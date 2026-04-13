#!/usr/bin/env python3
"""Generate intelligent commit messages by analyzing staged changes.

Usage:
    python3 smart-message.py                    # Analyze staged changes
    python3 smart-message.py --diff <c1> <c2>   # Describe diff between two commits
    python3 smart-message.py --history [N]       # Show last N commits in readable format
    python3 smart-message.py --history [N] --section <name>  # Filter by section
    python3 smart-message.py --history [N] --type <type>     # Filter by commit type

Commit message format: <type>(<scope>): <subject>

Types: draft, revise, polish, format, review, figure, ref, meta, config, checkpoint, interact
Scopes: methods, results, discussion, introduction, abstract, figures, refs, all
"""

import argparse
import os
import re
import subprocess
import sys


def run_git(*args):
    """Run a git command and return stdout."""
    result = subprocess.run(
        ["git"] + list(args),
        capture_output=True,
        text=True,
        cwd=os.environ.get("PROJECT_ROOT", "."),
    )
    return result.stdout.strip()


def get_staged_files():
    """Get list of staged files."""
    output = run_git("diff", "--cached", "--name-only")
    return [f for f in output.split("\n") if f]


def get_staged_stat():
    """Get insertion/deletion stats for staged changes."""
    output = run_git("diff", "--cached", "--stat")
    return output


def detect_type_from_files(files):
    """Detect commit type from changed file paths."""
    for f in files:
        if "review_log" in f:
            return "review"
        if "figure_registry" in f:
            return "figure"
        if "references.bib" in f:
            return "ref"
        if any(x in f for x in ["style_profile", "journal_spec", "project.json"]):
            return "config"
    for f in files:
        if "paper/sections/" in f:
            return "draft"
        if ".pipeline/memory/" in f:
            return "meta"
        if "submission/" in f:
            return "format"
    return "meta"


def detect_scope_from_files(files):
    """Detect commit scope from changed file paths."""
    section_map = {
        "methods": "methods",
        "results": "results",
        "discussion": "discussion",
        "introduction": "introduction",
        "abstract": "abstract",
    }
    for f in files:
        for key, scope in section_map.items():
            if key in f.lower():
                return scope
    for f in files:
        if "figure" in f.lower():
            return "figures"
        if "references" in f.lower() or "refs" in f.lower():
            return "refs"
    return "all"


def generate_message():
    """Generate a commit message for staged changes."""
    files = get_staged_files()
    if not files:
        print("No staged changes.")
        return

    commit_type = detect_type_from_files(files)
    scope = detect_scope_from_files(files)

    # Get stats
    stat = get_staged_stat()
    insertions = 0
    deletions = 0
    match = re.search(r"(\d+) insertion", stat)
    if match:
        insertions = int(match.group(1))
    match = re.search(r"(\d+) deletion", stat)
    if match:
        deletions = int(match.group(1))

    # Build subject
    if commit_type == "draft" and insertions > 100:
        subject = f"add substantial content ({insertions} lines)"
    elif commit_type == "draft":
        subject = f"update draft ({insertions}+ {deletions}-)"
    elif commit_type == "review":
        subject = "record review findings"
    elif commit_type == "figure":
        subject = "update figure registry"
    elif commit_type == "ref":
        subject = "update references"
    elif commit_type == "meta":
        basenames = [os.path.basename(f) for f in files[:3]]
        subject = f"update {', '.join(basenames)}"
    else:
        subject = f"update ({insertions}+ {deletions}-)"

    message = f"{commit_type}({scope}): {subject}"
    print(message)


def show_history(n=20, section_filter=None, type_filter=None):
    """Show commit history in a human-readable format."""
    # Build git log command
    args = ["log", f"--max-count={n}", "--format=%H|%s|%ai|%an"]

    # Add path filter for section
    section_paths = {
        "methods": "paper/sections/methods.tex",
        "results": "paper/sections/results.tex",
        "discussion": "paper/sections/discussion.tex",
        "introduction": "paper/sections/introduction.tex",
        "abstract": "paper/sections/abstract.tex",
    }

    if section_filter and section_filter in section_paths:
        args.extend(["--", section_paths[section_filter]])

    output = run_git(*args)
    if not output:
        print("No commits found.")
        return

    print(f"{'#':<4} {'Type':<12} {'Scope':<14} {'Subject':<45} {'Date':<12}")
    print("-" * 87)

    idx = 0
    for line in output.split("\n"):
        if not line:
            continue
        parts = line.split("|", 3)
        if len(parts) < 4:
            continue

        commit_hash, subject, date, author = parts
        short_hash = commit_hash[:7]

        # Parse type(scope): subject
        match = re.match(r"(\w+)\((\w+)\):\s*(.*)", subject)
        if match:
            ctype, scope, desc = match.groups()
        else:
            ctype, scope, desc = "other", "—", subject

        # Apply type filter
        if type_filter and ctype != type_filter:
            continue

        # Format date
        short_date = date[:10]

        idx += 1
        print(f"{idx:<4} {ctype:<12} {scope:<14} {desc:<45} {short_date}")


def describe_diff(commit1, commit2):
    """Describe the diff between two commits in human-readable form."""
    # Get file-level changes
    stat = run_git("diff", "--stat", commit1, commit2)
    name_only = run_git("diff", "--name-only", commit1, commit2)
    files = [f for f in name_only.split("\n") if f]

    if not files:
        print("No differences found.")
        return

    # Group by category
    sections_changed = []
    memory_changed = []
    other_changed = []

    for f in files:
        if "paper/sections/" in f:
            sections_changed.append(f)
        elif ".pipeline/memory/" in f:
            memory_changed.append(f)
        else:
            other_changed.append(f)

    print(f"Comparing {commit1[:7]}..{commit2[:7]}")
    print(f"Total: {len(files)} files changed\n")

    if sections_changed:
        print("## Paper sections changed:")
        for f in sections_changed:
            section_name = os.path.basename(f).replace(".tex", "")
            diff_stat = run_git("diff", "--numstat", commit1, commit2, "--", f)
            if diff_stat:
                parts = diff_stat.split("\t")
                added = parts[0] if len(parts) > 0 else "?"
                removed = parts[1] if len(parts) > 1 else "?"
                print(f"  - {section_name}: +{added} -{removed} lines")
        print()

    if memory_changed:
        print("## Memory files changed:")
        for f in memory_changed:
            print(f"  - {os.path.basename(f)}")
        print()

    if other_changed:
        print("## Other files:")
        for f in other_changed:
            print(f"  - {f}")


def main():
    parser = argparse.ArgumentParser(description="Smart commit message generator")
    parser.add_argument(
        "--diff", nargs=2, metavar=("COMMIT1", "COMMIT2"), help="Describe diff"
    )
    parser.add_argument(
        "--history", nargs="?", const=20, type=int, help="Show N recent commits"
    )
    parser.add_argument("--section", help="Filter history by section name")
    parser.add_argument("--type", dest="commit_type", help="Filter history by type")

    args = parser.parse_args()

    if args.diff:
        describe_diff(args.diff[0], args.diff[1])
    elif args.history is not None:
        show_history(args.history, args.section, args.commit_type)
    else:
        generate_message()


if __name__ == "__main__":
    main()
