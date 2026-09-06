[CmdletBinding()]
param(
    [string]$Branch = 'develop',
    [switch]$NoBranch,
    [switch]$Latest,
    [switch]$Ci,
    [switch]$NoSubmodules,
    [switch]$NoBackend,
    [switch]$NoFrontend,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

function Show-Usage {
    Write-Host @'
Paydeya setup
Usage: setup.ps1 [options]

  -Branch <name>    branch to checkout in the main repo and submodules (default: develop)
  -NoBranch         keep the current branch, do not checkout anything
  -Latest           update submodules to latest branches (--remote)
  -Ci               install frontend via npm ci (package-lock.json)
  -NoSubmodules     skip submodule init
  -NoBackend        skip backend setup
  -NoFrontend       skip frontend install
  -Help             show this help
'@
}

if ($Help) {
    Show-Usage
    exit 0
}

function Get-CommandExists {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $RootDir

Write-Host '==> Paydeya setup'

if (-not (Get-CommandExists 'git')) {
    Write-Host '[error] git not found. Install git first.'
    exit 1
}

if ($NoBranch) {
    Write-Host '==> Skipping branch checkout (-NoBranch)'
}
else {
    Write-Host "==> Checking out branch $Branch"
    $currentBranch = (git branch --show-current 2>$null | Out-String).Trim()
    if ($currentBranch -ne $Branch) {
        git checkout $Branch 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[ok] main repo -> $Branch"
        }
        else {
            $currentBranch = if ($null -eq $currentBranch -or $currentBranch -eq '') { 'detached HEAD' } else { $currentBranch }
            Write-Host "[warn] branch '$Branch' not found in the main repo, staying on '$currentBranch'"
        }
    }
    else {
        Write-Host "[ok] already on $Branch"
    }
}

if (-not $NoSubmodules) {
    Write-Host '==> Checking GitHub SSH access'
    $sshOut = ssh -o BatchMode=yes -o ConnectTimeout=5 -T git@github.com 2>&1 | Out-String
    if ($sshOut -match 'successfully authenticated') {
        Write-Host '[ok] GitHub SSH access'
    }
    else {
        Write-Host '[warn] cannot verify GitHub SSH access (git@github.com). Check your SSH key.'
    }

    Write-Host '==> Initializing submodules'
    if ($Latest) {
        git submodule update --init --recursive --remote
    }
    else {
        git submodule update --init --recursive
    }
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Host '[ok] submodules initialized'

    if ($Branch -and -not $NoBranch) {
        $subPaths = git config --file .gitmodules --get-regexp '^submodule\..*\.path$' 2>$null |
            ForEach-Object { ($_ -split ' ', 2)[1] }
        foreach ($sub in $subPaths) {
            if (-not $sub) { continue }
            Push-Location $sub
            try {
                git checkout $Branch 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[ok] $sub -> $Branch"
                }
                else {
                    Write-Host "[warn] branch '$Branch' not found in $sub, keeping pinned commit"
                }
            }
            finally {
                Pop-Location
            }
        }
    }
    elseif ($NoBranch) {
        Write-Host '[ok] submodules kept on current branch (-NoBranch)'
    }
}
else {
    Write-Host '==> Skipping submodules (-NoSubmodules)'
}

if (-not $NoBackend) {
    Write-Host '==> Backend'
    $envExample = Join-Path $RootDir 'backend\.env.example'
    $envDev = Join-Path $RootDir 'backend\.env.dev'
    if (Test-Path $envExample) {
        if (-not (Test-Path $envDev)) {
            Copy-Item $envExample $envDev
            Write-Host '[ok] created backend/.env.dev from example'
        }
        else {
            Write-Host '[ok] backend/.env.dev already exists'
        }
    }
    else {
        Write-Host '[warn] backend/.env.example not found'
    }

    if (Get-CommandExists 'uv') {
        Write-Host '==> Installing backend deps (uv sync)'
        Push-Location (Join-Path $RootDir 'backend')
        try {
            uv sync
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        }
        finally {
            Pop-Location
        }
    }
    else {
        Write-Host '[warn] uv not found - skip backend deps. Use Docker: cd backend; make dev'
    }
}
else {
    Write-Host '==> Skipping backend (-NoBackend)'
}

if (-not $NoFrontend) {
    Write-Host '==> Frontend'
    if (Get-CommandExists 'npm') {
        Write-Host '==> Installing frontend deps (npm)'
        Push-Location (Join-Path $RootDir 'frontend')
        try {
            if ($Ci) {
                npm ci
            }
            else {
                npm install
            }
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        }
        finally {
            Pop-Location
        }
    }
    else {
        Write-Host '[warn] npm not found - skip frontend deps. Install Node.js 20+.'
    }
}
else {
    Write-Host '==> Skipping frontend (-NoFrontend)'
}

Write-Host
Write-Host 'Done. Next steps:'
Write-Host '  Backend (Docker):  cd backend; make dev           -> http://localhost:7812'
Write-Host '  Backend (local):   cd backend; uv run uvicorn app.main:app --host 0.0.0.0 --port 7812 --reload'
Write-Host '  Frontend:          cd frontend; npm run dev       -> http://localhost:3000'