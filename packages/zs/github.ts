import { run } from "./commands.ts";
import { clean, object, json, compare } from "./text.ts";
import type { Repo, Row } from "./main.ts";

export interface GithubMetadata {
  repository: string;
  head: string;
  complete: boolean;
}

export interface PullRequest {
  repository: string;
  number: number;
  title: string;
  state: string;
  isDraft: boolean;
}
export function githubRepository(remote: string): string | null {
  const match =
    /^(?:(?:https?|git):\/\/github\.com\/|ssh:\/\/git@github\.com(?::22)?\/|git@github\.com:)([a-z0-9_-]+)\/([a-z0-9_.-]+?)(?:\.git)?\/?$/i.exec(
      remote,
    );
  return match && ![".", ".."].includes(match[2])
    ? `${match[1]}/${match[2]}`
    : null;
}
async function githubQuery(
  query: string,
  signal?: AbortSignal,
): Promise<Record<string, unknown> | null> {
  const value = json(
    await run(
      [
        "gh",
        "api",
        "graphql",
        "--hostname",
        "github.com",
        "--cache",
        "60s",
        "-f",
        `query=${query}`,
      ],
      { optional: true, timeout: 3000, signal },
    ),
  );
  return object(value) && !value.errors && object(value.data)
    ? value.data
    : null;
}
export function prBadge(pr: PullRequest): string {
  return `PR #${pr.number} ${pr.isDraft && pr.state === "OPEN" ? "draft" : pr.state.toLowerCase()}`;
}
function prUrl(pr: PullRequest): string {
  return `https://github.com/${pr.repository}/pull/${pr.number}`;
}

export function githubPreview(metadata: GithubMetadata, prs: PullRequest[]): string {
  const note = !metadata.complete
    ? "PR: unavailable or incomplete (auth, network, timeout or too many branch matches)"
    : prs.length
      ? prs.map((pr) => `${prBadge(pr)}: ${clean(pr.title)}\n${prUrl(pr)}`).join("\n")
      : "PR: no matching pull request";
  return `GitHub: ${metadata.repository} · head ${clean(metadata.head)} (cache ≤60s)\n${note}`;
}

export async function pullRequestPreview(prs: PullRequest[]): Promise<string> {
  if (!prs.length) return "";
  const queries = prs.map((pr, i) => {
    const [owner, name] = pr.repository.split("/");
    return `r${i}: repository(owner:${JSON.stringify(owner)},name:${JSON.stringify(name)}) { pullRequest(number:${pr.number}) {
      commits(last:1) { nodes { commit { statusCheckRollup { state } } } }
    } }`;
  });
  const data = await githubQuery(`query { ${queries.join("\n")} }`);
  return prs
    .map((pr, i) => {
      const repo = data?.[`r${i}`];
      const pull =
        object(repo) && object(repo.pullRequest) ? repo.pullRequest : null;
      const commits =
        pull && object(pull.commits) && Array.isArray(pull.commits.nodes)
          ? pull.commits.nodes
          : [];
      const commit =
        object(commits[0]) && object(commits[0].commit)
          ? commits[0].commit
          : null;
      const rollup =
        commit && object(commit.statusCheckRollup)
          ? commit.statusCheckRollup
          : null;
      const state = rollup?.state;
      const ci = !pull
        ? "? unavailable (auth, network or timeout)"
        : !rollup
          ? "— no checks reported"
          : state === "SUCCESS"
            ? "✓ passing"
            : ["ERROR", "FAILURE"].includes(String(state))
              ? "✗ failed"
              : ["PENDING", "EXPECTED"].includes(String(state))
                ? "◐ pending"
                : "? unknown";
      return `CI #${pr.number}: ${ci} (GitHub cache ≤60s)`;
    })
    .join("\n\n");
}

export async function loadGithub(
  repos: ReadonlyMap<string, Repo>,
  rows: Row[],
  signal?: AbortSignal,
): Promise<void> {
  const groups = new Map<string, { row: Row; head: string }[]>();
  for (const [common, repo] of repos) {
    if (signal?.aborted) return;
    const output = await run(
      [
        "git",
        "-C",
        repo.path,
        "config",
        "--null",
        "--get-regexp",
        "^(remote\\..*\\.url|branch\\..*\\.(remote|merge|pushremote)|remote\\.pushdefault)$",
      ],
      { optional: true, signal },
    );
    if (signal?.aborted) return;
    const config = new Map(
      (output ?? "")
        .split("\0")
        .filter(Boolean)
        .map((entry) => {
          const split = entry.indexOf("\n");
          return [entry.slice(0, split), entry.slice(split + 1)];
        }),
    );
    const remotes = [...config.keys()].filter(
      (name) => name.startsWith("remote.") && name.endsWith(".url"),
    );
    const repositories = new Map<string, string | null>();
    for (const row of rows.filter(
      (r) => r.kind === "worktree" && r.repo === common,
    )) {
      if (!row.branch || row.branch.startsWith("detached ")) continue;
      const tracking = config.get(`branch.${row.branch}.remote`);
      const remote =
        config.get(`branch.${row.branch}.pushremote`) ??
        config.get("remote.pushdefault") ??
        tracking ??
        (config.has("remote.origin.url")
          ? "origin"
          : remotes.length === 1
            ? remotes[0].slice(7, -4)
            : "");
      if (!repositories.has(remote)) {
        const url = await run(
          [
            "git",
            "-C",
            repo.path,
            "remote",
            "get-url",
            "--push",
            "--",
            remote,
          ],
          { optional: true, signal },
        );
        if (signal?.aborted) return;
        repositories.set(
          remote,
          githubRepository((url ?? "").replace(/\n$/, "")),
        );
      }
      const repository = repositories.get(remote);
      if (!repository) continue;
      const head =
        remote === tracking
          ? (config
              .get(`branch.${row.branch}.merge`)
              ?.replace(/^refs\/heads\//, "") ?? row.branch)
          : row.branch;
      const name = repository.toLowerCase();
      groups.set(name, [...(groups.get(name) ?? []), { row, head }]);
    }
  }
  const entries = [...groups];
  // Bound concurrent API requests; cached GitHub metadata must never change navigation identity.
  for (let start = 0; start < entries.length; start += 4) {
    if (signal?.aborted) return;
    await Promise.all(
      entries.slice(start, start + 4).map(async ([repository, bindings]) => {
        const heads = [...new Set(bindings.map((b) => b.head))].sort(compare);
        const fields = heads
          .map(
            (
              head,
              i,
            ) => `b${i}: pullRequests(headRefName:${JSON.stringify(head)},states:[OPEN,CLOSED,MERGED],first:100,orderBy:{field:UPDATED_AT,direction:DESC}) {
        pageInfo { hasNextPage } nodes { number title state isDraft updatedAt headRefName headRepository { nameWithOwner } }
      }`,
          )
          .join("\n");
        const [owner, name] = repository.split("/");
        const data = await githubQuery(
          `query { repository(owner:${JSON.stringify(owner)},name:${JSON.stringify(name)}) {
        nameWithOwner ${fields} parent { nameWithOwner ${fields} }
      } }`,
          signal,
        );
        if (signal?.aborted) return;
        const repo = object(data?.repository) ? data.repository : null;
        for (const { row, head } of bindings) {
          const matches: (PullRequest & { updatedAt: string })[] = [];
          let complete = repo !== null;
          for (const base of [repo, repo?.parent].filter(object)) {
            const baseName =
              typeof base.nameWithOwner === "string"
                ? githubRepository(`https://github.com/${base.nameWithOwner}`)
                : null;
            const connection = base[`b${heads.indexOf(head)}`];
            if (
              !baseName ||
              !object(connection) ||
              !Array.isArray(connection.nodes) ||
              !object(connection.pageInfo) ||
              connection.pageInfo.hasNextPage !== false
            ) {
              complete = false;
              continue;
            }
            for (const pr of connection.nodes) {
              if (
                !object(pr) ||
                !object(pr.headRepository) ||
                typeof pr.headRepository.nameWithOwner !== "string" ||
                pr.headRepository.nameWithOwner.toLowerCase() !==
                  repository ||
                pr.headRefName !== head ||
                !Number.isSafeInteger(pr.number) ||
                Number(pr.number) <= 0 ||
                typeof pr.title !== "string" ||
                typeof pr.isDraft !== "boolean" ||
                typeof pr.updatedAt !== "string" ||
                !["OPEN", "CLOSED", "MERGED"].includes(String(pr.state))
              )
                continue;
              matches.push({
                repository: baseName,
                number: Number(pr.number),
                title: pr.title,
                state: String(pr.state),
                isDraft: pr.isDraft,
                updatedAt: pr.updatedAt,
              });
            }
          }
          matches.sort((a, b) => compare(b.updatedAt, a.updatedAt));
          const open = matches.filter((pr) => pr.state === "OPEN");
          // Multiple base branches can have open PRs from the same head; show them all, never guess.
          row.pullRequests = complete
            ? open.length
              ? open
              : matches.slice(0, 1)
            : [];
          row.github = { repository, head, complete };
        }
      }),
    );
  }
}
