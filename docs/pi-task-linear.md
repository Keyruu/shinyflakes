# Start Pi tasks from Linear

`pi-task-linear` lists your assigned, unarchived, unfinished tickets in fzf.
`--all` lists unfinished tickets across the workspace visible to your API key.
Completed and canceled tickets are excluded; backlog and triage remain available.
Descriptions appear in the preview. Escape cancels without creating a task.

## API key (one-time setup)

1. Open <https://linear.app/settings/account/security> and create a personal
   API key with **Read** permission. Limit team access if desired. Workspace
   policy may require an administrator to allow personal API keys.
2. Save the key outside this repository and outside Nix configuration. For
   Bash, paste it at the hidden prompt:

   ```bash
   (
     umask 077
     mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/pi-task"
     read -r -s -p 'Linear API key: ' key
     printf '\n'
     printf '%s\n' "$key" > "${XDG_CONFIG_HOME:-$HOME/.config}/pi-task/linear-api-key"
     chmod 600 "${XDG_CONFIG_HOME:-$HOME/.config}/pi-task/linear-api-key"
   )
   ```

Alternatively, supply `LINEAR_API_KEY` through your secret manager/environment.
The environment value takes precedence. Never paste the real key into chat,
Git, Nix expressions or shell command arguments. The picker makes read-only API
queries; it does not update tickets.

## Run

From the repository the ticket belongs to:

```bash
pi-task-linear
pi-task-linear --all
pi-task-linear --repo /path/to/repo --base HEAD --review-mode guided
pi-task-linear --model qwen-token-plan/qwen3.8-max

# Without rebuilding your Home Manager configuration:
nix run '/home/lucas/shinyflakes?submodules=1#pi-task-linear' -- --repo /path/to/repo
```

The package is installed alongside `pi-task` by the Zellij aspect on rebuild.
No Linear CLI is required. All result pages are fetched, most recently updated
first. Select the correct repository with `--repo` when running elsewhere;
there is no automatic ticket-to-repository mapping.

Task names combine the ticket ID and a normalized title (up to 80 characters).
The saved request contains the ticket ID, full title, URL and Markdown
description (or an explicit missing-description marker). Existing `pi-task new`
handles branch/worktree creation, committed base and review state. Duplicate
names fail rather than reopening or changing an existing task. Default model:
`qwen-token-plan/glm-5.3`; `--model` overrides it. Run outside an existing Pi task
to avoid nesting task workspaces.

## Check

```bash
python3 packages/tests/pi-task-linear.py
nix build '.?submodules=1#pi-task-linear' --no-link
```

Automated checks mock Linear, fzf and the task launcher; they need no API key.
A real API/picker launch still requires the one-time setup above.
