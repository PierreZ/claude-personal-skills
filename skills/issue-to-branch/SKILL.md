---
name: issue-to-branch
description: Read open issues from GitHub or GitLab, automatically choose the next logical one (or use a given issue number), spawn sub-agents to explore the code and plan the work, then implement it on a fresh branch cut from an updated main. Use when the user wants to "work the next issue", "pick up a ticket", "grab an issue", or turn a GitHub/GitLab issue into a branch and implementation.
argument-hint: "[issue number or URL — optional; omit to auto-pick the next issue]"
allowed-tools: Bash, Read, Edit, Write, Grep, Glob, Agent, TodoWrite
---

# Issue → Branch

Turn an open issue into a working branch. Pick an issue, plan it with sub-agents, then implement it on a branch cut from a freshly-updated `main`.

Issue selector (optional): <issue>$ARGUMENTS</issue>

## Step 0 — Detect the forge

Inspect `git remote -v`. Pick the CLI from the remote host:

| Host | CLI | List issues (with labels/assignee) | View issue |
|------|-----|-------------|------------|
| github.com | `gh` | `gh issue list --state open --json number,title,labels,assignees,milestone` | `gh issue view <n> --comments` |
| gitlab.* | `glab` | `glab issue list --all` | `glab issue view <n> --comments` |

If the chosen CLI is missing or unauthenticated, stop and tell the user how to install/auth it (`gh auth login` / `glab auth login`).

## Step 1 — Pick an issue

If `<issue>` is a number or URL, use it directly — skip to Step 2.

Otherwise **choose the next logical issue yourself** — do not ask the user. List open issues with labels, milestone, and assignee, then rank them:

| Priority | Prefer |
|----------|--------|
| 1 | Assigned to me / the current user |
| 2 | Highest priority label (`P0`/`P1`, `critical`, `priority::high`, `bug` over `enhancement`) |
| 3 | Part of the active/nearest milestone |
| 4 | Oldest among ties (FIFO) |

**Skip** issues that are blocked, labelled `needs-info`/`waiting`/`on-hold`, depend on another open issue, or are clearly underspecified. Pick the single best remaining candidate, state in one line which issue you chose and why, then proceed without waiting for confirmation.

## Step 2 — Read the issue fully

View the chosen issue **including comments**. Extract: the actual ask, acceptance criteria, linked issues/PRs, and any constraints discussed in comments. Restate the goal in one sentence and confirm you understood it.

## Step 3 — Plan with sub-agents

Spawn sub-agents in parallel (one message, multiple `Agent` calls) to keep planning out of the main context:

1. **Explore agent** (`Explore`) — map the code the issue touches: relevant files, existing patterns, conventions, tests. Return file paths and a description of how the area works.
2. **Plan agent** (`Plan`) — given the issue text + exploration, produce a step-by-step implementation plan: files to change, the approach, edge cases, and how to verify.

Synthesize their output into a concise plan. For anything touching **>3 files**, present the plan and get a "go" before implementing (per the user's plan-mode preference). Smaller changes: proceed straight to implementation.

## Step 4 — Branch off updated main

```
git stash         # only if the tree is dirty — warn the user first
git checkout main
git pull --ff-only
git checkout -b <branch>
```

Branch name: `<issue-number>-<short-kebab-slug>` (e.g. `142-retry-on-timeout`). Match any existing branch-naming convention you observe in `git branch -a`.

## Step 5 — Implement

- Follow the plan. Make **surgical changes** — touch only what the issue requires.
- Prefer `Edit` over `Write`; match surrounding style.
- Run the project's checks before committing (tests, linters, formatters — e.g. `cargo fmt && cargo clippy`, `npm test`). Loop until green.
- Commit with a **conventional-commit** message that references the issue (`fix: retry on timeout (#142)`).
- **Do not push and do not open a PR** unless the user explicitly asks.

## Guidelines

- One issue at a time. Finish or hand back before starting another.
- Pick autonomously — only the >3-file plan (Step 3) is a checkpoint; issue selection is not.
- If the chosen issue turns out to be underspecified once you read it, say so and pick the next candidate rather than guessing — don't stall on a question.
- Leave the work in a runnable, committed state; report which issue you took, what's done, and what's left.
