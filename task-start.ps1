# ==========================================
#        🚀 GitHub Task Starter 🚀
# ==========================================

# --- Section 1: Environment Verification ---
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "        🚀 GitHub Task Starter 🚀         " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[1/3] Verifying environment & requirements..." -ForegroundColor Blue

# 1. Refresh PATH from registry to immediately detect newly installed tools (like gh CLI)
$MachinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$UserPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = "$MachinePath;$UserPath"

# 2. Add common absolute install directories as fallbacks
$DefaultPaths = @(
    "C:\Program Files\GitHub CLI"
    "$env:LOCALAPPDATA\Microsoft\WinGet\Links"
)
foreach ($Path in $DefaultPaths) {
    if (Test-Path "$Path\gh.exe") {
        $env:Path += ";$Path"
    }
}

# 3. Check if gh CLI is available
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Warning "⚠️ GitHub CLI (gh) was not found."
    $response = Read-Host "❓ Would you like to run installation script to install it now? [Y/n]"
    if ($response -eq 'y' -or $response -eq 'Y' -or [string]::IsNullOrWhiteSpace($response)) {
        . .\utils\install-gh.ps1
        if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
            Write-Error "❌ Error: GitHub CLI is still not found. Please restart your terminal."
            exit 1
        }
    } else {
        exit 1
    }
}

# 4. Check GitHub CLI Authentication
& gh auth status -h github.com > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Warning "⚠️ You are not logged into GitHub CLI."
    $response = Read-Host "❓ Would you like to run 'gh auth login' now? [Y/n]"
    if ($response -eq 'y' -or $response -eq 'Y' -or [string]::IsNullOrWhiteSpace($response)) {
        gh auth login
        & gh auth status -h github.com > $null 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "❌ Error: Authentication failed. Please log in manually using 'gh auth login'."
            exit 1
        }
    } else {
        exit 1
    }
}

# 5. Get and verify access to the GitHub repository
$GitRemote = (git remote get-url origin 2>$null)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($GitRemote)) {
    Write-Error "❌ Error: Could not retrieve the remote URL for 'origin'."
    exit 1
}

$GitRemote = $GitRemote.Trim()
if ($GitRemote -match 'github\.com[:/]([^/]+/[^/.]+?)(?:\.git)?$') {
    $RepoName = $Matches[1]
} else {
    Write-Error "❌ Error: Could not parse the GitHub repository name from remote URL '$GitRemote'."
    exit 1
}

& gh repo view $RepoName > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Error: You do not have access to the repository '$RepoName' or it does not exist."
    Write-Host "👉 Please make sure you have the correct permissions." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Environment, authentication, and repository access verified!" -ForegroundColor Green

# --- Section 2: Task Configuration ---
Write-Host ""
Write-Host "[2/3] Configure new task settings" -ForegroundColor Blue
Write-Host "------------------------------------------" -ForegroundColor DarkGray

$TaskId = Read-Host "  📌 Enter Task ID (e.g., 6)"
if ([string]::IsNullOrWhiteSpace($TaskId)) {
    Write-Error "❌ Error: Task ID is required."
    exit 1
}

$TaskTitle = Read-Host "  📝 Enter Pull Request Title (Optional)"
if ([string]::IsNullOrWhiteSpace($TaskTitle)) {
    $TaskTitle = ""
}

$TaskPrefix = "TASK"
$BranchName = "task/$TaskId"
$BaseBranch = "dev"

if ([string]::IsNullOrEmpty($TaskTitle)) {
    $PrTitle = "[$TaskPrefix-$TaskId]"
} else {
    $PrTitle = "[$TaskPrefix-$TaskId] $TaskTitle"
}

# --- Section 3: Execution ---
Write-Host ""
Write-Host "[3/3] Executing Git & GitHub automation..." -ForegroundColor Blue
Write-Host "------------------------------------------" -ForegroundColor DarkGray

# 1. Fetch from remote repository
Write-Host "  📥 Fetching from origin..." -ForegroundColor Yellow
git fetch origin
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Error: Git fetch failed."
    exit 1
}

# 2. Check if origin/dev exists
$HasDev = git branch -r | Select-String "origin/$BaseBranch"
if (-not $HasDev) {
    Write-Error "❌ Error: The base branch 'origin/dev' does not exist."
    Write-Host "👉 Please create the 'dev' branch on origin first before running this script." -ForegroundColor Red
    exit 1
}

# 3. Create and checkout new branch from origin/dev
Write-Host "  🌿 Creating branch '$BranchName' from 'origin/$BaseBranch'..." -ForegroundColor Yellow
git checkout -b $BranchName origin/$BaseBranch
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Error: Failed to create or checkout branch '$BranchName'."
    exit 1
}

# 4. Create initial empty commit
Write-Host "  💾 Creating initial empty commit..." -ForegroundColor Yellow
git commit --allow-empty -m "chore: start task-$TaskId"
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Error: Failed to create initial empty commit."
    exit 1
}

# 5. Push to remote and set upstream
Write-Host "  📤 Pushing branch to origin..." -ForegroundColor Yellow
git push -u origin $BranchName
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Error: Failed to push branch '$BranchName' to origin."
    exit 1
}

# 6. Create Draft PR
Write-Host "  📝 Creating Draft PR via GitHub CLI..." -ForegroundColor Yellow
$TemplatePath = ".github/pull_request_template.md"
if (Test-Path $TemplatePath) {
    gh pr create --draft --title $PrTitle --body-file $TemplatePath --base $BaseBranch --assignee "@me"
} else {
    gh pr create --draft --title $PrTitle --body "" --base $BaseBranch --assignee "@me"
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Error: Failed to create Draft PR."
    exit 1
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  🎉 Draft PR created successfully!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

gh pr view --web
