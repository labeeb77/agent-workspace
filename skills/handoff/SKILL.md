---
name: handoff
description: Hand a task over to another coding harness (Claude Code, Codex, OpenCode, ...) or pick one up. Use when the user says "handoff", "switch to codex/claude", "I'm out of credits", "save progress for later", "continue from the handoff", "resume", or when you are close to your own usage or context limit mid-task.
---

Cross-harness handoff works through files, never through a harness's internal session: the outgoing agent
writes notes, `orch` adds the mechanical state (git, plan status, terminal tail), and the incoming agent
reads one file. The helper is `orch` (`~/.local/bin/orch`). Everything lives in `<repo>/.orchestrate/`,
which `orch` keeps out of git.

## Handing off (you are stopping)

1. Write `.orchestrate/handoff-notes.md`, at most 40 lines, using `###` headings:
   - `### Goal` — the requirement in one or two sentences (if `.orchestrate/requirement.md` is missing, also save the full requirement there).
   - `### Done` — what works now, with file paths.
   - `### In progress` — what is half-finished and its exact state.
   - `### Next steps` — numbered, concrete, in order.
   - `### Decisions` — choices made and why (also append lasting ones to `.orchestrate/decisions.md`).
   - `### Gotchas` — traps, failing tests and their cause, commands that matter.
   - `### Checks` — the check command and its last result.
   Write facts, not narrative. Don't paste code that is already in the working tree.
2. Do not commit unless the user asked; the uncommitted diff is part of the handoff.
3. Run `orch handoff`. Add `--to <agent-name>` only if the user named a running Herdr agent to continue
   (it is then prompted directly). Add `--from <your-agent-name>` only when handing off on behalf of
   another agent whose pane should be captured.
4. Tell the user in one line: which file was written and what to say in the next harness —
   "continue from .orchestrate/handoff.md".

If you were rate-limited before you could write notes, the user can run `orch handoff --from <agent>`
from a shell; it captures that agent's last terminal output instead.

## Picking up (you are continuing)

1. Read `.orchestrate/handoff.md`. If it is older than the newest commit or the notes, run `orch handoff`
   first to refresh it.
2. Verify before trusting: check `git status` and the diff against the notes; run the check command.
3. Continue from "Next steps". If something in the notes contradicts the code, believe the code and say so.
4. When you stop, hand off again (above) so the chain never breaks.

If `.orchestrate/state.json` exists, the task is part of an orch plan: as the lead, invoke the
`orch-run` skill instead of working on tasks yourself.
