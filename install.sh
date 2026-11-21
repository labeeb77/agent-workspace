#!/usr/bin/env bash
# install.sh — idempotent. Links this repo's tools, skills and global instructions into place.
# Never overwrites a real file: existing ones are reported and left alone.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)

# --herdr-config: also install herdr/config.toml (your current one is backed up first)
herdr_config=0
for a in "$@"; do
  case $a in
    --herdr-config) herdr_config=1 ;;
    -h|--help) echo "usage: install.sh [--herdr-config]"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

link() {  # link <target> <link-path>
  local target=$1 path=$2
  if [[ -L $path && $(readlink -f "$path") == "$(readlink -f "$target")" ]]; then echo "ok     $path"; return; fi
  if [[ -e $path || -L $path ]]; then
    if [[ -L $path ]]; then rm "$path"
    elif [[ -f $path ]] && cmp -s "$path" "$target"; then rm "$path"
    else echo "SKIP   $path exists and differs from $target — merge it by hand"; return; fi
  fi
  mkdir -p "$(dirname "$path")"
  ln -s "$target" "$path" && echo "linked $path -> $target"
}

# 1. tools
for f in "$here"/bin/*; do [[ -f $f ]] || continue; link "$f" "$HOME/.local/bin/$(basename "$f")"; done

# 2. skills: canonical copies in ~/.agents/skills, which Codex reads natively
for d in "$here"/skills/*/; do
  n=$(basename "$d")
  p=$HOME/.agents/skills/$n
  if [[ -d $p && ! -L $p ]] && diff -rq "$d" "$p" >/dev/null; then rm -rf "$p"; fi   # identical old copy
  link "${d%/}" "$p"
done
"$here/bin/skills-link"   # ... and expose all of them to Claude Code

# 3a. the full herdr setup (theme, tmux-style keys, top bar): new installs get it; an existing,
#     different config is only replaced with --herdr-config, after a timestamped backup
herdr_cfg=$HOME/.config/herdr/config.toml
if [[ ! -e $herdr_cfg ]]; then
  mkdir -p "$(dirname "$herdr_cfg")"
  cp "$here/herdr/config.toml" "$herdr_cfg" && echo "copied $herdr_cfg"
elif cmp -s "$here/herdr/config.toml" "$herdr_cfg"; then
  echo "ok     $herdr_cfg"
elif (( herdr_config )); then
  bak=$herdr_cfg.bak-$(date +%Y%m%d-%H%M%S)
  cp "$herdr_cfg" "$bak" && cp "$here/herdr/config.toml" "$herdr_cfg"
  echo "replaced $herdr_cfg (backup: $bak)"
  herdr server reload-config >/dev/null 2>&1 || true
else
  echo "keep   $herdr_cfg differs from herdr/config.toml; run with --herdr-config to replace it (backed up)"
fi

# 3b. herdr shortcuts: prefix+a opens a project, prefix+alt+s switches the lead AI, prefix+f focus mode, prefix+t terminal, prefix+y status panel, prefix+i editor
if [[ -f $herdr_cfg ]] && ! grep -q '# >>> ai workspace >>>' "$herdr_cfg"; then
  cat >> "$herdr_cfg" <<'EOF'

# >>> ai workspace >>> (managed by agent-workspace/install.sh)
[[keys.command]]
key = "prefix+a"
type = "popup"
command = "ai"
width = "80%"
height = "70%"

[[keys.command]]
key = "prefix+alt+s"
type = "popup"
command = "ai switch"
width = "60%"
height = "40%"

[[keys.command]]
key = "prefix+f"
type = "shell"
command = "ai focus"

[[keys.command]]
key = "prefix+t"
type = "shell"
command = "ai term"

[[keys.command]]
key = "prefix+y"
type = "shell"
command = "ai status"

[[keys.command]]
key = "prefix+i"
type = "shell"
command = "ai edit"
# <<< ai workspace <<<
EOF
  echo "added herdr shortcuts (prefix+a, prefix+alt+s)"
  herdr server reload-config >/dev/null 2>&1 || true
else
  echo "ok     herdr shortcuts"
fi

# 4. global instructions shared by every harness
link "$here/global/AGENTS.md" "$HOME/.agents/AGENTS.md"
link "$HOME/.agents/AGENTS.md" "$HOME/.codex/AGENTS.md"
claude_md=$HOME/.claude/CLAUDE.md
if [[ ! -e $claude_md ]]; then
  printf '@~/.agents/AGENTS.md\n' > "$claude_md" && echo "created $claude_md (imports ~/.agents/AGENTS.md)"
elif grep -qxF '@~/.agents/AGENTS.md' "$claude_md"; then
  echo "ok     $claude_md imports ~/.agents/AGENTS.md"
else
  echo "WARN   $claude_md exists; add the line '@~/.agents/AGENTS.md' to it"
fi
