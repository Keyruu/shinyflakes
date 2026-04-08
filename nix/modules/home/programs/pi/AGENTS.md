# MCP Tools (via mcporter)

Use MCP tools via `pnpx mcporter call <server>.<tool>(...)` for the following
functionalities. If you want to see the full list of tools available do
`pnpx mcporter <server>`.

## `searxng` — Web Search (2 tools)

Web search and URL content reading via SearXNG.

Common usage:

- `mcporter call searxng.searxng_web_search(query: "nix flake blueprint")` — web
  search
- `mcporter call searxng.searxng_web_search(query: "nixos 24.11 release", time_range: "month")`
  — time-filtered search
- `mcporter call searxng.web_url_read(url: "https://example.com")` — read URL
  content
- `mcporter call searxng.web_url_read(url: "https://example.com", section: "Installation")`
  — read specific section

Tools: `searxng_web_search`, `web_url_read`

## `github` — GitHub Access (41 tools)

Full GitHub integration — PRs, issues, repos, branches, releases, code search,
and more.

Common usage:

- `mcporter call github.list_pull_requests(owner: "org", repo: "repo")` — list
  PRs
- `mcporter call github.create_pull_request(owner: "org", repo: "repo", title: "feat: stuff", head: "feature-branch", base: "main")`
  — create PR
- `mcporter call github.pull_request_read(method: "get", owner: "org", repo: "repo", pullNumber: 42)`
  — view PR details
- `mcporter call github.pull_request_read(method: "get_diff", owner: "org", repo: "repo", pullNumber: 42)`
  — view PR diff
- `mcporter call github.list_issues(owner: "org", repo: "repo")` — list issues
- `mcporter call github.issue_read(owner: "org", repo: "repo", issueNumber: 123)`
  — view issue
- `mcporter call github.search_code(query: "content:useState language:TypeScript org:vercel")`
  — search code
- `mcporter call github.search_pull_requests(query: "is:open review:required", owner: "org", repo: "repo")`
  — search PRs
- `mcporter call github.get_file_contents(owner: "org", repo: "repo", path: "src/main.ts")`
  — get file contents
- `mcporter call github.list_commits(owner: "org", repo: "repo", sha: "main")` —
  list commits
- `mcporter call github.create_branch(owner: "org", repo: "repo", branch: "feature-x")`
  — create branch
- `mcporter call github.get_me()` — get authenticated user info

# `atlassian` — Jira & Confluence Access (72 tools)

Full Jira and Confluence integration — issues, sprints, boards, pages, and more.

### Jira — Common usage:

- `mcporter call atlassian.jira_search(jql: "assignee = currentUser() AND status != Done")`
  — search issues
- `mcporter call atlassian.jira_get_issue(issue_key: "PROJ-123")` — view issue
- `mcporter call atlassian.jira_create_issue(project_key: "PROJ", summary: "Bug title", issue_type: "Bug")`
  — create issue
- `mcporter call atlassian.jira_update_issue(issue_key: "PROJ-123", fields: "{\"status\": \"In Progress\"}")`
  — update issue
- `mcporter call atlassian.jira_add_comment(issue_key: "PROJ-123", body: "Working on it")`
  — add comment
- `mcporter call atlassian.jira_transition_issue(issue_key: "PROJ-123")` —
  transition issue status
- `mcporter call atlassian.jira_get_agile_boards(project_key: "PROJ")` — list
  boards
- `mcporter call atlassian.jira_get_sprints_from_board(board_id: "100", state: "active")`
  — list active sprints
- `mcporter call atlassian.jira_get_sprint_issues(sprint_id: "200")` — list
  sprint issues
- `mcporter call atlassian.jira_get_project_issues(project_key: "PROJ")` — list
  project issues

### Confluence — Common usage:

- `mcporter call atlassian.confluence_search(query: "deployment guide")` —
  search pages
- `mcporter call atlassian.confluence_get_page(page_id: "123456789")` — get page
  content
- `mcporter call atlassian.confluence_create_page(...)` — create page
- `mcporter call atlassian.confluence_update_page(...)` — update page

## `gh_grep` — GitHub Code Search (1 tool)

Search real-world code examples from public GitHub repos. Searches for literal
code patterns (like grep), not keywords.

Common usage:

- `mcporter call gh_grep.searchGitHub(query: "useState(")` — search for code
  pattern
- `mcporter call gh_grep.searchGitHub(query: "CORS(", matchCase: true, language: ["Python"])`
  — case-sensitive with language filter
- `mcporter call gh_grep.searchGitHub(query: "(?s)useEffect\\(\\(\\) =>.*cleanup", useRegexp: true, language: ["TSX"])`
  — regex search
- `mcporter call gh_grep.searchGitHub(query: "nixosConfigurations", repo: "numtide/blueprint")`
  — search in specific repo

Tools: `searchGitHub`

## `context7` — Library Documentation Search (2 tools)

Search for up-to-date library documentation and usage examples.

Common usage:

- `mcporter call context7.resolve-library-id(query: "how to use hooks", libraryName: "React")`
  — find library ID
- `mcporter call context7.query-docs(libraryId: "/vercel/next.js", query: "server components routing")`
  — query docs

Tools: `resolve-library-id`, `query-docs`
