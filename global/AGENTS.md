# Global agent instructions

Shared by every harness: Codex reads this as `~/.codex/AGENTS.md`; Claude Code imports it from
`~/.claude/CLAUDE.md`. Source of truth: `~/dev/tools/agent-workspace/global/AGENTS.md`.
Keep it short — it is loaded into every session.

## Context and handoff
- Project rules live in the repo's `AGENTS.md` (`CLAUDE.md` only imports it). Read it before working.
- Task state lives in `<repo>/.orchestrate/` and in git, never only in your session.
- If `.orchestrate/handoff.md` exists and the user says continue/resume, or you are near your usage or
  context limit, use the `handoff` skill.
- Multi-step features with several agents: the `orch-plan` and `orch-run` skills (Herdr + `orch`).

## Skills
- Global skills: `~/.agents/skills` (canonical; linked into `~/.claude/skills` by `skills-link`).
- Repo skills: `<repo>/.agents/skills` (`.claude/skills` is a symlink to it).

## Safety
- Never commit secrets, `.env` files or credentials, and never print them into notes or handoff files.
- Ask before destructive operations, database migrations on shared databases, force-pushes, merges into
  the main branch, and deploys.
