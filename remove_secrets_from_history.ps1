# Script to remove Stripe secrets from Git history
# Run this script to clean your Git history

Write-Host "=== Removing Stripe Secrets from Git History ===" -ForegroundColor Yellow
Write-Host ""

# Step 1: Create a backup branch (safety first!)
Write-Host "Step 1: Creating backup branch..." -ForegroundColor Cyan
git branch backup-before-secret-removal
Write-Host "✅ Backup created: backup-before-secret-removal" -ForegroundColor Green
Write-Host ""

# Step 2: Remove the files from history using filter-branch
Write-Host "Step 2: Removing files from Git history..." -ForegroundColor Cyan
Write-Host "This may take a few minutes..." -ForegroundColor Yellow

git filter-branch --force --index-filter `
  "git rm --cached --ignore-unmatch ADD_STRIPE_SECRET.md STRIPE_SECRET_SETUP.md STRIPE_SETUP_GUIDE.md" `
  --prune-empty --tag-name-filter cat -- --all

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Files removed from history!" -ForegroundColor Green
} else {
    Write-Host "❌ Error occurred. Check the output above." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 3: Cleaning up..." -ForegroundColor Cyan
git reflog expire --expire=now --all
git gc --prune=now --aggressive

Write-Host ""
Write-Host "✅ Done! Now you can push:" -ForegroundColor Green
Write-Host "   git push origin main --force" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  WARNING: This rewrites history. Make sure all team members know!" -ForegroundColor Yellow
Write-Host "⚠️  If you're working with others, coordinate before force pushing!" -ForegroundColor Yellow


