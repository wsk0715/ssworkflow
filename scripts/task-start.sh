#!/bin/bash

# ==========================================
#        *** GitHub Task Starter ***
# ==========================================

# --- Section 1: Environment Verification ---
echo ""
echo -e "\033[36m==========================================\033[0m"
echo -e "\033[36m        *** GitHub Task Starter ***       \033[0m"
echo -e "\033[36m==========================================\033[0m"
echo ""
echo -e "\033[34m[1/3] Verifying environment & requirements...\033[0m"

# 1. Add common macOS Homebrew paths to session PATH if not already present
if ! command -v gh &> /dev/null; then
  export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
fi

# 2. Check if gh CLI is available
if ! command -v gh &> /dev/null; then
  echo "[WARN] GitHub CLI (gh) was not found."
  read -p "  [?] Would you like to run installation script to install it now? [Y/n] " INSTALL_CHOICE
  if [[ "$INSTALL_CHOICE" =~ ^[Yy]$ || -z "$INSTALL_CHOICE" ]]; then
    source ./install-gh.sh
    if ! command -v gh &> /dev/null; then
      echo "[ERROR] GitHub CLI is still not found. Please restart your terminal."
      exit 1
    fi
  else
    exit 1
  fi
fi

# 3. Check GitHub CLI Authentication
if ! gh auth status -h github.com &>/dev/null; then
  echo "[WARN] You are not logged into GitHub CLI."
  read -p "  [?] Would you like to run 'gh auth login' now? [Y/n] " LOGIN_CHOICE
  if [[ "$LOGIN_CHOICE" =~ ^[Yy]$ || -z "$LOGIN_CHOICE" ]]; then
    gh auth login
    if ! gh auth status -h github.com &>/dev/null; then
      echo "[ERROR] Authentication failed. Please log in manually using 'gh auth login'."
      exit 1
    fi
  else
    exit 1
  fi
fi

# 4. Get and verify access to the GitHub repository
GIT_REMOTE=$(git remote get-url origin 2>/dev/null | tr -d '\r')
if [ $? -ne 0 ] || [ -z "$GIT_REMOTE" ]; then
  echo "[ERROR] Could not retrieve the remote URL for 'origin'."
  exit 1
fi

if [[ $GIT_REMOTE =~ github\.com[:/]([^/]+/[^/.]+?)(\.git)?$ ]]; then
  REPO_NAME="${BASH_REMATCH[1]}"
else
  echo "[ERROR] Could not parse the GitHub repository name from remote URL '$GIT_REMOTE'."
  exit 1
fi

if ! gh repo view "$REPO_NAME" &>/dev/null; then
  echo "[ERROR] You do not have access to the repository '$REPO_NAME' or it does not exist."
  echo "  [!] Please make sure you have the correct permissions."
  exit 1
fi

echo -e "\033[32m[OK] Environment, authentication, and repository access verified!\033[0m"

# --- Section 2: Task Configuration ---
echo ""
echo -e "\033[34m[2/3] Configure new task settings\033[0m"
echo -e "\033[90m------------------------------------------\033[0m"

read -p "  * Enter Task ID (e.g., 6): " TASK_ID
if [ -z "$TASK_ID" ]; then
  echo "[ERROR] Task ID is required."
  exit 1
fi

read -p "  * Enter Pull Request Title (Optional): " TASK_TITLE

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

# 1. Fetch from remote repository & Prune remote-tracking branches
echo -e "  [+] Fetching from origin and pruning deleted branches..."
git fetch origin --prune || { echo "[ERROR] Git fetch failed."; exit 1; }

# Clean up local branches whose tracking branches are gone (already merged and deleted on remote)
GONE_BRANCHES=$(git branch -vv | grep ': gone]' | awk '{print $1}' | tr -d '*' | xargs)
if [ -n "$GONE_BRANCHES" ]; then
  echo -e "  [+] Cleaning up merged local branches..."
  for b in $GONE_BRANCHES; do
    if [ "$b" != "dev" ] && [ "$b" != "main" ]; then
      git branch -d "$b" &>/dev/null
    fi
  done
fi

# 1.5. Check if branch or PR already exists to prevent duplicate tasks
echo -e "  [+] Checking for existing branches or PRs for Task $TASK_ID..."

DUPLICATE_DETECTED=0
DUPLICATE_ITEMS=()

# Check Local branches
LOCAL_BRANCH_EXISTS=$(git branch --list "$BRANCH_NAME" "$BRANCH_NAME-*" | tr -d ' *' | xargs)
if [ -n "$LOCAL_BRANCH_EXISTS" ]; then
  DUPLICATE_DETECTED=1
  for b in $LOCAL_BRANCH_EXISTS; do
    DUPLICATE_ITEMS+=("    [Local Branch] $b")
  done
fi

# Check Remote branches
REMOTE_BRANCH_EXISTS=$(git branch -r --list "origin/$BRANCH_NAME" "origin/$BRANCH_NAME-*" | tr -d ' ' | xargs)
if [ -n "$REMOTE_BRANCH_EXISTS" ]; then
  DUPLICATE_DETECTED=1
  for b in $REMOTE_BRANCH_EXISTS; do
    DUPLICATE_ITEMS+=("    [Remote Branch] $b")
  done
fi

# Check GitHub PRs using gh CLI
if command -v jq &>/dev/null; then
  PRS_JSON=$(gh pr list --state all --limit 100 --json headRefName,title,state,url 2>/dev/null)
  if [ $? -eq 0 ] && [ -n "$PRS_JSON" ]; then
    MATCHED_PRS=$(echo "$PRS_JSON" | jq -c --arg id "$TASK_ID" --arg prefix "$TASK_PREFIX" '
      .[] | select((.headRefName | test("^task/" + $id + "(-|$)")) or (.title | test("^\\[" + $prefix + "-" + $id + "\\]")))
    ' 2>/dev/null)
    
    if [ -n "$MATCHED_PRS" ]; then
      DUPLICATE_DETECTED=1
      while read -r pr; do
        if [ -n "$pr" ]; then
          PR_TITLE_VAL=$(echo "$pr" | jq -r '.title')
          PR_STATE_VAL=$(echo "$pr" | jq -r '.state')
          PR_URL_VAL=$(echo "$pr" | jq -r '.url')
          DUPLICATE_ITEMS+=("    [GitHub PR] $PR_TITLE_VAL (State: $PR_STATE_VAL) - $PR_URL_VAL")
        fi
      done <<< "$MATCHED_PRS"
    fi
  fi
else
  PRS_TEXT=$(gh pr list --state all --limit 100 --json headRefName,title,state,url --template '{{range .}}{{.headRefName}}	{{.title}}	{{.state}}	{{.url}}{{"\n"}}{{end}}' 2>/dev/null)
  if [ $? -eq 0 ] && [ -n "$PRS_TEXT" ]; then
    while read -r line; do
      if [ -n "$line" ]; then
        IFS=$'\t' read -r ref title state url <<< "$line"
        IS_MATCH=0
        if [[ "$ref" =~ ^task/$TASK_ID(-|$) ]]; then
          IS_MATCH=1
        elif [[ "$title" =~ ^\[$TASK_PREFIX-$TASK_ID\] ]]; then
          IS_MATCH=1
        fi
        
        if [ $IS_MATCH -eq 1 ]; then
          DUPLICATE_DETECTED=1
          DUPLICATE_ITEMS+=("    [GitHub PR] $title (State: $state) - $url")
        fi
      fi
    done <<< "$PRS_TEXT"
  fi
fi

# Warn user if duplicates are found
if [ $DUPLICATE_DETECTED -eq 1 ]; then
  echo ""
  echo -e "\033[33m[WARN] Task ID $TASK_ID is already associated with the following resources:\033[0m"
  for item in "${DUPLICATE_ITEMS[@]}"; do
    echo -e "\033[33m$item\033[0m"
  done
  echo ""
  read -p "  [?] Do you want to proceed anyway? [y/N] " PROCEED
  if [[ ! "$PROCEED" =~ ^[Yy]$ ]]; then
    echo -e "\033[31m[ERROR] Operation aborted by user.\033[0m"
    exit 0
  fi
fi

# 2. Check if origin/dev exists
if ! git branch -r | grep -q "origin/$BASE_BRANCH"; then
  echo "[ERROR] The base branch 'origin/dev' does not exist."
  echo "  [!] Please create the 'dev' branch on origin first before running this script."
  exit 1
fi

# 3. Create and checkout new branch from origin/$BASE_BRANCH
# Clean up existing local/remote branch with the same name if they exist
if git branch --list "$BRANCH_NAME" | grep -q "$BRANCH_NAME"; then
  echo -e "  [-] Existing local branch '$BRANCH_NAME' found. Deleting..."
  CURRENT_BRANCH=$(git branch --show-current)
  if [ "$CURRENT_BRANCH" = "$BRANCH_NAME" ]; then
    git checkout $BASE_BRANCH || git checkout main || :
  fi
  git branch -D $BRANCH_NAME || { echo "[ERROR] Failed to delete local branch '$BRANCH_NAME'."; exit 1; }
fi

if git branch -r --list "origin/$BRANCH_NAME" | grep -q "origin/$BRANCH_NAME"; then
  echo -e "  [-] Existing remote branch 'origin/$BRANCH_NAME' found. Deleting..."
  git push origin --delete $BRANCH_NAME || { echo "[ERROR] Failed to delete remote branch '$BRANCH_NAME'."; exit 1; }
fi

echo -e "  [+] Creating branch '$BRANCH_NAME' from 'origin/$BASE_BRANCH'..."
git checkout -b $BRANCH_NAME origin/$BASE_BRANCH || { echo "[ERROR] Failed to create or checkout branch '$BRANCH_NAME'."; exit 1; }

# 4. Create initial empty commit
echo -e "  [+] Creating initial empty commit..."
git reset &>/dev/null
git commit --allow-empty -m "chore: start task-$TASK_ID" -m "[skip ci]" || { echo "[ERROR] Failed to create initial empty commit."; exit 1; }

# 5. Push to remote and set upstream
echo -e "  [+] Pushing branch to origin..."
git push -u origin $BRANCH_NAME || { echo "[ERROR] Failed to push branch '$BRANCH_NAME' to origin."; exit 1; }

# 6. Create Draft PR
echo -e "  [+] Creating Draft PR via GitHub CLI..."
TEMPLATE_PATH=".github/pull_request_template.md"
if [ -f "$TEMPLATE_PATH" ]; then
  gh pr create --draft --title "$PR_TITLE" --body-file "$TEMPLATE_PATH" --base "$BASE_BRANCH" --assignee "@me"
else
  gh pr create --draft --title "$PR_TITLE" --body '""' --base "$BASE_BRANCH" --assignee "@me"
fi

if [ $? -ne 0 ]; then
  echo "[ERROR] Failed to create Draft PR."
  exit 1
fi

echo ""
echo -e "\033[32m==========================================\033[0m"
echo -e "\033[32m  *** Draft PR created successfully! ***   \033[0m"
echo -e "\033[32m==========================================\033[0m"
echo ""

gh pr view --web
