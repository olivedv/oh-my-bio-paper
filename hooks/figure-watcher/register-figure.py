#!/usr/bin/env python3
"""Register a new figure entry into .pipeline/memory/figure_registry.md.

Usage:
    python3 register-figure.py \
        --registry <path_to_figure_registry.md> \
        --filepath <relative_file_path> \
        --figure-num <N> \
        --figure-type <figure|supplementary_figure|table|unknown> \
        --description <parsed_description> \
        --metadata <json_string_from_parse_metadata>
"""

import argparse
import json
import os
import sys
from datetime import datetime, timezone


def build_entry(args):
    """Build a markdown entry for the figure registry."""
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    # Parse metadata JSON
    meta = {}
    if args.metadata:
        try:
            meta = json.loads(args.metadata)
        except (json.JSONDecodeError, TypeError):
            pass

    # Determine heading
    if args.figure_type == "table":
        heading = f"Table {args.figure_num}"
    elif args.figure_type == "supplementary_figure":
        heading = f"Supplementary Figure {args.figure_num}"
    elif args.figure_num == "?":
        heading = f"Unrecognized — {args.description}"
    else:
        heading = f"Figure {args.figure_num}"

    # Build dimensions string
    width = meta.get("width", "unknown")
    height = meta.get("height", "unknown")
    dim_str = f"{width} × {height} px" if width != "unknown" else "unknown"

    # DPI with journal check
    dpi = meta.get("dpi")
    if dpi and dpi >= 300:
        dpi_str = f"{dpi} (meets 300 DPI requirement)"
    elif dpi:
        dpi_str = f"{dpi} ⚠️ BELOW 300 DPI — may not meet journal requirements"
    else:
        dpi_str = "unknown"

    color = meta.get("color_space", "unknown")
    size_mb = meta.get("file_size_mb", "unknown")

    # Status
    if args.figure_num == "?":
        status = "[NEEDS_RENAME] [NEEDS_HUMAN_ANNOTATION]"
    elif not meta.get("metadata_complete", False):
        status = "[METADATA_INCOMPLETE] [NEEDS_HUMAN_ANNOTATION]"
    else:
        status = "[NEEDS_HUMAN_ANNOTATION]"

    entry = f"""
### {heading} — {args.description}
- **File**: `{args.filepath}`
- **Registered**: {now} (auto by figure-watcher)
- **Dimensions**: {dim_str}
- **DPI**: {dpi_str}
- **Color**: {color}
- **File size**: {size_mb} MB
- **Parsed title**: {args.description}
- **Status**: {status}

#### Panels
_To be filled by user or during /omp:write results_
- (A) _description pending_
- (B) _description pending_

#### Statistics
_To be filled_
- Test: ?
- n: ?
- Error bars: ?

#### Referenced in
- Results section: _not yet referenced_
"""
    return entry


def main():
    parser = argparse.ArgumentParser(description="Register a figure in the registry")
    parser.add_argument("--registry", required=True, help="Path to figure_registry.md")
    parser.add_argument("--filepath", required=True, help="Relative file path")
    parser.add_argument("--figure-num", required=True, help="Figure number")
    parser.add_argument(
        "--figure-type",
        required=True,
        choices=["figure", "supplementary_figure", "table", "unknown"],
    )
    parser.add_argument("--description", required=True, help="Parsed description")
    parser.add_argument("--metadata", default="", help="JSON metadata string")

    args = parser.parse_args()

    # Check registry exists
    if not os.path.isfile(args.registry):
        print(f"ERROR: Registry not found: {args.registry}", file=sys.stderr)
        sys.exit(1)

    # Check not already registered
    with open(args.registry, "r", encoding="utf-8") as f:
        content = f.read()
    if args.filepath in content:
        print(f"Already registered: {args.filepath}")
        return

    # Build and append entry
    entry = build_entry(args)

    # Find insertion point — append before "## Tables" if it exists,
    # otherwise append at end of "## Figures" section
    with open(args.registry, "a", encoding="utf-8") as f:
        f.write(entry)

    print(f"Registered: {args.filepath}")


if __name__ == "__main__":
    main()
