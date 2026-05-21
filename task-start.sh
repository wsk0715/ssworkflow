#!/bin/bash

# ==========================================
#        🚀 GitHub Task Starter 🚀
# ==========================================

# --- Section 1: Environment Verification ---
echo ""
echo -e "\033[36m==========================================\033[0m"
echo -e "\033[36m        🚀 GitHub Task Starter 🚀         \033[0m"
echo -e "\033[36m==========================================\033[0m"
echo ""
echo -e "\033[34m[1/3] Verifying environment & requirements...\033[0m"

# 1. Add common macOS Homebrew paths to session PATH if not already present
if ! command -v gh &> /dev/null; then
  export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
fi

# 2. Check if gh CLI is available
if ! command -v gh &> /dev/null; then
  echo "⚠️ GitHub CLI (gh) was not found."
  read -p "❓ Would you like to run installation script to install it now? [Y/n] " INSTALL_CHOICE
  if [[ "$INSTALL_CHOICE" =~ ^[Yy]$ || -z "$INSTALL_CHOICE" ]]; then
    source ./utils/install-gh.sh
    if ! command -v gh &> /dev/null; then
      echo "❌ Error: GitHub CLI is still not found. Please restart your terminal."
      exit 1
    fi
  else
    exit 1
  fi
fi

# 3. Check GitHub CLI Authentication
if ! gh auth status -h github.com &>/dev/null; then
  echo "⚠️ You are not logged into GitHub CLI."
  read -p "❓ Would you like to run 'gh auth login' now? [Y/n] " LOGIN_CHOICE
  if [[ "$LOGIN_CHOICE" =~ ^[Yy]$ || -z "$LOGIN_CHOICE" ]]; then
    gh auth login
    if ! gh auth status -h github.com &>/dev/null; then
      echo "❌ Error: Authentication failed. Please log in manually using 'gh auth login'."
      exit 1
    fi
  else
    exit 1
  fi
fi

# 4. Get and verify access to the GitHub repository
GIT_REMOTE=$(git remote get-url origin 2>/dev/null | tr -d '\r')
if [ $? -ne 0 ] || [ -z "$GIT_REMOTE" ]; then
  echo "❌ Error: Could not retrieve the remote URL for 'origin'."
  exit 1
fi

if [[ $GIT_REMOTE =~ github\.com[:/]([^/]+/[^/.]+?)(\.git)?$ ]]; then
  REPO_NAME="${BASH_REMATCH[1]}"
else
  echo "❌ Error: Could not parse the GitHub repository name from remote URL '$GIT_REMOTE'."
  exit 1
fi

if ! gh repo view "$REPO_NAME" &>/dev/null; then
  echo "❌ Error: You do not have access to the repository '$REPO_NAME' or it does not exist."
  echo "👉 Please make sure you have the correct permissions."
  exit 1
fi

echo -e "\033[32m✅ Environment, authentication, and repository access verified!\033[0m"

# --- Section 2: Task Configuration ---
echo ""
echo -e "\033[34m[2/3] Configure new task settings\033[0m"
echo -e "\033[90m------------------------------------------\033[0m"

read -p "  📌 Enter Task ID (e.g., 6): " TASK_ID
if [ -z "$TASK_ID" ]; then
  echo "❌ Error: Task ID is required."
  exit 1
fi

read -p "  📝 Enter Pull Request Title (Optional): " TASK_TITLE

TASK_PREFIX="TASK"
BRANCH_NAME="task/$TASK_ID"
BASE_BRANCH="dev"

if [ -z "$TASK_TITLE" ]; then
  PR_TITLE="[$TASK_PREFIX-$TASK_ID]"
else
  PR_TITLE="[$TASK_PREFIX-$TASK_ID] $TASK_TITLE"
fi

# --- Section 3: Execution ---
echo ""
echo -e "\033[34m[3/3] Executing Git & GitHub automation...\033[0m"
echo -e "\033[90m------------------------------------------\033[0m"

# 1. Fetch from remote repository
echo -e "  📥 Fetching from origin..."
git fetch origin || { echo "❌ Error: Git fetch failed."; exit 1; }

# 2. Check if origin/dev exists
if ! git branch -r | grep -q "origin/$BASE_BRANCH"; then
  echo "❌ Error: The base branch 'origin/dev' does not exist."
  echo "👉 Please create the 'dev' branch on origin first before running this script."
  exit 1
fi

# 3. Create and checkout new branch from origin/$BASE_BRANCH
echo -e "  🌿 Creating branch '$BRANCH_NAME' from 'origin/$BASE_BRANCH'..."
git checkout -b $BRANCH_NAME origin/$BASE_BRANCH || { echo "❌ Error: Failed to create or checkout branch '$BRANCH_NAME'."; exit 1; }

# 4. Create initial empty commit
echo -e "  💾 Creating initial empty commit..."
git commit --allow-empty -m "chore: start task-$TASK_ID" || { echo "❌ Error: Failed to create initial empty commit."; exit 1; }

# 5. Push to remote and set upstream
echo -e "  📤 Pushing branch to origin..."
git push -u origin $BRANCH_NAME || { echo "❌ Error: Failed to push branch '$BRANCH_NAME' to origin."; exit 1; }

# 6. Create Draft PR
echo -e "  📝 Creating Draft PR via GitHub CLI..."
TEMPLATE_PATH=".github/pull_request_template.md"
if [ -f "$TEMPLATE_PATH" ]; then
  gh pr create --draft --title "$PR_TITLE" --body-file "$TEMPLATE_PATH" --base $BASE_BRANCH --assignee "@me"
else
  gh pr create --draft --title "$PR_TITLE" --body "" --base $BASE_BRANCH --assignee "@me"
fi

if [ $? -ne 0 ]; then
  echo "❌ Error: Failed to create Draft PR."
  exit 1
fi

echo ""
echo -e "\033[32m==========================================\033[0m"
echo -e "\033[32m  🎉 Draft PR created successfully!        \033[0m"
echo -e "\033[32m==========================================\033[0m"
echo ""

gh pr view --web
