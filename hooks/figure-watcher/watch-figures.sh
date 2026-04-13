#!/usr/bin/env bash
# figure-watcher: Watch paper/figures/ for new or modified image files.
# Supported formats: tiff, tif, png, svg, pdf (v1.3.1)
#
# Usage:
#   ./watch-figures.sh                 # Scan paper/figures/ once
#   ./watch-figures.sh --watch         # Continuous watch mode (requires fswatch/inotifywait)
#   ./watch-figures.sh <filepath>      # Process a single file
#
# This script is called by the PostToolUse Hook when files are written
# to paper/figures/, or manually via `/omp:figures scan`.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIGURES_DIR="$PROJECT_ROOT/paper/figures"
REGISTRY="$PROJECT_ROOT/.pipeline/memory/figure_registry.md"
DEBOUNCE_DIR="$PROJECT_ROOT/.pipeline/.figure-watcher-cache"

SUPPORTED_EXTENSIONS="tiff tif png svg pdf"

# --- Helpers ---

log() {
  echo "[figure-watcher] $*"
}

is_supported() {
  local ext="${1##*.}"
  ext="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"
  for e in $SUPPORTED_EXTENSIONS; do
    [ "$ext" = "$e" ] && return 0
  done
  return 1
}

# Debounce: skip if same file was processed within last 5 minutes
should_skip() {
  local filepath="$1"
  local hash
  hash="$(echo "$filepath" | md5sum 2>/dev/null | cut -d' ' -f1 || echo "$filepath")"
  local stamp_file="$DEBOUNCE_DIR/$hash"

  mkdir -p "$DEBOUNCE_DIR"

  if [ -f "$stamp_file" ]; then
    local last_ts
    last_ts="$(cat "$stamp_file")"
    local now_ts
    now_ts="$(date +%s)"
    local diff=$(( now_ts - last_ts ))
    if [ "$diff" -lt 300 ]; then
      return 0  # Skip — within 5 min debounce window
    fi
  fi

  date +%s > "$stamp_file"
  return 1
}

# Parse figure number and description from filename
# Expected: Fig<N>_<description>.<ext> or FigS<N>_<description>.<ext>
# Also handles: Table<N>_<description>.<ext>
parse_filename() {
  local basename="$1"
  local name="${basename%.*}"

  FIGURE_NUM=""
  FIGURE_DESC=""
  FIGURE_TYPE="figure"  # figure, supplementary_figure, table

  if [[ "$name" =~ ^Fig([0-9]+)_(.+)$ ]]; then
    FIGURE_NUM="${BASH_REMATCH[1]}"
    FIGURE_DESC="${BASH_REMATCH[2]//_/ }"
    FIGURE_TYPE="figure"
  elif [[ "$name" =~ ^FigS([0-9]+)_(.+)$ ]]; then
    FIGURE_NUM="S${BASH_REMATCH[1]}"
    FIGURE_DESC="${BASH_REMATCH[2]//_/ }"
    FIGURE_TYPE="supplementary_figure"
  elif [[ "$name" =~ ^Table([0-9]+)_(.+)$ ]]; then
    FIGURE_NUM="${BASH_REMATCH[1]}"
    FIGURE_DESC="${BASH_REMATCH[2]//_/ }"
    FIGURE_TYPE="table"
  else
    FIGURE_NUM="?"
    FIGURE_DESC="[NEEDS_RENAME] $name"
    FIGURE_TYPE="unknown"
  fi
}

# Check if figure is already registered in the registry
is_registered() {
  local filepath="$1"
  if [ -f "$REGISTRY" ]; then
    grep -qF "$filepath" "$REGISTRY" 2>/dev/null && return 0
  fi
  return 1
}

# --- Main processing ---

process_file() {
  local filepath="$1"
  local relpath="${filepath#$PROJECT_ROOT/}"
  local basename="$(basename "$filepath")"

  # Check supported format
  if ! is_supported "$basename"; then
    log "Skipping unsupported format: $basename"
    return 0
  fi

  # Debounce check
  if should_skip "$filepath"; then
    log "Debounce: skipping $basename (processed recently)"
    return 0
  fi

  # Already registered?
  if is_registered "$relpath"; then
    log "Already registered: $relpath"
    return 0
  fi

  log "Processing: $basename"

  # Parse filename
  parse_filename "$basename"

  # Try to extract metadata via Python
  local metadata=""
  if command -v python3 &>/dev/null; then
    metadata="$(python3 "$SCRIPT_DIR/parse-metadata.py" "$filepath" 2>/dev/null || echo "")"
  elif command -v python &>/dev/null; then
    metadata="$(python "$SCRIPT_DIR/parse-metadata.py" "$filepath" 2>/dev/null || echo "")"
  fi

  # Register the figure
  python3 "$SCRIPT_DIR/register-figure.py" \
    --registry "$REGISTRY" \
    --filepath "$relpath" \
    --figure-num "$FIGURE_NUM" \
    --figure-type "$FIGURE_TYPE" \
    --description "$FIGURE_DESC" \
    --metadata "$metadata" \
    2>/dev/null \
  || python "$SCRIPT_DIR/register-figure.py" \
    --registry "$REGISTRY" \
    --filepath "$relpath" \
    --figure-num "$FIGURE_NUM" \
    --figure-type "$FIGURE_TYPE" \
    --description "$FIGURE_DESC" \
    --metadata "$metadata" \
    2>/dev/null \
  || {
    log "WARNING: register-figure.py failed, attempting manual registration"
    # Fallback: append minimal entry directly
    cat >> "$REGISTRY" << ENTRY

### Fig${FIGURE_NUM} — ${FIGURE_DESC}
- **File**: ${relpath}
- **Registered**: $(date -u +"%Y-%m-%dT%H:%M:%SZ") (auto by figure-watcher)
- **Metadata**: [METADATA_INCOMPLETE] (Python not available)
- **Parsed title**: ${FIGURE_DESC}
- **Status**: [NEEDS_HUMAN_ANNOTATION]
ENTRY
    log "Registered (fallback): $basename"
  }

  log "Done: $basename"
}

# --- Entry points ---

scan_directory() {
  log "Scanning $FIGURES_DIR ..."
  if [ ! -d "$FIGURES_DIR" ]; then
    log "Directory does not exist: $FIGURES_DIR"
    return 0
  fi

  local count=0
  for f in "$FIGURES_DIR"/*; do
    [ -f "$f" ] || continue
    process_file "$f"
    count=$((count + 1))
  done
  log "Scan complete. Checked $count files."
}

# --- Main ---

case "${1:-}" in
  --watch)
    log "Watch mode not yet implemented (requires fswatch or inotifywait)"
    log "Falling back to single scan."
    scan_directory
    ;;
  "")
    scan_directory
    ;;
  *)
    # Single file mode
    if [ -f "$1" ]; then
      process_file "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
    else
      log "File not found: $1"
      exit 1
    fi
    ;;
esac
