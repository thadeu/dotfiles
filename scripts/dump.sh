#!/usr/bin/env bash
#
# Pulls the current machine state back into the repo — run this before
# committing, so the repo reflects what you actually have installed.
#
#   ./scripts/dump.sh
#
# Symlinked files need no dumping (they ARE the repo). This captures the
# things that can't be symlinked: package and extension lists.

set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

step() { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }

step "Brewfile"
brew bundle dump --force --file="$DOTFILES/Brewfile"
printf '    %s formulae, %s casks\n' \
  "$(grep -c '^brew' "$DOTFILES/Brewfile")" \
  "$(grep -c '^cask' "$DOTFILES/Brewfile")"

step "VS Code extensions"

if command -v code >/dev/null 2>&1; then
  code --list-extensions > "$DOTFILES/vscode/extensions.txt"
  printf '    %s extensions\n' "$(wc -l < "$DOTFILES/vscode/extensions.txt" | tr -d ' ')"
else
  printf '    \033[2mcode CLI not found — skipped\033[0m\n'
fi

step "Cursor extensions"

if command -v cursor >/dev/null 2>&1; then
  cursor --list-extensions > "$DOTFILES/cursor/extensions.txt"
elif [[ -d "$HOME/.cursor/extensions" ]]; then
  ls "$HOME/.cursor/extensions" \
    | sed -E 's/-[0-9]+\.[0-9]+\.[0-9]+.*$//' \
    | grep -v '^\.' | sort -u > "$DOTFILES/cursor/extensions.txt"
fi

if [[ -f "$DOTFILES/cursor/extensions.txt" ]]; then
  printf '    %s extensions\n' "$(wc -l < "$DOTFILES/cursor/extensions.txt" | tr -d ' ')"
fi

step "Claude Code skills"

if [[ -f "$HOME/.agents/.skill-lock.json" ]]; then
  cp "$HOME/.agents/.skill-lock.json" "$DOTFILES/claude/skill-lock.json"
  python3 -c "
import json
d = json.load(open('$DOTFILES/claude/skill-lock.json'))
srcs = sorted({v['source'] for v in d['skills'].values() if v.get('sourceType') == 'github'})
open('$DOTFILES/claude/skills-sources.txt', 'w').write('\n'.join(srcs) + '\n')
print(f'    {len(srcs)} sources')
"
else
  printf '    \033[2mno skill lockfile — skipped\033[0m\n'
fi

step "Secret scan"
pattern='ghp_[A-Za-z0-9]{36}|gho_[A-Za-z0-9]{36}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|_authToken='

# --untracked matters: newly added files are the likeliest place for a leak.
if git -C "$DOTFILES" grep -nIE --untracked "$pattern" -- . ':!scripts/dump.sh' 2>/dev/null; then
  printf '\n\033[31m✗ SECRETS DETECTED above — do not commit.\033[0m\n'

  exit 1
fi

printf '    clean\n'
printf '\n\033[1mDone.\033[0m Review with: git -C %s diff\n' "$DOTFILES"
