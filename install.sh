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
for f in "$here"/bin/*; do link "$f" "$HOME/.local/bin/$(basename "$f")"; done

# 2. skills: canonical copies in ~/.agents/skills, which Codex reads natively
for d in "$here"/skills/*/; do
  n=$(basename "$d")
  p=$HOME/.agents/skills/$n
  if [[ -d $p && ! -L $p ]] && diff -rq "$d" "$p" >/dev/null; then rm -rf "$p"; fi   # identical old copy
  link "${d%/}" "$p"
done
"$here/bin/skills-link"   # ... and expose all of them to Claude Code

# 3. global instructions shared by every harness
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
