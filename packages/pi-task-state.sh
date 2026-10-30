# Compatibility entry points for source-checkout regression fixtures, not a second state implementation.
PI_TASK_SOURCE_LAUNCHER="$(dirname "${BASH_SOURCE[0]}")/pi-task.sh"
task_review_init() { bash "$PI_TASK_SOURCE_LAUNCHER" review-internal init-task "$@"; }
task_review_update() { bash "$PI_TASK_SOURCE_LAUNCHER" review-internal "$@"; }
