# agent-workspace

A multi-agent dev workspace that sits on top of tools you already run: **Herdr** for terminals and agent
state, **`orch`** as the deterministic scheduler, **skills** shared by every harness, and **files plus git**
as the only shared memory. No daemon and no database.

```
Herdr workspace (per project)                       orch (no LLM)                <repo>/.orchestrate/
┌ lead: claude|codex ┬ board: orch board --watch ┐   plan.md → state.json         requirement.md  plan.md
│ orch-plan/orch-run │ coders in worktrees       │ → deps · dispatch · checks  → state.json  handoff.md
│ handoff skill      │ claude-1, codex-1, review │   review · gates · merge      decisions.md  summary.md
└────────────────────┴───────────────────────────┘   handoff · PR · CI           (git-excluded)
```

## Install

```bash
~/dev/tools/agent-workspace/install.sh     # idempotent; never overwrites a file that differs
```

It links:

- `bin/*` into `~/.local/bin`
- `skills/*` into `~/.agents/skills` (the canonical folder, which Codex reads natively); `skills-link` then links every skill there into `~/.claude/skills`
- `global/AGENTS.md` as `~/.agents/AGENTS.md`, which `~/.codex/AGENTS.md` links to and `~/.claude/CLAUDE.md` imports (`@~/.agents/AGENTS.md`)

## Daily use

| Step | Command |
|---|---|
| Open a project (inside Herdr) | `ws [filter] [--lead codex]`: fzf picker, then a workspace with the lead on the left and the board on the right |
| One-time per repo | `ctx-init`: `AGENTS.md` becomes the shared rules file and `CLAUDE.md` = `@AGENTS.md` (`--migrate` converts an existing CLAUDE.md) |
| Plan a feature | in the lead: `/orch-plan <requirement>` (Codex: `$orch-plan …`), then edit `.orchestrate/plan.md` |
| Run it | `orch autopilot` (no AI in the loop), or `/orch-run` to have the lead drive |
| Watch | `orch board --watch` |
| Approval gates | tasks with `Approve: yes` stop after checks and review: `orch approve M3` / `orch reject M3 "why"` |
| Switch harness mid-task | say "handoff" in the agent (skill writes notes), or run `orch handoff [--from codex-1] [--to claude-1]`; in the other harness: "continue from .orchestrate/handoff.md" |
| Ship | `orch pr [--draft]` (asks before pushing), `orch ci --watch` |

Rate limits: when autopilot sees a coder hit a usage limit, it parks the task with a wip commit and benches
that coder for `ORCH_COOLDOWN_MIN` (default 60). It then gives the task to the other coder, with the limit
reason and the last terminal lines in `task.md`.

## Adding things

- **Global skill:** put a `SKILL.md` folder in `~/.agents/skills/<name>` (or in `skills/` here, then `install.sh`), then run `skills-link`.
- **Repo skill:** put it in `<repo>/.agents/skills/<name>`; `.claude/skills` is a symlink to it (`skills-link --project`).
- **Another harness:** Herdr already detects opencode, gemini, amp and others. List them in the plan's `Workers:` line.

## Not done yet (roadmap)

Role skills (backend, frontend, db, security-review), shared MCP config across harnesses, harness choice
from past results, and token/cost tracking.
