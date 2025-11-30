# =====================================
# Git History Cleanup Script
# =====================================
# This script removes the exposed firebase_options.dart from Git history
# ⚠️ WARNING: This rewrites Git history! Coordinate with your team!

Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "🔐 Git History Cleanup for Exposed Keys" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Safety check
Write-Host "⚠️  WARNING: This will rewrite Git history!" -ForegroundColor Red
Write-Host "   - All collaborators will need to re-clone the repository" -ForegroundColor Yellow
Write-Host "   - This operation cannot be undone easily" -ForegroundColor Yellow
Write-Host ""
$confirm = Read-Host "Type 'YES' to continue"

if ($confirm -ne "YES") {
    Write-Host "❌ Operation cancelled" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 1: Creating backup..." -ForegroundColor Green
$backupDir = "connected-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item -Path "." -Destination "../$backupDir" -Recurse -Force
Write-Host "✅ Backup created at: ../$backupDir" -ForegroundColor Green

Write-Host ""
Write-Host "Step 2: Checking for git filter-repo..." -ForegroundColor Green
$filterRepo = Get-Command git-filter-repo -ErrorAction SilentlyContinue

if ($null -eq $filterRepo) {
    Write-Host "⚠️  git-filter-repo not found. Using git filter-branch (slower)..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Step 3: Removing firebase_options.dart from history..." -ForegroundColor Green
    
    # Method 1: Using git filter-branch (slower but more compatible)
    git filter-branch --force --index-filter `
        "git rm --cached --ignore-unmatch lib/firebase_options.dart" `
        --prune-empty --tag-name-filter cat -- --all
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ File removed from history" -ForegroundColor Green
    } else {
        Write-Host "❌ Error during filter-branch" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✅ git-filter-repo found" -ForegroundColor Green
    Write-Host ""
    Write-Host "Step 3: Removing firebase_options.dart from history..." -ForegroundColor Green
    
    # Method 2: Using git filter-repo (faster)
    git filter-repo --path lib/firebase_options.dart --invert-paths --force
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ File removed from history" -ForegroundColor Green
    } else {
        Write-Host "❌ Error during filter-repo" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Step 4: Cleaning up..." -ForegroundColor Green
git reflog expire --expire=now --all
git gc --prune=now --aggressive

Write-Host ""
Write-Host "✅ History cleanup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "1. Force push to remote:" -ForegroundColor Yellow
Write-Host "   git push origin --force --all" -ForegroundColor White
Write-Host ""
Write-Host "2. Verify the file is gone from GitHub:" -ForegroundColor Yellow
Write-Host "   https://github.com/Mr-Yacin/connected/blob/068cab74b23c6d0dd1114f6f87d1db8fb4b78e9f/lib/firebase_options.dart" -ForegroundColor White
Write-Host ""
Write-Host "3. Notify team members to re-clone the repository" -ForegroundColor Yellow
Write-Host ""
Write-Host "⚠️  IMPORTANT: Regenerate your API keys BEFORE pushing!" -ForegroundColor Red
Write-Host "   See SECURITY_FIX_README.md for instructions" -ForegroundColor Red
Write-Host ""
