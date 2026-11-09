#!/usr/bin/env bash
# install.sh — idempotent. Links this repo's tools, skills and global instructions into place.
# Never overwrites a real file: existing ones are reported and left alone.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)

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

# 3. herdr shortcuts: prefix+a opens a project, prefix+alt+s switches the lead AI
herdr_cfg=$HOME/.config/herdr/config.toml
if [[ -f $herdr_cfg ]] && ! grep -q '# >>> ai workspace >>>' "$herdr_cfg"; then
  cat >> "$herdr_cfg" <<'EOF'

# >>> ai workspace >>> (managed by ~/dev/tools/agent-workspace/install.sh)
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
