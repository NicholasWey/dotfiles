#!/bin/bash
# Bootstrap Neovim config on a remote Linux/Mac machine.
# Usage: curl -fsSL https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/dotfiles/main/bootstrap.sh | bash
set -e

GITHUB_USERNAME="YOUR_GITHUB_USERNAME"
NVIM_CONFIG_DIR="$HOME/.config/nvim"

echo "==> Installing Neovim..."
if command -v apt-get &>/dev/null; then
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

echo "==> Cloning dotfiles..."
if [ -d "$NVIM_CONFIG_DIR" ]; then
  echo "  Existing config found at $NVIM_CONFIG_DIR — backing up to ${NVIM_CONFIG_DIR}.bak"
  mv "$NVIM_CONFIG_DIR" "${NVIM_CONFIG_DIR}.bak"
fi

git clone "https://github.com/${GITHUB_USERNAME}/dotfiles.git" "$NVIM_CONFIG_DIR"

echo ""
echo "Done! Run 'nvim' to complete plugin installation."
echo "Plugins will auto-install on first launch."
