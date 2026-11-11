# ai workspace

Claude Code and Codex as interchangeable coding AIs in one Herdr terminal workspace. You talk to one
lead AI; it does small tasks itself and plans big ones for helper agents. A status panel shows
progress, and switching AIs keeps the task's context.

```
┌ spaces ─────┬─ lead ───────────────────────────────┬─ status ─────────────────────────┐
│ ● ordero2   │  Claude                              │ ordero2                      dev │
│             │                                      │ ● claude  lead · working         │
│ agents      │  > Build customer list with search   │                                  │
│ ● claude    │                                      │ PLAN  Customer management        │
│ ● codex-1   │                                      │ ━━━━━━━━━━━━━━━━━━━━━━━━━━  4/6  │
│             │                                      │ ✔ API contract     codex-1 done  │
│             │                                      │ ⟳ List UI          claude-1 7m   │
│             │                                      │ ⚑ Migration        needs you     │
│             │                                      │  s switch  a approve  p ship     │
└─────────────┴──────────────────────────────────────┴──────────────────────────────────┘
```

## Everyday use

| You want to… | Do this |
|---|---|
| Open a project | `ai` from any terminal, or **prefix+a** inside Herdr (prefix = ctrl+space) |
| Start with Codex as the lead | `ai -c` |
| Give it work | type the request in the lead pane |
| Run an approved plan | the lead runs `ai run`, or press **r** in the panel |
| Approve a step waiting for you | **a** in the panel |
| Switch Claude ⇄ Codex | **s** in the panel, or **prefix+alt+s** (`ai switch --quick` if it's rate-limited) |
| Give the AI the full screen | **f** in the panel or **prefix+f** (again to restore); **prefix+b** hides the sidebar |
| Finish (commit, push, PR) | **p** in the panel (`ai ship`). It always asks before pushing. |

## How it works

- **Herdr** handles the terminals, sidebar and agent status. **`orch`** (bin/orch) is the plain-Python
  scheduler that runs plans: dependencies, worktrees, checks, review, approval gates, merges.
  **`ai`** (bin/ai) is the front door and the status panel.
- **Shared context:** `~/.agents/AGENTS.md` holds the global rules for both AIs. Each repo's `AGENTS.md`
  holds project rules, and `CLAUDE.md` just imports it. Task state lives in `<repo>/.orchestrate/`
  (git-excluded): `requirement.md`, `handoff-notes.md`, `plan.md`, `state.json`, `summary.md`.
- **Switching** saves the notes and git state to `.orchestrate/handoff.md`, then opens the other AI
  in the lead's place with "read it and continue".
- **Skills** live in `~/.agents/skills` (Codex reads that folder; each skill is symlinked into
  `~/.claude/skills`): `orch-plan`, `orch-run`, `handoff`, plus the `role-*` specialists for React/Next, Python, Flutter,
  .NET/EF, Node, SQL, code review and security review.

## Install / update

```bash
~/dev/tools/agent-workspace/install.sh    # idempotent; links tools, skills, global rules, herdr keys
```

Optional `~/.config/ai/config.toml`:

```toml
lead  = "claude"     # or "codex"
roots = ["~/dev"]    # where your repositories live
```

## Later (not built yet)

Shared MCP tools (Playwright, databases), tasks spanning frontend and backend repos, usage/cost display.
