#!/usr/bin/env bash
#
# Bootstrap this machine from the dotfiles repo:
#   1. install / update all tools via Homebrew (Brewfile)
#   2. symlink config files into place via GNU stow
#
# Idempotent: safe to re-run. Stow uses --restow so existing links are refreshed.
set -euo pipefail
cd "$(dirname "$0")"

# --- 1. Tools (latest versions) via Homebrew ---------------------------------
if command -v brew >/dev/null 2>&1; then
  echo "==> brew bundle (install/update tools)"
  brew bundle --file=Brewfile
else
  echo "!! Homebrew not found. Install it first: https://brew.sh" >&2
  exit 1
fi

# --- 2. Config files via GNU stow --------------------------------------------
# Packages mirror their real $HOME-relative path (see .stowrc: --target=~).
# Only actively-used configs are linked. GUI/daemon configs are kept in the
# repo but intentionally NOT linked here (ghostty, karabiner, aerospace,
# sketchybar, skhd, wezterm, zellij, hammerspoon, nix, nix-darwin, kindavim) —
# add them to STOW_PKGS once their layout is migrated to the nested form.
# atuin is excluded on purpose (see .stowrc --ignore).
STOW_PKGS=(nushell nvim tmux starship zshrc ssh)

if ! command -v stow >/dev/null 2>&1; then
  echo "!! GNU stow not found (should come from Brewfile)." >&2
  exit 1
fi

echo "==> stow ${STOW_PKGS[*]}"
for pkg in "${STOW_PKGS[@]}"; do
  stow --restow "$pkg"
done

echo "==> Done. Restart your shell."
