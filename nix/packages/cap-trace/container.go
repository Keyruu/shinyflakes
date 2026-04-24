package main

import (
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"
)

// buildPodmanArgs constructs a 'podman run -d' argument slice.
// Always includes --cap-drop all, then adds the requested caps.
func buildPodmanArgs(cfg config, ctrName string, caps []string) []string {
	args := []string{"run", "-d", "--name", ctrName, "--cap-drop", "all"}
	for _, c := range caps {
		args = append(args, "--cap-add", c)
	}
	for _, v := range cfg.volumes {
		args = append(args, "-v", v)
	}
	for _, e := range cfg.envs {
		args = append(args, "-e", e)
	}
	if cfg.network != "" {
		args = append(args, "--network", cfg.network)
	}
	if cfg.ports != "" {
		args = append(args, "-p", cfg.ports)
	}
	if cfg.user != "" {
		args = append(args, "--user", cfg.user)
	}
	if cfg.noNewPrivileges {
		args = append(args, "--security-opt=no-new-privileges")
	}
	if cfg.readOnly {
		args = append(args, "--read-only")
	}
	args = append(args, cfg.image)
	return args
}

// removeContainer force-removes a container with a 3s timeout.
func removeContainer(ctrName string) {
	exec.Command("podman", "rm", "-f", "-t", "3", ctrName).Run()
}

// containerRunning reports whether a container with the given name is active.
func containerRunning(ctrName string) bool {
	out, err := exec.Command("podman", "ps", "--filter", "name="+ctrName, "--format", "{{.ID}}").Output()
	return err == nil && strings.TrimSpace(string(out)) != ""
}

// containerMainPID returns the host PID of the container's init process.
func containerMainPID(ctrName string) (int, error) {
	out, err := exec.Command("podman", "inspect", ctrName, "--format", "{{.State.Pid}}").Output()
	if err != nil {
		return 0, err
	}
	return strconv.Atoi(strings.TrimSpace(string(out)))
}

// waitForHealth repeatedly runs cmd inside the container until it succeeds
// or timeout seconds elapse.
func waitForHealth(ctrName, cmd string, timeout int) bool {
	deadline := time.Now().Add(time.Duration(timeout) * time.Second)
	for time.Now().Before(deadline) {
		if !containerRunning(ctrName) {
			return false
		}
		if exec.Command("podman", "exec", ctrName, "sh", "-c", cmd).Run() == nil {
			return true
		}
		time.Sleep(1 * time.Second)
	}
	return false
}

// getContainerPIDs returns every PID (including thread IDs) that shares the
// container's PID namespace. This filters out host-side podman/conmon processes.
func getContainerPIDs(ctrName string) (map[int]bool, error) {
	mainPid, err := containerMainPID(ctrName)
	if err != nil || mainPid == 0 {
		return nil, fmt.Errorf("container not running")
	}

	ns, err := os.Readlink(fmt.Sprintf("/proc/%d/ns/pid", mainPid))
	if err != nil {
		return nil, err
	}

	pids := map[int]bool{}
	entries, err := os.ReadDir("/proc")
	if err != nil {
		return nil, err
	}

	for _, e := range entries {
		pid, err := strconv.Atoi(e.Name())
		if err != nil {
			continue
		}
		pns, err := os.Readlink(fmt.Sprintf("/proc/%d/ns/pid", pid))
		if err != nil {
			continue
		}
		if pns == ns {
			pids[pid] = true
			addThreadPIDs(pid, pids)
		}
	}
	return pids, nil
}

// addThreadPIDs adds all thread IDs under /proc/<pid>/task to the set.
func addThreadPIDs(pid int, pids map[int]bool) {
	entries, err := os.ReadDir(fmt.Sprintf("/proc/%d/task", pid))
	if err != nil {
		return
	}
	for _, e := range entries {
		if tid, err := strconv.Atoi(e.Name()); err == nil {
			pids[tid] = true
		}
	}
}
