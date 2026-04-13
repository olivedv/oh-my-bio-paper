#!/usr/bin/env bash
# version-guardian: Install Git hooks for the bio-paper project.
#
# Installs:
#   1. pre-push hook — blocks all pushes (local-only repo)
#   2. Registers PostToolUse hooks in .claude/settings.json for auto-commit
#
# Usage:
#   ./install-hooks.sh [--project-root <path>]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"

log() {
  echo "[version-guardian] $*"
}

# --- 1. Install pre-push hook ---

install_pre_push() {
  local hooks_dir="$PROJECT_ROOT/.git/hooks"

  if [ ! -d "$PROJECT_ROOT/.git" ]; then
    log "ERROR: Not a git repository: $PROJECT_ROOT"
    exit 1
  fi

  mkdir -p "$hooks_dir"

  cat > "$hooks_dir/pre-push" << 'HOOK'
#!/bin/bash
# Oh My Bio-Paper: Block all push operations.
# This repository is LOCAL-ONLY to protect unpublished data.
echo "================================================"
echo "ERROR: This repository is LOCAL-ONLY."
echo "Pushing to any remote is blocked by pre-push hook."
echo "If you really need to back up, use rsync to an"
echo "encrypted external drive or a private NAS."
echo "================================================"
exit 1
HOOK

  chmod +x "$hooks_dir/pre-push"
  log "Installed pre-push hook (blocks all pushes)"
}

# --- 2. Safety checks ---

run_safety_checks() {
  cd "$PROJECT_ROOT"

  # Check .gitignore exists
  if [ ! -f ".gitignore" ]; then
    log "WARNING: .gitignore not found! Run /omp:setup to generate it."
  fi

  # Check for remotes
  local remotes
  remotes="$(git remote -v 2>/dev/null || true)"
  if [ -n "$remotes" ]; then
    log "WARNING: Remote repositories detected!"
    log "This repo should be LOCAL-ONLY. Remotes found:"
    echo "$remotes" | while read -r line; do
      log "  $line"
    done
    log "Consider removing with: git remote remove <name>"
  fi

  # Check for accidentally tracked binary files
  local tracked_binaries
  tracked_binaries="$(git ls-files '*.tiff' '*.tif' '*.xlsx' '*.csv' '*.psd' '*.ai' 2>/dev/null || true)"
  if [ -n "$tracked_binaries" ]; then
    log "WARNING: Binary files are being tracked by Git!"
    echo "$tracked_binaries" | while read -r f; do
      log "  $f"
    done
    log "Remove with: git rm --cached <file>"
  fi

  log "Safety checks complete."
}

# --- Main ---

log "Installing hooks in: $PROJECT_ROOT"

install_pre_push
run_safety_checks

log "Done."
