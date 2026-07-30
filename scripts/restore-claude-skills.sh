#!/usr/bin/env bash
#
# Reinstalls Claude Code skills and relinks the command repos.
#
#   ./scripts/restore-claude-skills.sh
#
# Skills come from the vercel-labs/skills CLI; commands are symlinks into
# personal repos under ~/code, which get cloned if missing.

set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CODE_DIR="$HOME/code"

# Repos that provide ~/.claude/commands/* entries.
COMMAND_REPOS=(
  thadeu/claude-anki
  thadeu/claude-issue-description
  thadeu/claude-memory-notes
  thadeu/claude-trello
)

printf '\n\033[1mSkills\033[0m\n'

if command -v npx >/dev/null 2>&1; then
  while IFS= read -r src; do
    [[ -z "$src" || "$src" == \#* ]] && continue

    printf '  \033[32m+\033[0m %s\n' "$src"
    npx -y skills add "$src" -a claude-code -g -y >/dev/null 2>&1 \
      || printf '  \033[31m✗ failed: %s\033[0m\n' "$src"
  done < "$DOTFILES/claude/skills-sources.txt"
else
  printf '  \033[31mnpx not found — install node first\033[0m\n'
fi

printf '\n\033[1mCommand repos\033[0m\n'
mkdir -p "$CODE_DIR" "$HOME/.claude/commands"

for repo in "${COMMAND_REPOS[@]}"; do
  name="${repo#*/}"
  dest="$CODE_DIR/$name"

  if [[ -d "$dest" ]]; then
    printf '  \033[2m· %s\033[0m\n' "$name"
  else
    printf '  \033[32m+\033[0m %s\n' "$name"
    git clone --depth=1 "https://github.com/$repo.git" "$dest" >/dev/null 2>&1 \
      || { printf '  \033[31m✗ clone failed: %s\033[0m\n' "$repo"; continue; }
  fi

  if [[ -d "$dest/commands" ]]; then
    ln -sfn "$dest/commands" "$HOME/.claude/commands/${name#claude-}"
  fi
done

printf '\nDone. Run "claude" and check /help to verify.\n'
