# Installs Trip Agent on Windows, in one command, in PowerShell:
#
#   irm https://raw.githubusercontent.com/Kinetik-Infotech/trip-agent-marketplace/main/install/install.ps1 | iex
#
# It installs Claude Code's command line if it is missing, installs Python 3 with winget if it is missing, adds
# Kinetik's Trip Agent listing, installs the plugin, and makes the traveller's folder, trip-agent in the home
# folder. The folder's .claude\settings.json names the travel agent, so each Code session started on the folder opens
# with it. Run it again to carry on, or to update: each step already done says so.

$ErrorActionPreference = "Continue"
$Marketplace = "Kinetik-Infotech/trip-agent-marketplace"
$MarketplaceName = "trip-agent"
$Plugin = "trip-agent"
$Agent = "trip-agent:travel-agent"
$Folder = if ($env:TRIP_AGENT_FOLDER) { $env:TRIP_AGENT_FOLDER } else { Join-Path $HOME "trip-agent" }
$Log = Join-Path ([IO.Path]::GetTempPath()) ("trip-agent-install-" + [guid]::NewGuid().ToString("N") + ".log")
$failed = $false
function Say($what, $how) { Write-Host "${what}: $how" }
function Has($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

# Claude Code's command line, from Anthropic's own installer.
$env:Path = (Join-Path $HOME ".local\bin") + ";" + $env:Path
if (Has "claude") { Say "Claude Code" "already there" }
else {
  try { Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression *>> $Log } catch { $_ | Out-File -Append $Log }
  if (Has "claude") { Say "Claude Code" "installed" }
  else { Say "Claude Code" "failed. Run it by hand: irm https://claude.ai/install.ps1 | iex"; Write-Host "Then run this again. The log is $Log."; return }
}

# Python 3 builds the trip pages and converts prices.
$python = $null
foreach ($p in @("python", "py")) { if (Has $p) { & $p -c "import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)" 2>$null; if ($LASTEXITCODE -eq 0) { $python = $p; break } } }
if ($python) { Say "Python 3" "already there" }
elseif (Has "winget") {
  winget install --id Python.Python.3.12 -e --accept-source-agreements --accept-package-agreements *>> $Log
  Say "Python 3" "installed. Close this window, open a new PowerShell, and run this again"
  $failed = $true
}
else { Say "Python 3" "missing. Install it from python.org, then run this again"; $failed = $true }

if (-not $python) { Write-Host "Python 3 is needed before the rest. Run this again once it is installed."; return }

# Kinetik's listing, then the plugin from it. A listing called trip-agent from anywhere else, or a list that cannot
# be read, stops the install.
$raw = claude plugin marketplace list --json 2>>$Log | Out-String
if ($LASTEXITCODE -ne 0) { Say "Trip Agent listing" "could not be checked, so the install stopped. The log is $Log"; return }
try { $all = @($raw | ConvertFrom-Json) } catch { Say "Trip Agent listing" "could not be checked, so the install stopped. The log is $Log"; return }
function Slug($v) { if (-not $v) { return "" }; (("$v".Trim().ToLowerInvariant()) -replace '^(https?://|git@)github\.com[:/]', '') -replace '(\.git)?/?$', '' }
$listing = $all | Where-Object { $_.name -ceq $MarketplaceName } | Select-Object -First 1
if ($listing) {
  $ours = (-not $listing.path) -and ((Slug $listing.repo) -ceq (Slug $Marketplace) -or (Slug $listing.url) -ceq (Slug $Marketplace))
  if (-not $ours) {
    Say "Trip Agent listing" "stopped. A listing called $MarketplaceName is already there, from somewhere other than $Marketplace. Remove it with: claude plugin marketplace remove $MarketplaceName, then run this again"
    return
  }
}
if ($listing) {
  claude plugin marketplace update $MarketplaceName *>> $Log
  Say "Trip Agent listing" "already there, updated"
} else {
  claude plugin marketplace add $Marketplace *>> $Log
  if ($LASTEXITCODE -eq 0) { Say "Trip Agent listing" "added" }
  else { Say "Trip Agent listing" "failed. Run it by hand: claude plugin marketplace add $Marketplace"; Write-Host "The log is $Log."; return }
}
$installedIds = @((claude plugin list --json 2>>$Log | Out-String | ConvertFrom-Json) | ForEach-Object { $_.id })
if ($installedIds -contains "$Plugin@$MarketplaceName") {
  claude plugin update "$Plugin@$MarketplaceName" *>> $Log
  Say "Trip Agent plugin" "already there, updated"
} else {
  claude plugin install "$Plugin@$MarketplaceName" *>> $Log
  if ($LASTEXITCODE -eq 0) { Say "Trip Agent plugin" "installed" }
  else { Say "Trip Agent plugin" "failed. Run it by hand: claude plugin install $Plugin@$MarketplaceName"; Write-Host "The log is $Log."; return }
}

# The traveller's folder, with the travel agent named in its settings. Any other setting already there is kept.
$settingsDir = Join-Path $Folder ".claude"
New-Item -ItemType Directory -Force -Path $settingsDir | Out-Null
$settingsFile = Join-Path $settingsDir "settings.json"
try {
  $settings = if (Test-Path $settingsFile) { Get-Content $settingsFile -Raw | ConvertFrom-Json } else { [pscustomobject]@{} }
  $settings | Add-Member -NotePropertyName agent -NotePropertyValue $Agent -Force
  $settings | ConvertTo-Json -Depth 20 | Set-Content -Encoding UTF8 $settingsFile
  Say "Your folder" "$Folder, with the travel agent"
} catch {
  Say "Your folder" "failed. Add `"agent`": `"$Agent`" to $settingsFile by hand"
  $failed = $true
}

Write-Host ""
if ($failed) { Write-Host "Some steps need finishing. Do what they say, then run this again. The log is $Log."; return }
Write-Host "Done. In the Claude app's Code tab, start a new session on $Folder, and type: Plan me a trip"
