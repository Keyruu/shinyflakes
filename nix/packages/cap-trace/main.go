package main

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"slices"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/creack/pty"
	"github.com/spf13/pflag"
)

// Linux capability number → name mapping (linux/capability.h)
var capNames = map[int]string{
	0:  "CHOWN",
	1:  "DAC_OVERRIDE",
	2:  "DAC_READ_SEARCH",
	3:  "FOWNER",
	4:  "FSETID",
	5:  "KILL",
	6:  "SETGID",
	7:  "SETUID",
	8:  "SETPCAP",
	9:  "LINUX_IMMUTABLE",
	10: "NET_BIND_SERVICE",
	11: "NET_BROADCAST",
	12: "NET_ADMIN",
	13: "NET_RAW",
	14: "IPC_LOCK",
	15: "IPC_OWNER",
	16: "SYS_MODULE",
	17: "SYS_RAWIO",
	18: "SYS_CHROOT",
	19: "SYS_PTRACE",
	20: "SYS_PACCT",
	21: "SYS_ADMIN",
	22: "SYS_BOOT",
	23: "SYS_NICE",
	24: "SYS_RESOURCE",
	25: "SYS_TIME",
	26: "SYS_TTY_CONFIG",
	27: "MKNOD",
	28: "LEASE",
	29: "AUDIT_WRITE",
	30: "AUDIT_CONTROL",
	31: "SETFCAP",
	32: "MAC_OVERRIDE",
	33: "MAC_ADMIN",
	34: "SYSLOG",
	35: "WAKE_ALARM",
	36: "BLOCK_SUSPEND",
	37: "AUDIT_READ",
	38: "PERFMON",
	39: "BPF",
	40: "CHECKPOINT_RESTORE",
}

const bpfScript = `#!/usr/bin/env bpftrace
kprobe:cap_capable
{
    printf("CAP_REQ %d %d\n", pid, arg2);
}
`

func main() {
	var (
		image         string
		traceTime     int
		envs          []string
		volumes       []string
		network       string
		ports         string
		extraCaps     []string
		healthCmd     string
		healthTimeout int
	)

	fs := pflag.NewFlagSet("cap-trace", pflag.ExitOnError)
	fs.StringVarP(&image, "image", "i", "", "Container image to trace (required)")
	fs.IntVarP(&traceTime, "time", "t", 10, "Seconds to trace after container starts")
	fs.StringArrayVarP(&envs, "env", "e", nil, "Environment variable (KEY=VAL, repeatable)")
	fs.StringArrayVarP(&volumes, "volume", "v", nil, "Volume mount (SRC:DST, repeatable)")
	fs.StringVarP(&network, "network", "n", "", "Podman network to attach to")
	fs.StringVarP(&ports, "port", "p", "", "Port to publish ([host:]container)")
	fs.StringArrayVar(&extraCaps, "cap-add", nil, "Extra capability to add (repeatable)")
	fs.StringVar(&healthCmd, "health-cmd", "", "Health check command to wait for")
	fs.IntVar(&healthTimeout, "health-timeout", 30, "Max seconds to wait for health check")

	fs.Parse(os.Args[1:])

	if image == "" {
		fmt.Fprintln(os.Stderr, "Error: --image is required")
		fs.Usage()
		os.Exit(1)
	}

	ctx, cancel := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer cancel()

	// Write bpftrace script
	bpfFile, err := os.CreateTemp("", "cap-trace-*.bpf")
	if err != nil {
		fatal("creating temp file: %v", err)
	}
	bpfPath := bpfFile.Name()
	defer os.Remove(bpfPath)
	if _, err := bpfFile.WriteString(bpfScript); err != nil {
		fatal("writing bpftrace script: %v", err)
	}
	bpfFile.Close()

	// Start bpftrace with a PTY so it line-buffers its output
	fmt.Fprintln(os.Stderr, "→ Starting bpftrace capability tracer...")
	fmt.Fprintln(os.Stderr, "→ Container:", image)

	bpfCmd := exec.CommandContext(ctx, "bpftrace", bpfPath)
	bpfCmd.Stdin = nil
	ptmx, err := pty.Start(bpfCmd)
	if err != nil {
		fatal("starting bpftrace with pty: %v", err)
	}
	defer ptmx.Close()

	// Give bpftrace time to attach probes
	time.Sleep(2 * time.Second)

	// Read bpftrace "Attached N probes" message from pty
	// (drain it so it doesn't pollute our parsing later)
	buf := make([]byte, 4096)
	ptmx.SetReadDeadline(time.Now().Add(500 * time.Millisecond))
	ptmx.Read(buf)

	// Build podman command — run with ALL capabilities so container stays alive
	ctrName := fmt.Sprintf("cap-trace-%d", time.Now().Unix())
	podmanArgs := []string{"run", "--name", ctrName, "--rm"}
	for _, v := range volumes {
		podmanArgs = append(podmanArgs, "-v", v)
	}
	for _, e := range envs {
		podmanArgs = append(podmanArgs, "-e", e)
	}
	if network != "" {
		podmanArgs = append(podmanArgs, "--network", network)
	}
	if ports != "" {
		podmanArgs = append(podmanArgs, "-p", ports)
	}
	for _, c := range extraCaps {
		podmanArgs = append(podmanArgs, "--cap-add", c)
	}
	podmanArgs = append(podmanArgs, image)

	fmt.Fprintln(os.Stderr, "→ Running container (all caps granted, tracing capability requests)...")

	podmanCmd := exec.CommandContext(ctx, "podman", podmanArgs...)
	podmanCmd.Stdout = os.Stderr
	podmanCmd.Stderr = os.Stderr
	if err := podmanCmd.Start(); err != nil {
		fatal("starting container: %v", err)
	}

	// Wait for trace window or health check
	if healthCmd != "" {
		fmt.Fprintf(os.Stderr, "→ Waiting for health check (timeout: %ds)...\n", healthTimeout)
		deadline := time.Now().Add(time.Duration(healthTimeout) * time.Second)
		for time.Now().Before(deadline) {
			if !containerRunning(ctrName) {
				fmt.Fprintln(os.Stderr, "⚠ Container exited before health check passed")
				break
			}
			if healthCheck(ctrName, healthCmd) {
				fmt.Fprintln(os.Stderr, "✓ Health check passed")
				break
			}
			time.Sleep(1 * time.Second)
		}
	} else {
		fmt.Fprintf(os.Stderr, "→ Tracing for %ds...\n", traceTime)
		select {
		case <-time.After(time.Duration(traceTime) * time.Second):
		case <-ctx.Done():
		}
	}

	// Capture container PIDs BEFORE stopping
	containerPIDs, err := getContainerPIDs(ctrName)
	if err != nil || len(containerPIDs) == 0 {
		fmt.Fprintf(os.Stderr, "⚠ Could not get container PIDs: %v\n", err)
		fmt.Fprintln(os.Stderr, "  Showing all traced capabilities (may include host noise)")
		containerPIDs = nil
	}

	// Read trace output from pty
	ptmx.SetReadDeadline(time.Now().Add(2 * time.Second))
	var traceData []byte
	for {
		n, err := ptmx.Read(buf)
		if n > 0 {
			traceData = append(traceData, buf[:n]...)
		}
		if err != nil {
			break
		}
	}

	// Stop everything
	bpfCmd.Process.Signal(syscall.SIGINT)
	podmanCmd.Process.Kill()
	bpfCmd.Wait()
	podmanCmd.Wait()

	// Parse trace
	caps, err := parseTrace(traceData, containerPIDs)
	if err != nil {
		fatal("parsing trace: %v", err)
	}

	// Display results
	fmt.Fprintln(os.Stderr)
	fmt.Fprintln(os.Stderr, "═══════════════════════════════════════")
	fmt.Fprintf(os.Stderr, "  Required Capabilities for %s\n", image)
	fmt.Fprintln(os.Stderr, "═══════════════════════════════════════")

	// Sort capability numbers for deterministic output
	sortedCaps := make([]int, 0, len(caps))
	for capNum := range caps {
		sortedCaps = append(sortedCaps, capNum)
	}
	slices.Sort(sortedCaps)

	resultCaps := []string{}
	for _, capNum := range sortedCaps {
		name, ok := capNames[capNum]
		if !ok {
			name = fmt.Sprintf("CAP_%d", capNum)
		}
		fmt.Fprintf(os.Stderr, "  ✓ %s (%d)\n", name, capNum)
		resultCaps = append(resultCaps, name)
	}
	fmt.Fprintln(os.Stderr, "═══════════════════════════════════════")
	fmt.Fprintln(os.Stderr)

	if len(resultCaps) == 0 {
		fmt.Fprintln(os.Stderr, "⚠ No capabilities detected. Container may have failed to start.")
		fmt.Fprintln(os.Stderr, "Try running with a longer --time or --health-cmd")
		fmt.Fprintln(os.Stderr)
		fmt.Println("# No capabilities needed — use security.dropAllCapabilities = true;")
	} else {
		fmt.Println("# Add to your stack container config:")
		fmt.Println("addCapabilities = [")
		for _, c := range resultCaps {
			fmt.Printf("  \"%s\"\n", c)
		}
		fmt.Println("];")
	}
}

func getContainerPIDs(ctrName string) (map[int]bool, error) {
	// Get container ID
	out, err := exec.Command("podman", "ps", "-a", "--filter", "name="+ctrName, "--format", "{{.ID}}").Output()
	if err != nil {
		return nil, fmt.Errorf("podman ps: %w", err)
	}
	ids := strings.Fields(strings.TrimSpace(string(out)))
	if len(ids) == 0 {
		return nil, fmt.Errorf("no container found with name %s", ctrName)
	}

	pids := map[int]bool{}
	for _, id := range ids {
		// Get host PIDs from podman top
		out, err := exec.Command("podman", "top", id, "hpid").Output()
		if err != nil {
			continue
		}
		scanner := bufio.NewScanner(strings.NewReader(string(out)))
		lineNum := 0
		for scanner.Scan() {
			lineNum++
			if lineNum == 1 {
				continue // skip header
			}
			fields := strings.Fields(scanner.Text())
			if len(fields) > 0 {
				if pid, err := strconv.Atoi(fields[0]); err == nil {
					pids[pid] = true
					// Also add thread PIDs from /proc
					addThreadPIDs(pid, pids)
				}
			}
		}
	}

	// Also get the main PID from podman inspect and its threads
	out, err = exec.Command("podman", "inspect", ctrName, "--format", "{{.State.Pid}}").Output()
	if err == nil {
		mainPid, err := strconv.Atoi(strings.TrimSpace(string(out)))
		if err == nil && mainPid > 0 {
			pids[mainPid] = true
			addThreadPIDs(mainPid, pids)
		}
	}

	// Get all PIDs from the container's cgroup
	out, err = exec.Command("podman", "inspect", ctrName, "--format", "{{.State.CgroupPath}}").Output()
	if err == nil {
		cgroupPath := strings.TrimSpace(string(out))
		for _, suffix := range []string{"/cgroup.procs", "/container/cgroup.procs"} {
			data, err := os.ReadFile("/sys/fs/cgroup" + cgroupPath + suffix)
			if err == nil {
				for _, line := range strings.Split(string(data), "\n") {
					if pid, err := strconv.Atoi(strings.TrimSpace(line)); err == nil && pid > 0 {
						pids[pid] = true
						addThreadPIDs(pid, pids)
					}
				}
			}
		}
	}

	return pids, nil
}

func addThreadPIDs(pid int, pids map[int]bool) {
	entries, err := os.ReadDir(fmt.Sprintf("/proc/%d/task", pid))
	if err == nil {
		for _, entry := range entries {
			if tid, err := strconv.Atoi(entry.Name()); err == nil {
				pids[tid] = true
			}
		}
	}
}

func parseTrace(traceData []byte, containerPIDs map[int]bool) (map[int]bool, error) {
	caps := map[int]bool{}
	scanner := bufio.NewScanner(strings.NewReader(string(traceData)))
	for scanner.Scan() {
		line := scanner.Text()
		if !strings.HasPrefix(line, "CAP_REQ ") {
			continue
		}
		parts := strings.Fields(line)
		if len(parts) != 3 {
			continue
		}
		pid, err := strconv.Atoi(parts[1])
		if err != nil {
			continue
		}
		capNum, err := strconv.Atoi(parts[2])
		if err != nil {
			continue
		}
		// Filter: only count capabilities from container PIDs
		if containerPIDs != nil && !containerPIDs[pid] {
			continue
		}
		caps[capNum] = true
	}
	return caps, scanner.Err()
}

func containerRunning(ctrName string) bool {
	out, err := exec.Command("podman", "ps", "--filter", "name="+ctrName, "--format", "{{.ID}}").Output()
	if err != nil {
		return false
	}
	return strings.TrimSpace(string(out)) != ""
}

func healthCheck(ctrName, cmd string) bool {
	return exec.Command("podman", "exec", ctrName, "sh", "-c", cmd).Run() == nil
}

func fatal(format string, args ...any) {
	fmt.Fprintf(os.Stderr, "Error: "+format+"\n", args...)
	os.Exit(1)
}