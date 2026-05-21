# Install GitHub CLI (using --force to repair corrupted/half-installed states)
Write-Host "📥 Installing/Repairing GitHub CLI..." -ForegroundColor Yellow
Start-Process winget -ArgumentList "install --id GitHub.cli --source winget --force" -NoNewWindow -Wait

# Refresh PATH in the current session
$MachinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$UserPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = "$MachinePath;$UserPath"

# Apply fallback paths
$DefaultPaths = @(
    "C:\Program Files\GitHub CLI"
    "$env:LOCALAPPDATA\Microsoft\WinGet\Links"
)
foreach ($Path in $DefaultPaths) {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue) -and (Test-Path "$Path\gh.exe")) {
        $env:Path += ";$Path"
    }
}

# Verify installation
if (Get-Command gh -ErrorAction SilentlyContinue) {
    Write-Host "✅ GitHub CLI (gh) installed and loaded successfully in this session!" -ForegroundColor Green
    Write-Host "👉 Please run 'gh auth login' to authenticate." -ForegroundColor Cyan
} else {
    Write-Error "❌ gh could not be loaded. Please restart your terminal."
}
