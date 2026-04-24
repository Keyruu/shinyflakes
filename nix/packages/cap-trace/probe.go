package main

import (
	"context"
	"net/http"
	"os/exec"
	"sync"
	"time"
)

// runProbes starts HTTP and/or exec probes against the container in the
// background until the stop channel is closed.
func runProbes(cfg config, ctrName string, stop <-chan struct{}) {
	var wg sync.WaitGroup

	if cfg.probeHTTP != "" {
		wg.Add(1)
		go func() {
			defer wg.Done()
			client := &http.Client{Timeout: 5 * time.Second}
			ticker := time.NewTicker(time.Duration(cfg.probeInterval) * time.Second)
			defer ticker.Stop()
			for {
				select {
				case <-stop:
					return
				case <-ticker.C:
					ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
					req, _ := http.NewRequestWithContext(ctx, "GET", cfg.probeHTTP, nil)
					client.Do(req)
					cancel()
				}
			}
		}()
	}

	if cfg.probeExec != "" {
		wg.Add(1)
		go func() {
			defer wg.Done()
			ticker := time.NewTicker(time.Duration(cfg.probeInterval) * time.Second)
			defer ticker.Stop()
			for {
				select {
				case <-stop:
					return
				case <-ticker.C:
					exec.Command("podman", "exec", ctrName, "sh", "-c", cfg.probeExec).Run()
				}
			}
		}()
	}

	wg.Wait()
}
