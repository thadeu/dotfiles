# dotfiles

macOS setup for [@thadeu](https://github.com/thadeu) — zsh, neovim, terminals, VS Code, Cursor and Claude Code.

## New machine

```bash
git clone https://github.com/thadeu/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./scripts/bootstrap.sh
```

`bootstrap.sh` installs Xcode CLI tools, Homebrew, everything in the `Brewfile`,
oh-my-zsh with its plugins, then symlinks the dotfiles and restores editor
extensions and Claude skills. Every step is idempotent.

Afterwards, four things are still manual — they need credentials:

| | |
|---|---|
| Tokens | fill in `~/.zshrc.local` (created from the template on first install) |
| GitHub CLI | `gh auth login` |
| npm | `npm login` |
| SSH keys | copy them across, then `chmod 600 ~/.ssh/id_*` |

## Existing machine

```bash
./install.sh              # symlink everything
./install.sh shell nvim   # only these groups
./install.sh --dry-run    # preview, write nothing
./install.sh --list       # show groups
```

Nothing is overwritten silently — whatever is in the way moves to
`~/.dotfiles-backup/<timestamp>/` first.

Groups: `shell` `git` `terminal` `nvim` `tools` `ssh` `vscode` `cursor` `claude`

## Layout

```
home/          → ~/                     zsh, tmux, p10k, gitconfig
config/        → ~/.config/             nvim, ghostty, alacritty, zellij, mise, gh, git, opencode
ssh/           → ~/.ssh/                config only, never keys
vscode/        → ~/Library/.../Code/User/
cursor/        → ~/Library/.../Cursor/User/
claude/        → ~/.claude/             CLAUDE.md, settings, skill sources
scripts/                                bootstrap, restore, dump
Brewfile                                formulae + casks
```

Files are symlinked, so editing `~/.zshrc` edits the repo directly. Commit when
you're happy with it.

## Keeping the repo in sync

Package and extension lists can't be symlinked, so re-dump them before committing:

```bash
./scripts/dump.sh
```

That refreshes the `Brewfile`, both extension lists and the Claude skill
sources, then scans the whole repo for leaked credentials and fails if it finds
any.

## Secrets

Nothing secret is committed. Specifically:

- **`~/.zshrc.local`** holds all tokens and is gitignored. `home/.zshrc.local.example`
  is the template; `.zshrc` sources the real file at the end if it exists.
- **`~/.npmrc`** is not versioned (it carries an auth token) — run `npm login`.
- **`config/gh/hosts.yml`** is not versioned (OAuth token) — run `gh auth login`.
- **SSH keys** are never in this repo; only `~/.ssh/config`.

`scripts/dump.sh` enforces this with a grep for token patterns.

## Claude Code

Skills are installed via the [vercel-labs/skills](https://github.com/vercel-labs/skills)
CLI rather than vendored, so only the source list is versioned
(`claude/skills-sources.txt`, generated from the lockfile). Commands come from
separate repos under `~/code` that get cloned and symlinked:

```bash
./scripts/restore-claude-skills.sh
```
