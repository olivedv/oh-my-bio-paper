#!/usr/bin/env bash
# version-guardian: Auto-commit with 30-second debounce and smart commit messages.
#
# Usage:
#   ./auto-commit.sh                     # Commit all staged changes now
#   ./auto-commit.sh --debounce          # Wait 30s, merge with subsequent writes
#   ./auto-commit.sh --type <type>       # Override commit type
#   ./auto-commit.sh --scope <scope>     # Override commit scope
#   ./auto-commit.sh --flush             # Force commit any pending changes
#
# Commit message format: <type>(<scope>): <subject>
#
# Types: draft, revise, polish, format, review, figure, ref, meta, config, checkpoint, interact
# Scopes: methods, results, discussion, introduction, abstract, figures, refs, all

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DEBOUNCE_FILE="$PROJECT_ROOT/.pipeline/.version-guardian-debounce"
DEBOUNCE_SECONDS=30

# --- Helpers ---

log() {
  echo "[version-guardian] $*"
}

# Detect what type of change was made based on changed files
detect_type() {
  local files="$1"

  if echo "$files" | grep -q "review_log\.md"; then
    echo "review"
  elif echo "$files" | grep -q "figure_registry\.md"; then
    echo "figure"
  elif echo "$files" | grep -q "references\.bib"; then
    echo "ref"
  elif echo "$files" | grep -q "style_profile\.md\|journal_spec\.md\|project\.json"; then
    echo "config"
  elif echo "$files" | grep -q "\.pipeline/memory/"; then
    echo "meta"
  elif echo "$files" | grep -q "paper/sections/"; then
    echo "draft"
  elif echo "$files" | grep -q "submission/"; then
    echo "format"
  else
    echo "meta"
  fi
}

# Detect scope from changed files
detect_scope() {
  local files="$1"

  if echo "$files" | grep -q "methods\.tex"; then
    echo "methods"
  elif echo "$files" | grep -q "results\.tex"; then
    echo "results"
  elif echo "$files" | grep -q "discussion\.tex"; then
    echo "discussion"
  elif echo "$files" | grep -q "introduction\.tex"; then
    echo "introduction"
  elif echo "$files" | grep -q "abstract\.tex"; then
    echo "abstract"
  elif echo "$files" | grep -q "figure_registry\|paper/figures"; then
    echo "figures"
  elif echo "$files" | grep -q "references\.bib"; then
    echo "refs"
  elif echo "$files" | grep -q "review_log"; then
    # Try to detect which section was reviewed from the log
    echo "all"
  else
    echo "all"
  fi
}

# Generate a human-readable subject line from the diff
generate_subject() {
  local type="$1"
  local scope="$2"
  local files="$3"

  # Count lines changed
  local stats
  stats="$(cd "$PROJECT_ROOT" && git diff --cached --stat 2>/dev/null | tail -1 || echo "")"
  local insertions
  insertions="$(echo "$stats" | grep -oP '\d+(?= insertion)' || echo "0")"
  local deletions
  deletions="$(echo "$stats" | grep -oP '\d+(?= deletion)' || echo "0")"

  # Count files
  local file_count
  file_count="$(echo "$files" | wc -l)"

  case "$type" in
    draft)
      if [ "$insertions" -gt 100 ]; then
        echo "add substantial content ($insertions lines)"
      else
        echo "update draft ($insertions+ $deletions-)"
      fi
      ;;
    revise)
      echo "revise based on review feedback"
      ;;
    review)
      echo "record review findings"
      ;;
    figure)
      echo "update figure registry"
      ;;
    ref)
      echo "update references"
      ;;
    meta)
      if [ "$file_count" -gt 3 ]; then
        echo "update $file_count memory files"
      else
        local short_files
        short_files="$(echo "$files" | xargs -I{} basename {} | tr '\n' ', ' | sed 's/,$//')"
        echo "update $short_files"
      fi
      ;;
    config)
      echo "update project configuration"
      ;;
    format)
      echo "apply formatting changes"
      ;;
    *)
      echo "update ($insertions+ $deletions-)"
      ;;
  esac
}

# --- Core ---

do_commit() {
  local override_type="${1:-}"
  local override_scope="${2:-}"

  cd "$PROJECT_ROOT"

  # Check for changes
  git add -A 2>/dev/null
  local changed_files
  changed_files="$(git diff --cached --name-only 2>/dev/null)"

  if [ -z "$changed_files" ]; then
    log "No changes to commit."
    return 0
  fi

  # Detect type and scope
  local type="${override_type:-$(detect_type "$changed_files")}"
  local scope="${override_scope:-$(detect_scope "$changed_files")}"
  local subject
  subject="$(generate_subject "$type" "$scope" "$changed_files")"

  # Build commit message
  local message="${type}(${scope}): ${subject}"

  # Add footer with file list
  local footer="Files: $(echo "$changed_files" | tr '\n' ', ' | sed 's/,$//')"

  git commit -m "$message" -m "$footer" 2>/dev/null
  log "Committed: $message"
}

do_debounce() {
  local now
  now="$(date +%s)"

  # Write timestamp to debounce file
  mkdir -p "$(dirname "$DEBOUNCE_FILE")"
  echo "$now" > "$DEBOUNCE_FILE"

  # Wait for debounce period
  sleep "$DEBOUNCE_SECONDS"

  # Check if we're still the latest request
  if [ -f "$DEBOUNCE_FILE" ]; then
    local stored
    stored="$(cat "$DEBOUNCE_FILE")"
    if [ "$stored" = "$now" ]; then
      # We're the latest — commit
      rm -f "$DEBOUNCE_FILE"
      do_commit "$@"
    else
      log "Debounce: newer write detected, skipping this commit"
    fi
  fi
}

# --- Main ---

TYPE=""
SCOPE=""
MODE="immediate"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --debounce) MODE="debounce"; shift ;;
    --flush) MODE="flush"; shift ;;
    --type) TYPE="$2"; shift 2 ;;
    --scope) SCOPE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

case "$MODE" in
  debounce)
    do_debounce "$TYPE" "$SCOPE"
    ;;
  flush|immediate)
    do_commit "$TYPE" "$SCOPE"
    ;;
esac
