# ai workspace

A ready-made [Herdr](https://herdr.dev) setup for coding with AI agents. Claude Code and Codex are
interchangeable coding AIs in one terminal workspace: you talk to one lead AI, it does small tasks
itself and plans big ones for helper agents, a status panel shows progress, and switching AIs keeps
the task's context. It also ships a tmux-style Herdr config (keys, theme, top bar).

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

## Requirements

- Linux or macOS, bash, git
- [Herdr](https://herdr.dev) 0.9 or newer (the terminal app, not the Herdr desktop app)
- [uv](https://docs.astral.sh/uv/): runs `ai` and installs its Python dependency (`rich`) on first run
- python3 3.11+ and `jq`
- [Claude Code](https://claude.com/claude-code) and/or [Codex](https://github.com/openai/codex),
  installed and signed in
- Optional: [`gh`](https://cli.github.com) for pull requests (`ai ship`), a
  [Nerd Font](https://www.nerdfonts.com) in your terminal for the top-bar icons

## Install

```bash
git clone https://github.com/labeeb77/agent-workspace ~/dev/tools/agent-workspace
cd ~/dev/tools/agent-workspace
./install.sh                  # tools, skills, global AI rules, herdr shortcuts
./install.sh --herdr-config   # same, and also use this repo's full herdr config (see below)
```

Make sure `~/.local/bin` is on your `PATH`. The installer is idempotent: run it again any time.

What it puts where:

| What | Where |
|---|---|
| `ai`, `orch`, `ai-stat`, `ctx-init`, `skills-link` | symlinks in `~/.local/bin` |
| Skills (`orch-plan`, `orch-run`, `handoff`, `role-*`) | symlinks in `~/.agents/skills`, exposed in `~/.claude/skills` |
| Global AI rules | `~/.agents/AGENTS.md` → also `~/.codex/AGENTS.md`; `~/.claude/CLAUDE.md` imports it |
| Herdr config | `~/.config/herdr/config.toml` (see below) |

It never overwrites one of your files: a real file in the way is reported (`SKIP`) and left alone.

### The Herdr config

`herdr/config.toml` is a tmux-style setup: prefix `ctrl+space`, the terminal's own colors with a
dark sidebar and purple accent, no pane gaps or scrollbars, mouse on, and a top bar with agents,
CPU, RAM (`ai-stat`) and the date.

- **No herdr config yet:** the installer copies it in.
- **You already have one:** it's kept, and only the `ai` shortcuts are appended. Run
  `./install.sh --herdr-config` to use this repo's config instead; yours is saved as
  `config.toml.bak-<date>` first.

Keys (prefix = `ctrl+space`):

| Keys | Action |
|---|---|
| `prefix+h` / `alt+enter`, `prefix+v` / `alt+shift+enter` | split horizontal / vertical |
| `ctrl+alt+arrows` | move between panes |
| `ctrl+alt+shift+arrows` | resize pane |
| `prefix+z`, `prefix+x` | zoom, close pane |
| `prefix+c`, `alt+1..9`, `alt+left/right` | new tab, go to tab, previous/next tab |
| `prefix+shift+c`, `alt+up/down` | new workspace, previous/next workspace |
| `prefix+[` | copy mode |
| `prefix+q`, `prefix+?`, `prefix+d` | reload config, help, detach |
| `prefix+a`, `prefix+alt+s`, `prefix+f`, `prefix+t` | `ai` open project, switch AI, focus mode, terminal |

## Everyday use

| You want to… | Do this |
|---|---|
| Open a project | `ai` from any terminal, or **prefix+a** inside Herdr |
| Start with Codex as the lead | `ai -c` |
| Give it work | type the request in the lead pane |
| Run an approved plan | the lead runs `ai run`, or press **r** in the panel |
| Approve a step waiting for you | **a** in the panel |
| Switch Claude ⇄ Codex | **s** in the panel, or **prefix+alt+s** (`ai switch --quick` if it's rate-limited) |
| Run your own commands | **t** in the panel or **prefix+t**: a shell under the AI; again to jump back |
| Give the AI the full screen | **f** in the panel or **prefix+f** (again to restore); **prefix+b** hides the sidebar |
| Finish (commit, push, PR) | **p** in the panel (`ai ship`). It always asks before pushing. |

## Configuration

Optional `~/.config/ai/config.toml`:

```toml
lead  = "claude"     # or "codex"
roots = ["~/dev"]    # where your repositories live
```

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
  `~/.claude/skills`): `orch-plan`, `orch-run`, `handoff`, plus the `role-*` specialists for
  React/Next, Python, Flutter, .NET/EF, Node, SQL, code review and security review.

## Update

```bash
cd ~/dev/tools/agent-workspace && git pull && ./install.sh
```

Tools and skills are symlinks, so `git pull` updates them at once. The herdr config is a copy:
re-run with `--herdr-config` to take a newer one.

## Troubleshooting

- **The status panel is gone and the right pane shows a plain shell prompt.** Herdr restores panes
  after a restart but not the programs in them. Click into that pane and run `ai panel`.
- **Top-bar icons show as boxes.** Use a Nerd Font in your terminal.
- **`ai: command not found`.** Add `~/.local/bin` to your `PATH`.

## Uninstall

Remove the symlinks in `~/.local/bin` and `~/.agents/skills` that point into this repo, the
`# >>> ai workspace >>>` block in `~/.config/herdr/config.toml` (or restore your `.bak-*` copy),
and `~/.agents/AGENTS.md`.
