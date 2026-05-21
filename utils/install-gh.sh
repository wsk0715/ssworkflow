#!/bin/bash

# Install GitHub CLI using Homebrew (macOS)
echo "📥 Installing GitHub CLI via Homebrew..."
if command -v brew &> /dev/null; then
  brew install gh
else
  echo "❌ Error: Homebrew (brew) not found. Please install Homebrew or install gh manually from https://cli.github.com/"
  exit 1
fi

# Refresh PATH for the current session
if ! command -v gh &> /dev/null; then
  export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
fi

# Verify installation
if command -v gh &> /dev/null; then
  echo "✅ GitHub CLI (gh) installed and loaded successfully in this session!"
  echo "👉 Please run 'gh auth login' to authenticate."
else
  echo "❌ Installation complete, but 'gh' is not in PATH. Please restart your terminal."
fi
