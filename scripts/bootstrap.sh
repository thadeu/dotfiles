#!/usr/bin/env bash
#
# Full setup for a brand-new macOS machine. Run this first.
#
#   ./scripts/bootstrap.sh
#
# Every step is idempotent — re-running is safe.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

step() { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
skip() { printf '    \033[2m%s\033[0m\n' "$*"; }

step "Xcode Command Line Tools"

if xcode-select -p >/dev/null 2>&1; then
  skip "already installed"
else
  xcode-select --install
  echo "    Finish the GUI installer, then re-run this script."

  exit 0
fi

step "Homebrew"

if command -v brew >/dev/null 2>&1; then
  skip "already installed"
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

step "Homebrew packages (Brewfile)"

# A single stale entry shouldn't abort the shell setup that follows.
if ! brew bundle --file="$DOTFILES/Brewfile"; then
  printf '    \033[33m!\033[0m brew bundle had failures — fix the Brewfile and re-run\n'
fi

step "oh-my-zsh"

if [[ -d "$HOME/.oh-my-zsh" ]]; then
  skip "already installed"
else
  RUNZSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

step "zsh plugins and theme"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

clone_if_missing() {
  local repo="$1" dest="$2"

  if [[ -d "$dest" ]]; then
    skip "$(basename "$dest") already present"
  else
    git clone --depth=1 "$repo" "$dest"
  fi
}

clone_if_missing https://github.com/zsh-users/zsh-autosuggestions \
  "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting \
  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone_if_missing https://github.com/romkatv/powerlevel10k \
  "$ZSH_CUSTOM/themes/powerlevel10k"

step "Symlinking dotfiles"
"$DOTFILES/install.sh"

step "Runtimes (mise)"

if command -v mise >/dev/null 2>&1; then
  mise install
else
  skip "mise not installed — check the Brewfile"
fi

step "Editor extensions"
"$DOTFILES/scripts/restore-extensions.sh"

step "Claude Code skills"
"$DOTFILES/scripts/restore-claude-skills.sh"

cat <<'EOF'

Bootstrap complete. Remaining manual steps:

  1. Fill in ~/.zshrc.local with your tokens
  2. gh auth login
  3. npm login              (or write ~/.npmrc by hand)
  4. Copy your SSH keys across, then: chmod 600 ~/.ssh/id_*
  5. Restart the terminal

EOF
