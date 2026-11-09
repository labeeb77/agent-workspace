# Global agent instructions

Shared by every harness: Codex reads this as `~/.codex/AGENTS.md`; Claude Code imports it from
`~/.claude/CLAUDE.md`. Source of truth: `~/dev/tools/agent-workspace/global/AGENTS.md`.
Keep it short — it is loaded into every session.

## How to work
- Read the repo's `AGENTS.md` first and follow it. If it still has TODO placeholders, offer once to fill
  them in from the code (keep it under ~100 lines).
- **Small task** (one area, a handful of files, no API/DB contract change): just do it, run the checks,
  report briefly. No plan, no helper agents.
- **Big task** (frontend + backend, schema changes, or several independent parts): use the `orch-plan`
  skill. Ask only the questions that change the implementation, show the plan, and after the developer
  approves, run `ai run` — the status panel shows progress. Don't start helper agents for small tasks.
- Load a `role-*` skill when the work matches it (e.g. `role-backend-dotnet`, `role-frontend-react`).

## Keep the task resumable (any task longer than a few minutes)
- At the start, save the request and the developer's answers to `.orchestrate/requirement.md`.
- After each meaningful step, refresh `.orchestrate/handoff-notes.md` (≤ 40 lines: Goal, Done,
  In progress, Next steps, Decisions, Gotchas, Checks). This is what another AI reads if you hit a
  usage limit, so keep "Next steps" current.
- If the developer says continue/resume, or `.orchestrate/handoff.md` is newer than your session, read
  it first (`handoff` skill).
- `.orchestrate/` is git-excluded; never commit it.

## Safety
- Never commit secrets, `.env` files or credentials, and never copy them into notes or handoff files.
- Ask before: destructive git commands (reset --hard, force-push, branch deletion), database migrations
  or schema changes against a real database, deleting existing features, deploys, publishing anything,
  and merging into the default branch.
- Don't push or open PRs unless the developer asks (they use `ai ship`).
