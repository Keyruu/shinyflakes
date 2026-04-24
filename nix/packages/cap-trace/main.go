package main

import (
	"fmt"
	"os"

	"github.com/spf13/pflag"
)

// config holds all CLI flags.
type config struct {
	image           string
	traceTime       int
	envs            []string
	volumes         []string
	network         string
	ports           string
	user            string
	extraCaps       []string
	healthCmd       string
	healthTimeout   int
	skipMinimize    bool
	noNewPrivileges bool
	readOnly        bool
	probeHTTP       string
	probeExec       string
	probeInterval   int
	useStrace       bool
	maxIterations   int
}

func parseFlags() config {
	var cfg config
	fs := pflag.NewFlagSet("cap-trace", pflag.ExitOnError)
	fs.StringVarP(&cfg.image, "image", "i", "", "Container image to trace (required)")
	fs.IntVarP(&cfg.traceTime, "time", "t", 10, "Seconds to trace after health check / startup")
	fs.StringArrayVarP(&cfg.envs, "env", "e", nil, "Environment variable (KEY=VAL, repeatable)")
	fs.StringArrayVarP(&cfg.volumes, "volume", "v", nil, "Volume mount (SRC:DST, repeatable)")
	fs.StringVarP(&cfg.network, "network", "n", "", "Podman network to attach to")
	fs.StringVarP(&cfg.ports, "port", "p", "", "Port to publish ([host:]container)")
	fs.StringVarP(&cfg.user, "user", "u", "", "Run container as user (uid:gid or username)")
	fs.StringArrayVar(&cfg.extraCaps, "cap-add", nil, "Extra capability to start with (repeatable)")
	fs.StringVar(&cfg.healthCmd, "health-cmd", "", "Health check command to wait for")
	fs.IntVar(&cfg.healthTimeout, "health-timeout", 30, "Max seconds to wait for health check")
	fs.BoolVar(&cfg.skipMinimize, "skip-minimize", false, "Skip minimization phase")
	fs.BoolVar(&cfg.noNewPrivileges, "no-new-privileges", false, "Set no-new-privileges security option")
	fs.BoolVar(&cfg.readOnly, "read-only", false, "Run container with read-only rootfs")
	fs.StringVar(&cfg.probeHTTP, "probe-http", "", "HTTP URL to hit repeatedly during trace")
	fs.StringVar(&cfg.probeExec, "probe-exec", "", "Shell command to exec inside container repeatedly")
	fs.IntVar(&cfg.probeInterval, "probe-interval", 2, "Seconds between probe requests")
	fs.BoolVar(&cfg.useStrace, "strace", false, "Also trace syscalls for EPERM failures")
	fs.IntVar(&cfg.maxIterations, "max-iterations", 10, "Max discovery iterations")
	fs.Parse(os.Args[1:])
	if cfg.image == "" {
		fmt.Fprintln(os.Stderr, "Error: --image is required")
		fs.Usage()
		os.Exit(1)
	}
	return cfg
}

func fatal(format string, args ...any) {
	fmt.Fprintf(os.Stderr, "Error: "+format+"\n", args...)
	os.Exit(1)
}

func main() {
	cfg := parseFlags()

	required, err := fixedPointDiscovery(cfg)
	if err != nil {
		fatal("discovery failed: %v", err)
	}

	required, err = greedyMinimize(cfg, required)
	if err != nil {
		fatal("minimization failed: %v", err)
	}

	reportResults(cfg.image, required)
}
