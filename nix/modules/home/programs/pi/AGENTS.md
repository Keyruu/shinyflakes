# CLI Tools

Use the following CLI tools for their respective functionalities instead of web
APIs or MCP servers:

## `jira` — Jira Access

Use the `jira` CLI for interacting with Jira. Run `jira --help` for available
commands.

Common usage:

- `jira issue list` — list issues
- `jira issue view <key>` — view an issue
- `jira issue create` — create an issue
- `jira sprint list` — list sprints

## `gh` — GitHub Access

Use the `gh` CLI for interacting with GitHub. Run `gh --help` for available
commands.

Common usage:

- `gh pr list` — list pull requests
- `gh pr create` — create a pull request
- `gh pr view <number>` — view a pull request
- `gh issue list` — list issues
- `gh repo view` — view repository info
- `gh api <endpoint>` — call the GitHub API directly
- `gh search code "query"` — search for code across GitHub repositories
- `gh search code "query" --language nix` — search code filtered by language
- `gh search code "query" --repo owner/repo` — search code in a specific repo

## `ddgr` — Web Search

Use `ddgr` for web searches via DuckDuckGo. Run `ddgr --help` for available
options.

Common usage:

- `ddgr "search query"` — search the web
- `ddgr -n 5 "search query"` — limit to 5 results
- `ddgr --json "search query"` — output results as JSON

## `pnpx context7` — Library Documentation Search

Use `pnpx context7` to search for up-to-date library documentation and usage
examples. Run `pnpx context7 --help` for available options.

Common usage:

- `pnpx context7 resolve "library-name"` — find and fetch documentation for a library
- `pnpx context7 resolve "react"` — get React documentation and examples
