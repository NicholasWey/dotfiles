#!/bin/bash
# Bootstrap Neovim config on a remote Linux/Mac machine.
# Usage: curl -fsSL https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/dotfiles/main/bootstrap.sh | bash
#
# NOTE: curl | bash executes whatever the server returns. Only run this
# from a trusted source. A truncated download may leave the system in a
# partial state; re-run the script to recover.
set -e

GITHUB_USERNAME="YOUR_GITHUB_USERNAME"
NVIM_CONFIG_DIR="$HOME/.config/nvim"

echo "==> Installing Neovim..."
if command -v apt-get &>/dev/null; then
  # NOTE: apt-get on Ubuntu 20.04/22.04 may install an older Neovim (< 0.8).
  # For a newer version, use: sudo snap install nvim --classic
  sudo apt-get update -qq
  sudo apt-get install -y neovim
elif command -v brew &>/dev/null; then
  brew install neovim
elif command -v dnf &>/dev/null; then
  sudo dnf install -y neovim
else
  echo "ERROR: Could not detect package manager. Install Neovim manually."
  exit 1
fi

echo "==> Checking dependencies..."
if ! command -v git &>/dev/null; then
  echo "ERROR: git is not installed. Install it and re-run."
  exit 1
fi

echo "==> Cloning dotfiles..."
mkdir -p "$HOME/.config"

if [ -d "$NVIM_CONFIG_DIR" ]; then
  if [ -d "${NVIM_CONFIG_DIR}.bak" ]; then
    echo "ERROR: Backup directory ${NVIM_CONFIG_DIR}.bak already exists."
    echo "Remove it manually, then re-run."
    exit 1
  fi
  echo "  Existing config found at $NVIM_CONFIG_DIR -- backing up to ${NVIM_CONFIG_DIR}.bak"
  mv "$NVIM_CONFIG_DIR" "${NVIM_CONFIG_DIR}.bak"
fi

git clone "https://github.com/${GITHUB_USERNAME}/dotfiles.git" "$NVIM_CONFIG_DIR"

echo ""
echo "==> Neovim version installed:"
nvim --version | head -1

echo ""
echo "Done! Run 'nvim' to complete plugin installation."
echo "Plugins will auto-install on first launch."
