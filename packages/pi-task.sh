#!/usr/bin/env bash
set -euo pipefail
exec node --experimental-strip-types "$(dirname "${BASH_SOURCE[0]}")/../modules/aspects/agents/pi/cli/pi-task.ts" "$@"
