---
name: orch-plan
description: Orchestrator step 1 for a Herdr multi-agent team (OpenCode or Amp as lead; Claude/Codex coders; optional reviewer). Use when the user asks to plan or orchestrate a feature, or says "orch-plan". Preflight, discover agents, choose worktree or shared mode, baseline checks, write a dependency-aware task plan. Does NOT execute.
---

You are the LEAD of a Herdr agent team. You may be OpenCode or Amp; the rules are identical.
Load the `herdr` skill for exact CLI syntax. The state helper is `orch` (installed at `~/.local/bin/orch`; if `orch` is not on PATH call it by that full path; run it with no args for usage).
In this skill you ONLY plan. You do not prompt workers and you never edit application code.

Feature request = the user's message that invoked this skill.

## 1. Preflight (stop and report if any check fails)
- `echo $HERDR_ENV` prints `1`. If not, tell the user to start you from a Herdr pane, then stop.
- Inside a git repo, and `git status --porcelain` is empty. If not, ask the user to commit or stash first.
- `mkdir -p .orchestrate`.

## 2. Discover the team
- Run `herdr agent list` and `herdr pane current`. The current pane is YOU. Never prompt it.
- **Coders** = every claude and codex pane. Also count opencode or amp panes that are not you, if the user wants them coding. Name them `claude-1`, `claude-2`, `codex-1`… with `herdr agent rename` and always target them by name. Names stay stable; pane IDs can change when panes close.
- **Reviewer** = AGY, or one spare agent the user picks. Name it `reviewer`. If there is none, use `Reviewer: none`.
- If it's unclear which pane should play which role, ask the user.

## 3. Choose the isolation mode (ask the user if they haven't said)
- **worktree** (default when there are 2+ coders and 2+ tasks that can run independently): each coder gets its own git worktree at `../<repo>-wt/<worker>`, so they can work in parallel without overwriting each other. Each task gets its own branch, which is squash-merged into the integration branch when the task is done.
- **shared**: everyone works in this folder, one task at a time. The coder pool still means whichever of Claude or Codex is free takes the next task. Use this for small features, or if the user doesn't want worktrees.

**Worktree mode setup:**
1. Write the plan (step 5), run `orch sync`, then run `orch start`. This creates the integration branch and the worker worktrees.
2. Each coder's agent must run INSIDE its worktree, or it can't edit files there. For each worker:
   - Split a pane with `--cwd <worktree>`.
   - Launch the agent in it with `herdr pane run`: `claude --permission-mode acceptEdits` for Claude, or `codex --full-auto` for Codex.
   - Give it the worker's name with `herdr agent rename`.
   - Close or ignore the old coder panes that are sitting in the main folder.
3. If you cannot do this through herdr, print the exact commands for the user and wait for them.
4. Run `orch start` again. Every worker must show `herdr=found`.

## 4. Detect the check and setup commands; record a baseline
- **Check command**: one command for lint, typecheck and tests, taken from package.json, Makefile, pubspec.yaml, Cargo.toml, pyproject.toml, etc.
- **Setup command**: whatever a fresh worktree needs, e.g. `npm ci`, `flutter pub get` or `uv sync`. Use `none` for shared mode or if nothing is needed.
- Run the check command yourself in your own shell and save the output tail to `.orchestrate/baseline.txt`. If the baseline already fails, list what fails. Tasks are later judged on "no NEW failures".

## 5. Write `.orchestrate/plan.md` in EXACTLY this format (`orch sync` parses it)

```
# Plan: <feature title>
Branch: orch/<short-slug>
Check command: <command>
Setup command: <command | none>
Isolation: worktree | shared
Max parallel: <number, usually = number of coders>
Workers: claude-1 (claude), codex-1 (codex)
Reviewer: reviewer (agy) | none

## Global instructions
<empty — user may fill in>

## [x] M1: <title>
Depends on: none
Prefer: any | claude | codex
Review: yes | no
Likely files: src/a.ts, src/b.ts
Goal: <one sentence>
Scope:
- <bullet>
Acceptance criteria:
- <testable bullet>
Open questions:
- none
Notes from user:
```

Write each task section so it stands alone: in autopilot mode, `orch write-task` hands the section to the worker verbatim, plus the global instructions and the reports of the tasks it depends on. Anything the worker needs must be in its own section.

How to split the work into tasks:
- **Size**: 2–6 tasks. Each task is a cohesive slice one agent can finish in one sitting, and tightly coupled work stays together.
- **Dependencies are a graph, not a list.** M3 `Depends on: M1, M2` means M3 starts only after M1 and M2 are merged, so its branch contains their code. Leave independent work dependency-free so it can run in parallel. Typical shape: contract or schema first, then backend and frontend in parallel, then integration.
- **Contracts first.** When two parallel tasks must agree on something (API shape, types, DB schema), put that agreement in an earlier task they both depend on, or spell it out exactly in both tasks' Scope. Never let two parallel agents invent the same interface separately.
- **List realistic Likely files.** `orch sync` warns when two parallel tasks touch the same file. Then either add a dependency or accept a likely merge conflict.
- **Prefer**: `claude` for UI and refactors, `codex` for focused backend or test work, otherwise `any`. This is a preference, not a lock: if the preferred agent is busy or rate-limited, the other one takes the task.
- **Review**: `yes` for UI, API contracts, auth, payments and schema changes.
- **ZERO GUESSWORK**: missing business rules, undefined data shapes, and auth or security tradeoffs go under "Open questions" with 2–3 concrete options. `orch sync` marks such tasks `needs-answer`, and anything depending on them waits.

## 6. Validate and hand back
- Run `orch sync`. Fix every ERROR (unknown dependency, cycle, bad header) and re-run. Report every WARN to the user.
- Run `orch status` and show the user the table, the parallel shape (which tasks run together), and all open questions.
- Then say: "Plan written to .orchestrate/plan.md. Edit it: untick `[x]` to skip a task, change `Depends on`/`Prefer`, answer open questions under 'Notes from user' and set 'Open questions: - none', add global instructions. Then either run `orch autopilot` in a terminal (cheapest: no AI in the loop), or run orch-run to let me drive (OpenCode: `/orch-run`; Amp: "use the orch-run skill")."
- STOP.
