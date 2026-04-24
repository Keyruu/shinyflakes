package main

import (
	"fmt"
	"slices"
	"strings"
)

// linux/capability.h — capability number → canonical name.
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

// capNumbers is the reverse map, built from capNames in init.
var capNumbers map[string]int

func init() {
	capNumbers = make(map[string]int, len(capNames))
	for n, name := range capNames {
		capNumbers[name] = n
	}
}

// capName returns the canonical name for a capability number.
// Falls back to "CAP_%d" for unknown numbers.
func capName(n int) string {
	if name, ok := capNames[n]; ok {
		return name
	}
	return fmt.Sprintf("CAP_%d", n)
}

// capsToNames converts capability numbers to canonical names.
func capsToNames(nums []int) []string {
	names := make([]string, len(nums))
	for i, n := range nums {
		names[i] = capName(n)
	}
	return names
}

// namesToCaps converts capability names (with optional "CAP_" prefix) to numbers.
// Unknown names are silently ignored.
func namesToCaps(names []string) []int {
	caps := make([]int, 0, len(names))
	for _, n := range names {
		n = strings.ToUpper(strings.TrimPrefix(n, "CAP_"))
		if num, ok := capNumbers[n]; ok {
			caps = append(caps, num)
		}
	}
	slices.Sort(caps)
	return slices.Compact(caps)
}
