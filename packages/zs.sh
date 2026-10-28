#!/usr/bin/env bash
# Nix sets ZS_HELPER to the store copy; the relative path also supports local runs.
exec node --experimental-strip-types "${ZS_HELPER:-$(dirname "${BASH_SOURCE[0]}")/zs/main.ts}" "$@"
