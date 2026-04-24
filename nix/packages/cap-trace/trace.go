package main

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/creack/pty"
)

// bpfProbeScript is the bpftrace probe that logs cap_capable calls.
const bpfProbeScript = `kprobe:cap_capable
{
	printf("CAP_REQ %d %d\n", pid, arg2);
}
`

// syscallToCap maps syscalls (observed via strace) to the capability
// most likely required. This is a heuristic — not exhaustive.
var syscallToCap = map[string]string{
	"bind":              "NET_BIND_SERVICE",
	"mount":             "SYS_ADMIN",
	"umount2":           "SYS_ADMIN",
	"pivot_root":        "SYS_ADMIN",
	"chroot":            "SYS_CHROOT",
	"setuid":            "SETUID",
	"setgid":            "SETGID",
	"setresuid":         "SETUID",
	"setresgid":         "SETGID",
	"setgroups":         "SETGID",
	"setfsuid":          "SETUID",
	"setfsgid":          "SETGID",
	"setreuid":          "SETUID",
	"setregid":          "SETGID",
	"capset":            "SETPCAP",
	"mknod":             "MKNOD",
	"mknodat":           "MKNOD",
	"ptrace":            "SYS_PTRACE",
	"nice":              "SYS_NICE",
	"setpriority":       "SYS_NICE",
	"syslog":            "SYSLOG",
	"reboot":            "SYS_BOOT",
	"init_module":       "SYS_MODULE",
	"finit_module":      "SYS_MODULE",
	"delete_module":     "SYS_MODULE",
	"socket":            "NET_RAW",
	"setsockopt":        "NET_ADMIN",
	"open":              "DAC_OVERRIDE",
	"openat":            "DAC_OVERRIDE",
	"creat":             "DAC_OVERRIDE",
	"unlink":            "DAC_OVERRIDE",
	"rename":            "DAC_OVERRIDE",
	"chown":             "CHOWN",
	"fchown":            "CHOWN",
	"lchown":            "CHOWN",
	"fchownat":          "CHOWN",
	"chmod":             "FOWNER",
	"fchmod":            "FOWNER",
	"fchmodat":          "FOWNER",
	"quotactl":          "SYS_ADMIN",
	"bpf":               "BPF",
	"perf_event_open":   "PERFMON",
	"clock_settime":     "SYS_TIME",
	"setrlimit":         "SYS_RESOURCE",
	"vhangup":           "SYS_TTY_CONFIG",
	"fanotify_init":     "SYS_ADMIN",
	"name_to_handle_at": "SYS_ADMIN",
	"open_by_handle_at": "SYS_ADMIN",
	"iopl":              "SYS_RAWIO",
	"ioperm":            "SYS_RAWIO",
	"swapon":            "SYS_ADMIN",
	"swapoff":           "SYS_ADMIN",
	"lookup_dcookie":    "SYS_ADMIN",
	"process_vm_readv":  "SYS_PTRACE",
	"process_vm_writev": "SYS_PTRACE",
	"kcmp":              "SYS_PTRACE",
	"pidfd_getfd":       "SYS_PTRACE",
	"pidfd_open":        "CHECKPOINT_RESTORE",
}

// bpfTracer wraps a bpftrace process that probes cap_capable.
type bpfTracer struct {
	cmd    *exec.Cmd
	ptmx   *os.File
	script string
	cancel context.CancelFunc
}

// startBpfTrace launches bpftrace with the cap_capable probe.
func startBpfTrace(ctx context.Context) (*bpfTracer, error) {
	ctx, cancel := context.WithCancel(ctx)

	f, err := os.CreateTemp("", "captrace-*.bpf")
	if err != nil {
		cancel()
		return nil, err
	}
	path := f.Name()

	if _, err := f.WriteString(bpfProbeScript); err != nil {
		os.Remove(path)
		cancel()
		return nil, err
	}
	f.Close()

	cmd := exec.CommandContext(ctx, "bpftrace", path)
	cmd.Stdin = nil
	ptmx, err := pty.Start(cmd)
	if err != nil {
		os.Remove(path)
		cancel()
		return nil, fmt.Errorf("starting bpftrace: %w", err)
	}

	// Give bpftrace time to attach probes, then drain the "Attached N probe(s)" line.
	time.Sleep(2 * time.Second)
	ptmx.SetReadDeadline(time.Now().Add(500 * time.Millisecond))
	drain := make([]byte, 4096)
	ptmx.Read(drain)

	return &bpfTracer{
		cmd:    cmd,
		ptmx:   ptmx,
		script: path,
		cancel: cancel,
	}, nil
}

// collect reads trace output for the given duration.
func (t *bpfTracer) collect(timeout time.Duration) []byte {
	t.ptmx.SetReadDeadline(time.Now().Add(timeout))
	buf := make([]byte, 4096)
	var data []byte
	for {
		n, err := t.ptmx.Read(buf)
		if n > 0 {
			data = append(data, buf[:n]...)
		}
		if err != nil {
			break
		}
	}
	return data
}

// stop gracefully shuts down bpftrace and cleans up the temp script.
func (t *bpfTracer) stop() {
	t.cmd.Process.Signal(syscall.SIGINT)

	done := make(chan struct{})
	go func() {
		t.cmd.Wait()
		close(done)
	}()

	select {
	case <-done:
	case <-time.After(3 * time.Second):
		t.cmd.Process.Kill()
		<-done
	}

	t.ptmx.Close()
	t.cancel()
	os.Remove(t.script)
}

// straceTracer wraps an strace process attached to a container PID.
type straceTracer struct {
	cmd     *exec.Cmd
	logFile string
	data    []byte
}

// startStrace attaches strace -f to the given PID, writing to a temp file.
func startStrace(pid int) (*straceTracer, error) {
	f, err := os.CreateTemp("", "captrace-strace-*.log")
	if err != nil {
		return nil, err
	}
	f.Close()

	cmd := exec.Command("strace", "-f", "-p", strconv.Itoa(pid), "-o", f.Name())
	if err := cmd.Start(); err != nil {
		os.Remove(f.Name())
		return nil, err
	}
	return &straceTracer{cmd: cmd, logFile: f.Name()}, nil
}

// stop terminates strace and reads the captured log.
func (t *straceTracer) stop() {
	t.cmd.Process.Signal(syscall.SIGINT)
	t.cmd.Wait()
	t.data, _ = os.ReadFile(t.logFile)
	os.Remove(t.logFile)
}

// parseBpfTrace extracts capability numbers from bpftrace output.
// If pids is non-nil, only lines matching container PIDs are kept.
func parseBpfTrace(data []byte, pids map[int]bool) map[int]bool {
	caps := map[int]bool{}
	scanner := bufio.NewScanner(strings.NewReader(string(data)))
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
		if pids != nil && !pids[pid] {
			continue
		}
		capNum, err := strconv.Atoi(parts[2])
		if err != nil {
			continue
		}
		caps[capNum] = true
	}
	return caps
}

// parseStrace scans strace output for syscalls that returned EPERM or EACCES.
func parseStrace(data []byte) map[string]bool {
	failed := map[string]bool{}
	scanner := bufio.NewScanner(strings.NewReader(string(data)))
	for scanner.Scan() {
		line := scanner.Text()
		if !strings.Contains(line, "= -1 EPERM") && !strings.Contains(line, "= -1 EACCES") {
			continue
		}

		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "[pid") {
			if idx := strings.Index(line, "]"); idx != -1 {
				line = strings.TrimSpace(line[idx+1:])
			}
		}
		if idx := strings.Index(line, "("); idx > 0 {
			failed[line[:idx]] = true
		}
	}
	return failed
}
