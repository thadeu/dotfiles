#!/usr/bin/env bash
#
# Symlinks every tracked dotfile into place. Idempotent: safe to re-run.
# Anything it would overwrite gets backed up to ~/.dotfiles-backup/<timestamp>/.
#
# Usage:
#   ./install.sh              # link everything
#   ./install.sh shell git    # link only the named groups
#   ./install.sh --dry-run    # show what would happen
#   ./install.sh --list       # list available groups

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
VSCODE_USER="$HOME/Library/Application Support/Code/User"
CURSOR_USER="$HOME/Library/Application Support/Cursor/User"

DRY_RUN=false
linked=0 skipped=0 backed_up=0

# --- pretty output -----------------------------------------------------------

if [[ -t 1 ]]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'
  BLUE=$'\033[34m'; RED=$'\033[31m'; RESET=$'\033[0m'
else
  BOLD=""; DIM=""; GREEN=""; YELLOW=""; BLUE=""; RED=""; RESET=""
fi

info()  { printf '%s\n' "${BLUE}::${RESET} ${BOLD}$*${RESET}"; }
ok()    { printf '  %s %s\n' "${GREEN}✓${RESET}" "$*"; }
warn()  { printf '  %s %s\n' "${YELLOW}!${RESET}" "$*"; }
err()   { printf '  %s %s\n' "${RED}✗${RESET}" "$*" >&2; }
note()  { printf '  %s\n' "${DIM}$*${RESET}"; }

# Shorten $HOME to ~ for display.
tilde() {
  case "$1" in
    "$HOME") printf '~' ;;
    "$HOME"/*) printf '~%s' "${1#"$HOME"}" ;;
    *) printf '%s' "$1" ;;
  esac
}

# --- core --------------------------------------------------------------------

# link <source-relative-to-repo> <absolute-destination>
link() {
  local src="$DOTFILES/$1" dest="$2"

  if [[ ! -e "$src" ]]; then
    err "missing in repo: $1"

    return
  fi

  # Already pointing where we want it.
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    note "$(tilde "$dest") already linked"
    ((skipped++)) || true

    return
  fi

  if $DRY_RUN; then
    ok "$(tilde "$dest") -> $1"
    ((linked++)) || true

    return
  fi

  # Back up whatever is in the way (real file, dir, or stale symlink).
  if [[ -e "$dest" || -L "$dest" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "${dest#$HOME/}")"
    mv "$dest" "$BACKUP_DIR/${dest#$HOME/}"
    warn "backed up existing $(tilde "$dest")"
    ((backed_up++)) || true
  fi

  mkdir -p "$(dirname "$dest")"
  ln -sfn "$src" "$dest"
  ok "$(tilde "$dest") -> $1"
  ((linked++)) || true
}

# --- groups ------------------------------------------------------------------

group_shell() {
  info "shell (zsh, tmux, p10k)"
  link home/.zshrc      "$HOME/.zshrc"
  link home/.zshenv     "$HOME/.zshenv"
  link home/.zprofile   "$HOME/.zprofile"
  link home/.p10k.zsh   "$HOME/.p10k.zsh"
  link home/.tmux.conf  "$HOME/.tmux.conf"
  link home/.hushlogin  "$HOME/.hushlogin"
  link home/.yarnrc     "$HOME/.yarnrc"

  if [[ ! -f "$HOME/.zshrc.local" ]] && ! $DRY_RUN; then
    cp "$DOTFILES/home/.zshrc.local.example" "$HOME/.zshrc.local"
    warn "created ~/.zshrc.local from template — fill in your tokens"
  fi
}

group_git() {
  info "git"
  link home/.gitconfig      "$HOME/.gitconfig"
  link config/git           "$HOME/.config/git"
  link config/gh/config.yml "$HOME/.config/gh/config.yml"
  note "run 'gh auth login' to authenticate (hosts.yml is not versioned)"
}

group_terminal() {
  info "terminal emulators (ghostty, alacritty, zellij)"
  link config/ghostty   "$HOME/.config/ghostty"
  link config/alacritty "$HOME/.config/alacritty"
  link config/zellij    "$HOME/.config/zellij"

  # Ghostty reads ~/.config/ghostty/config, but a config in Application
  # Support silently outranks it. Move that one aside so the symlink wins.
  local shadow="$HOME/Library/Application Support/com.mitchellh.ghostty/config"

  if [[ -f "$shadow" && ! -L "$shadow" ]]; then
    if $DRY_RUN; then
      warn "would move aside $(tilde "$shadow") (shadows ~/.config/ghostty/config)"
    else
      mkdir -p "$BACKUP_DIR/$(dirname "${shadow#$HOME/}")"
      mv "$shadow" "$BACKUP_DIR/${shadow#$HOME/}"
      warn "moved aside $(tilde "$shadow") — it would shadow the symlink"
      ((backed_up++)) || true
    fi
  fi
}

group_nvim() {
  info "neovim"
  link config/nvim "$HOME/.config/nvim"
}

group_tools() {
  info "dev tools (mise, opencode)"
  link config/mise     "$HOME/.config/mise"
  link config/opencode "$HOME/.config/opencode"
}

group_ssh() {
  info "ssh"
  link ssh/config "$HOME/.ssh/config"

  if ! $DRY_RUN; then
    chmod 700 "$HOME/.ssh" 2>/dev/null || true
  fi
}

group_vscode() {
  info "vscode"

  if [[ ! -d "$VSCODE_USER" ]]; then
    warn "VS Code not installed — skipping"

    return
  fi

  link vscode/settings.json    "$VSCODE_USER/settings.json"
  link vscode/keybindings.json "$VSCODE_USER/keybindings.json"
  link vscode/snippets         "$VSCODE_USER/snippets"
}

group_cursor() {
  info "cursor"

  if [[ ! -d "$CURSOR_USER" ]]; then
    warn "Cursor not installed — skipping"

    return
  fi

  link cursor/settings.json    "$CURSOR_USER/settings.json"
  link cursor/keybindings.json "$CURSOR_USER/keybindings.json"
  link vscode/snippets         "$CURSOR_USER/snippets"
}

group_claude() {
  info "claude code"
  link claude/CLAUDE.md     "$HOME/.claude/CLAUDE.md"
  link claude/settings.json "$HOME/.claude/settings.json"
  note "run ./scripts/restore-claude-skills.sh to reinstall skills"
}

ALL_GROUPS=(shell git terminal nvim tools ssh vscode cursor claude)

# --- main --------------------------------------------------------------------

targets=()

for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=true ;;
    --list|-l)
      printf '%s\n' "${ALL_GROUPS[@]}"

      exit 0
      ;;
    --help|-h)
      sed -n '2,11p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'

      exit 0
      ;;
    -*)
      err "unknown flag: $arg"

      exit 1
      ;;
    *) targets+=("$arg") ;;
  esac
done

if [[ ${#targets[@]} -eq 0 ]]; then
  targets=("${ALL_GROUPS[@]}")
fi

$DRY_RUN && info "DRY RUN — nothing will be written"

for g in "${targets[@]}"; do
  if [[ " ${ALL_GROUPS[*]} " != *" $g "* ]]; then
    err "unknown group: $g (see --list)"

    exit 1
  fi

  "group_$g"
done

printf '\n%s %d linked, %d already ok, %d backed up\n' \
  "${BOLD}done:${RESET}" "$linked" "$skipped" "$backed_up"

if [[ $backed_up -gt 0 ]]; then
  note "backups in $(tilde "$BACKUP_DIR")"
fi
