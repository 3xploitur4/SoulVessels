# Installs the free helper AI CLIs for Soul Vessels. Nothing here is paid.
# Run by double-clicking install-helpers.bat (or: powershell -ExecutionPolicy Bypass -File install-helpers.ps1)
$ErrorActionPreference = 'Continue'
Write-Host "=== Soul Vessels helper AI tools installer ===" -ForegroundColor Cyan

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
  Write-Host "Node.js/npm not found. Install Node LTS from https://nodejs.org (free) and run this again." -ForegroundColor Red
  Read-Host "Press Enter to close"; exit 1
}

Write-Host "`n[1/4] OpenCode (free models, no account needed)" -ForegroundColor Yellow
npm install -g --allow-scripts=opencode-ai opencode-ai@latest

Write-Host "`n[2/4] Codex CLI (sign in with a FREE ChatGPT account)" -ForegroundColor Yellow
npm install -g --allow-scripts=@openai/codex @openai/codex@latest

Write-Host "`n[3/4] GitHub Copilot CLI (sign in with a FREE GitHub account)" -ForegroundColor Yellow
npm install -g --allow-scripts=@github/copilot @github/copilot@latest

Write-Host "`n[4/4] Antigravity CLI 'agy' (official Google installer, FREE Google account)" -ForegroundColor Yellow
try { Invoke-RestMethod https://antigravity.google/cli/install.ps1 | Invoke-Expression } catch { Write-Host "Antigravity install failed: $_" -ForegroundColor Red }

Write-Host "`n=== Check ===" -ForegroundColor Cyan
foreach ($c in 'opencode','codex','copilot','agy') {
  $p = Get-Command $c -ErrorAction SilentlyContinue
  if ($p) { Write-Host ("OK      " + $c + "  ->  " + $p.Source) -ForegroundColor Green }
  else    { Write-Host ("MISSING " + $c + "  (close and reopen the terminal; agy may need a new window for PATH)") -ForegroundColor Red }
}
Write-Host @"

NEXT: sign in once to each tool (opens your browser). NEVER pick a paid plan or enter a card.
  opencode      -> type /models, pick one marked Free, Ctrl+C to quit (no sign-in needed)
  codex         -> 'Sign in with ChatGPT' (free account)
  copilot       -> type /login, use your GitHub account (Free plan)
  agy           -> 'Google OAuth', personal Google account
"@
Read-Host "Press Enter to close"
