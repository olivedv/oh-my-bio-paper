#!/usr/bin/env python3
"""Extract image metadata (dimensions, DPI, color space, file size).

Supported formats: TIFF, TIF, PNG, SVG, PDF (v1.3.1)

Usage:
    python3 parse-metadata.py <filepath>

Output: JSON to stdout with keys:
    width, height, dpi, color_space, file_size_mb, created

Falls back gracefully if PIL is not installed — returns partial metadata.
"""

import json
import os
import sys
from datetime import datetime, timezone


def get_file_metadata(filepath):
    """Get basic file metadata available without any library."""
    stat = os.stat(filepath)
    return {
        "file_size_mb": round(stat.st_size / (1024 * 1024), 2),
        "created": datetime.fromtimestamp(
            stat.st_ctime, tz=timezone.utc
        ).isoformat(),
    }


def get_image_metadata_pil(filepath):
    """Extract image metadata using PIL/Pillow."""
    try:
        from PIL import Image
    except ImportError:
        return None

    ext = os.path.splitext(filepath)[1].lower()

    # PIL cannot handle SVG or PDF natively
    if ext in (".svg", ".pdf"):
        return None

    try:
        with Image.open(filepath) as img:
            width, height = img.size
            dpi_info = img.info.get("dpi", (None, None))
            dpi = int(dpi_info[0]) if dpi_info[0] else None
            color_space = img.mode  # RGB, CMYK, L (grayscale), etc.

            return {
                "width": width,
                "height": height,
                "dpi": dpi,
                "color_space": color_space,
            }
    except Exception:
        return None


def get_svg_metadata(filepath):
    """Extract SVG dimensions from the root element."""
    try:
        import xml.etree.ElementTree as ET

        tree = ET.parse(filepath)
        root = tree.getroot()

        # Handle namespace
        ns = ""
        if root.tag.startswith("{"):
            ns = root.tag.split("}")[0] + "}"

        width = root.get("width", "unknown")
        height = root.get("height", "unknown")
        viewbox = root.get("viewBox", "")

        return {
            "width": width,
            "height": height,
            "dpi": None,
            "color_space": "SVG (vector)",
            "viewbox": viewbox,
        }
    except Exception:
        return None


def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "No filepath provided"}))
        sys.exit(1)

    filepath = sys.argv[1]
    if not os.path.isfile(filepath):
        print(json.dumps({"error": f"File not found: {filepath}"}))
        sys.exit(1)

    ext = os.path.splitext(filepath)[1].lower()

    # Start with basic file metadata
    result = get_file_metadata(filepath)
    result["metadata_complete"] = False

    # Try PIL for raster images
    if ext in (".tiff", ".tif", ".png"):
        pil_data = get_image_metadata_pil(filepath)
        if pil_data:
            result.update(pil_data)
            result["metadata_complete"] = True

    # Try XML parsing for SVG
    elif ext == ".svg":
        svg_data = get_svg_metadata(filepath)
        if svg_data:
            result.update(svg_data)
            result["metadata_complete"] = True

    # PDF — just basic file info (full parsing needs additional libs)
    elif ext == ".pdf":
        result["color_space"] = "PDF (vector/raster)"
        result["width"] = "unknown"
        result["height"] = "unknown"
        result["dpi"] = None
        # metadata_complete stays False — user should verify manually

    print(json.dumps(result))


if __name__ == "__main__":
    main()
