#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

LATEST=false
CI=false
BRANCH=develop
SKIP_BRANCH=false
SKIP_SUBMODULES=false
SKIP_BACKEND=false
SKIP_FRONTEND=false

usage() {
  cat <<'EOF'
Paydeya setup
Usage: setup.sh [options]

  --branch <name>   branch to checkout in the main repo and submodules (default: develop)
  --no-branch       keep the current branch, do not checkout anything
  --latest          update submodules to latest branches (git submodule update --remote)
  --ci              install frontend via npm ci (package-lock.json)
  --no-submodules   skip submodule init
  --no-backend      skip backend setup
  --no-frontend     skip frontend install
  -h, --help        show this help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --branch)
      BRANCH="$2"
      shift 2
      ;;
    --no-branch) SKIP_BRANCH=true; shift ;;
    --latest) LATEST=true; shift ;;
    --ci) CI=true; shift ;;
    --no-submodules) SKIP_SUBMODULES=true; shift ;;
    --no-backend) SKIP_BACKEND=true; shift ;;
    --no-frontend) SKIP_FRONTEND=true; shift ;;
    -h | --help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

echo "==> Paydeya setup"

if ! command_exists git; then
  echo "[error] git not found. Install git first."
  exit 1
fi

if [ "$SKIP_BRANCH" != true ]; then
  echo "==> Checking out branch $BRANCH"
  CURRENT_BRANCH="$(git branch --show-current 2>/dev/null || true)"
  if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
    CHECKOUT_OUT=$(git checkout "$BRANCH" 2>&1)
    if [ $? -eq 0 ]; then
      echo "[ok] main repo -> $BRANCH"
    else
      echo "[warn] cannot checkout '$BRANCH' in the main repo: ${CHECKOUT_OUT%%$'\n'*}"
    fi
  else
    echo "[ok] already on $BRANCH"
  fi
else
  echo "==> Skipping branch checkout (--no-branch)"
fi

if [ "$SKIP_SUBMODULES" != true ]; then
  echo "==> Checking GitHub SSH access"
  SSH_OUT="$(ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 || true)"
  if printf '%s' "$SSH_OUT" | grep -q "successfully authenticated"; then
    echo "[ok] GitHub SSH access"
  else
    echo "[warn] cannot verify GitHub SSH access (git@github.com). Check your SSH key."
  fi

  echo "==> Initializing submodules"
  if [ "$LATEST" = true ]; then
    git submodule update --init --recursive --remote
  else
    git submodule update --init --recursive
  fi
  echo "[ok] submodules initialized"

  for sub in $(git config --file .gitmodules --get-regexp '^submodule\..*\.path$' 2>/dev/null | awk '{print $2}' || true); do
    if [ "$SKIP_BRANCH" = true ]; then
      echo "[ok] $sub kept on current branch (--no-branch)"
      continue
    fi
    if SUB_OUT=$(git -C "$sub" checkout "$BRANCH" 2>&1); then
      echo "[ok] $sub -> $BRANCH"
    else
      echo "[warn] cannot checkout '$BRANCH' in $sub: ${SUB_OUT%%$'\n'*}"
    fi
  done
else
  echo "==> Skipping submodules (--no-submodules)"
fi

if [ "$SKIP_BACKEND" != true ]; then
  echo "==> Backend"
  if [ -f backend/.env.example ]; then
    if [ ! -f backend/.env.dev ]; then
      cp backend/.env.example backend/.env.dev
      echo "[ok] created backend/.env.dev from example"
    else
      echo "[ok] backend/.env.dev already exists"
    fi
  else
    echo "[warn] backend/.env.example not found"
  fi

  if command_exists uv; then
    echo "==> Installing backend deps (uv sync)"
    (cd backend && uv sync)
  else
    echo "[warn] uv not found - skip backend deps. Use Docker: cd backend && make dev"
  fi
else
  echo "==> Skipping backend (--no-backend)"
fi

if [ "$SKIP_FRONTEND" != true ]; then
  echo "==> Frontend"
  if command_exists npm; then
    echo "==> Installing frontend deps (npm)"
    if [ "$CI" = true ]; then
      (cd frontend && npm ci)
    else
      (cd frontend && npm install)
    fi
  else
    echo "[warn] npm not found - skip frontend deps. Install Node.js 20+."
  fi
else
  echo "==> Skipping frontend (--no-frontend)"
fi

echo
echo "Done. Next steps:"
echo "  Backend (Docker):  cd backend && make dev              -> http://localhost:7812"
echo "  Backend (local):   cd backend && uv run uvicorn app.main:app --host 0.0.0.0 --port 7812 --reload"
echo "  Frontend:          cd frontend && npm run dev          -> http://localhost:3000"