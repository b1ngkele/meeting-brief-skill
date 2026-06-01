#!/usr/bin/env python3
"""Extract text and tables from a PDF file into a Markdown file using pdfplumber."""

from __future__ import annotations

import argparse
from pathlib import Path

import pdfplumber


def table_to_markdown(table: list[list[str | None]]) -> str:
    """Convert a pdfplumber table (list of rows) to a markdown table string."""
    if not table or len(table) < 1:
        return ""
    # Clean cells: replace None with empty string, collapse newlines
    cleaned = [
        [(cell.replace("\n", " ").strip() if cell else "") for cell in row]
        for row in table
    ]
    header = cleaned[0]
    if not any(header):
        return ""
    # Build markdown
    lines = []
    lines.append("| " + " | ".join(header) + " |")
    lines.append("| " + " | ".join("---" for _ in header) + " |")
    for row in cleaned[1:]:
        # Pad row if shorter than header
        padded = row + [""] * (len(header) - len(row))
        lines.append("| " + " | ".join(padded) + " |")
    return "\n".join(lines)


def extract_page(page: pdfplumber.page.Page) -> str:
    """Extract text and tables from a single page."""
    parts: list[str] = []

    # Extract full-page text
    text = page.extract_text()
    if text:
        parts.append(text.strip())

    # Extract tables as markdown (appended after text)
    tables = page.find_tables()
    for t in tables:
        md = table_to_markdown(t.extract())
        if md:
            parts.append(md)

    return "\n\n".join(parts)


def extract_pdf(pdf_path: Path, output_path: Path | None = None) -> Path:
    """Extract a PDF to a markdown file."""
    if output_path is None:
        output_path = pdf_path.with_suffix(".md")

    sections: list[str] = []
    with pdfplumber.open(pdf_path) as pdf:
        for i, page in enumerate(pdf.pages, start=1):
            content = extract_page(page)
            if content:
                sections.append(f"<!-- Page {i} -->\n{content}")

    output_path.write_text("\n\n---\n\n".join(sections), encoding="utf-8")
    return output_path


def main():
    parser = argparse.ArgumentParser(description="Extract PDF to Markdown")
    parser.add_argument("pdf", type=Path, help="Path to the PDF file")
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=None,
        help="Output markdown path (default: same name with .md)",
    )
    args = parser.parse_args()

    if not args.pdf.exists():
        raise FileNotFoundError(f"PDF not found: {args.pdf}")

    result = extract_pdf(args.pdf, args.output)
    print(f"Extracted to: {result}")


if __name__ == "__main__":
    main()
