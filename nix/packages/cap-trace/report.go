package main

import (
	"fmt"
	"os"
)

// reportResults prints the discovered required capabilities and the Nix config snippet.
func reportResults(image string, required []int) {
	fmt.Fprintln(os.Stderr)
	fmt.Fprintln(os.Stderr, "═══════════════════════════════════════")
	fmt.Fprintf(os.Stderr, "  Required Capabilities for %s\n", image)
	fmt.Fprintln(os.Stderr, "═══════════════════════════════════════")

	if len(required) == 0 {
		fmt.Fprintln(os.Stderr, "  (none)")
	} else {
		for _, c := range required {
			fmt.Fprintf(os.Stderr, "  ✓ %s (%d)\n", capName(c), c)
		}
	}

	fmt.Fprintln(os.Stderr, "═══════════════════════════════════════")
	fmt.Fprintln(os.Stderr)

	if len(required) == 0 {
		fmt.Fprintln(os.Stderr, "No capabilities required — use security.dropAllCapabilities = true;")
	} else {
		fmt.Fprintln(os.Stderr, "addCapabilities = [")
		for _, c := range required {
			fmt.Fprintf(os.Stderr, "  \"%s\"\n", capName(c))
		}
		fmt.Fprintln(os.Stderr, " ];")
	}
}
