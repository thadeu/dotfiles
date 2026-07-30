#!/usr/bin/env bash
#
# Installs every VS Code and Cursor extension listed in the repo.
#
#   ./scripts/restore-extensions.sh

set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

install_from() {
  local bin="$1" list="$2" label="$3"

  if ! command -v "$bin" >/dev/null 2>&1; then
    printf '\033[2m%s CLI not found — skipping %s\033[0m\n' "$bin" "$label"

    return
  fi

  if [[ ! -f "$list" ]]; then
    printf '\033[2mno list at %s — skipping %s\033[0m\n' "$list" "$label"

    return
  fi

  printf '\n\033[1m%s\033[0m (%s extensions)\n' "$label" "$(wc -l < "$list" | tr -d ' ')"

  local installed
  installed="$("$bin" --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')"

  while IFS= read -r ext; do
    [[ -z "$ext" || "$ext" == \#* ]] && continue

    if grep -qxF "$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')" <<<"$installed"; then
      printf '  \033[2m· %s\033[0m\n' "$ext"
    else
      printf '  \033[32m+\033[0m %s\n' "$ext"
      "$bin" --install-extension "$ext" --force >/dev/null 2>&1 \
        || printf '  \033[31m✗ failed: %s\033[0m\n' "$ext"
    fi
  done < "$list"
}

install_from code   "$DOTFILES/vscode/extensions.txt" "VS Code"
install_from cursor "$DOTFILES/cursor/extensions.txt" "Cursor"

printf '\nDone.\n'
