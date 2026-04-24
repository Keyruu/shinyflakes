package main

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"slices"
	"strings"
	"syscall"
	"time"
)

// testResult holds the outcome of a single container run.
type testResult struct {
	worked         bool
	capsChecked    map[int]bool
	syscallsFailed map[string]bool
	startupSec     int
	logs           string
}

// runTest starts a container with the given capabilities, traces it, and
// returns what capabilities were checked (and whether it stayed healthy).
// healthTimeout controls how long to wait for --health-cmd.
func runTest(cfg config, caps []int, healthTimeout int) (*testResult, error) {
	ctx, cancel := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer cancel()

	tracer, err := startBpfTrace(ctx)
	if err != nil {
		return nil, fmt.Errorf("bpftrace: %w", err)
	}
	defer tracer.stop()

	ctrName := fmt.Sprintf("captrace-%d", time.Now().UnixNano())
	args := buildPodmanArgs(cfg, ctrName, capsToNames(caps))

	fmt.Fprintf(os.Stderr, "  → Starting %s (caps: %d)...\n", ctrName, len(caps))
	start := time.Now()

	out, err := exec.CommandContext(ctx, "podman", args...).CombinedOutput()
	if err != nil {
		// Container failed to start — still collect whatever trace we can.
		time.Sleep(2 * time.Second)
		pids, _ := getContainerPIDs(ctrName)
		traceData := tracer.collect(2 * time.Second)
		removeContainer(ctrName)
		return &testResult{
			worked:      false,
			capsChecked: parseBpfTrace(traceData, pids),
			logs:        string(out),
		}, nil
	}

	// Optionally attach strace to catch EPERM before cap_capable is reached.
	var strace *straceTracer
	if cfg.useStrace {
		time.Sleep(500 * time.Millisecond)
		if pid, err := containerMainPID(ctrName); err == nil {
			if s, err := startStrace(pid); err == nil {
				strace = s
			}
		}
	}

	// Wait for health check or just observe running state.
	worked := false
	startupSec := 0
	if cfg.healthCmd != "" {
		if healthTimeout < 10 {
			healthTimeout = 10
		}
		hs := time.Now()
		worked = waitForHealth(ctrName, cfg.healthCmd, healthTimeout)
		startupSec = int(time.Since(hs).Seconds())
	}

	// Determine how long to keep tracing after startup/health.
	traceWindow := cfg.traceTime
	if worked && startupSec > 0 {
		traceWindow = startupSec + cfg.traceTime
	}
	elapsed := int(time.Since(start).Seconds())
	remaining := traceWindow - elapsed
	if remaining < 2 {
		remaining = 2
	}

	// Start background probes to exercise runtime paths.
	stopProbes := make(chan struct{})
	if cfg.probeHTTP != "" || cfg.probeExec != "" {
		go runProbes(cfg, ctrName, stopProbes)
	}
	if remaining > 0 {
		time.Sleep(time.Duration(remaining) * time.Second)
	}
	close(stopProbes)

	// Collect final traces and clean up.
	pids, _ := getContainerPIDs(ctrName)
	if strace != nil {
		strace.stop()
	}
	traceData := tracer.collect(2 * time.Second)

	if cfg.healthCmd == "" {
		worked = containerRunning(ctrName)
	}
	removeContainer(ctrName)

	result := &testResult{
		worked:      worked,
		capsChecked: parseBpfTrace(traceData, pids),
		startupSec:  startupSec,
	}
	if strace != nil {
		result.syscallsFailed = parseStrace(strace.data)
	}
	return result, nil
}

// fixedPointDiscovery runs the container starting from --cap-drop all,
// discovers which capabilities are checked, adds them, and repeats until
// no new capabilities appear and the container is healthy.
func fixedPointDiscovery(cfg config) ([]int, error) {
	current := namesToCaps(cfg.extraCaps)

	for iter := 0; iter < cfg.maxIterations; iter++ {
		fmt.Fprintf(os.Stderr, "\n━━━ Discovery iteration %d (testing %d cap(s)) ━━━\n", iter+1, len(current))
		result, err := runTest(cfg, current, cfg.healthTimeout)
		if err != nil {
			return nil, err
		}

		if result.worked {
			fmt.Fprintln(os.Stderr, "  → Container healthy")
		} else {
			fmt.Fprintln(os.Stderr, "  → Container failed or unhealthy")
		}

		// Collect newly-discovered capabilities from both tracing sources.
		newCaps := map[int]bool{}
		for c := range result.capsChecked {
			if !slices.Contains(current, c) {
				newCaps[c] = true
			}
		}
		for sc := range result.syscallsFailed {
			if name, ok := syscallToCap[sc]; ok {
				if n, ok := capNumbers[name]; ok && !slices.Contains(current, n) {
					newCaps[n] = true
				}
			}
		}

		if len(newCaps) == 0 && result.worked {
			fmt.Fprintln(os.Stderr, "  → Fixed point reached — no new capabilities checked.")
			return current, nil
		}

		for c := range newCaps {
			current = append(current, c)
		}
		slices.Sort(current)
		current = slices.Compact(current)

		names := capsToNames(current)
		fmt.Fprintf(os.Stderr, "  → Adding %d cap(s): %s\n", len(newCaps), strings.Join(names, ", "))
	}
	return nil, fmt.Errorf("max iterations (%d) reached without convergence", cfg.maxIterations)
}

// greedyMinimize tests removing one capability at a time. If the container
// still works without it, the cap is discarded.
func greedyMinimize(cfg config, caps []int) ([]int, error) {
	if len(caps) == 0 || cfg.skipMinimize {
		return caps, nil
	}

	fmt.Fprintf(os.Stderr, "\n━━━ Minimization (%d caps) ━━━\n", len(caps))

	// Adapt timeout based on observed startup times during minimization.
	adaptiveTimeout := cfg.healthTimeout

	required := make([]int, len(caps))
	copy(required, caps)

	for _, capNum := range caps {
		name := capName(capNum)
		test := make([]int, 0, len(required))
		for _, c := range required {
			if c != capNum {
				test = append(test, c)
			}
		}

		fmt.Fprintf(os.Stderr, "  → Testing without %s...", name)
		result, err := runTest(cfg, test, adaptiveTimeout)
		if err != nil {
			fmt.Fprintf(os.Stderr, " ERROR (keeping)\n")
			continue
		}
		if result.worked {
			fmt.Fprintf(os.Stderr, " NOT NEEDED ✗\n")
			required = test
			if result.startupSec*2 > adaptiveTimeout {
				adaptiveTimeout = result.startupSec * 2
			}
		} else {
			fmt.Fprintf(os.Stderr, " REQUIRED ✓\n")
		}
	}
	return required, nil
}
