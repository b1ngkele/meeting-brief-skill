#!/usr/bin/env python3
"""Extract readable text from PPTX meeting materials into Markdown."""

from __future__ import annotations

import argparse
import re
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET


NS = {
    "p": "http://schemas.openxmlformats.org/presentationml/2006/main",
    "a": "http://schemas.openxmlformats.org/drawingml/2006/main",
    "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
    "c": "http://schemas.openxmlformats.org/drawingml/2006/chart",
}


def q(prefix: str, name: str) -> str:
    return f"{{{NS[prefix]}}}{name}"


def slide_paths(package: zipfile.ZipFile) -> list[str]:
    presentation = ET.fromstring(package.read("ppt/presentation.xml"))
    rels = ET.fromstring(package.read("ppt/_rels/presentation.xml.rels"))
    relmap = {rel.attrib["Id"]: rel.attrib["Target"] for rel in rels}
    paths = []
    for slide_id in presentation.findall(".//p:sldId", NS):
        target = relmap[slide_id.attrib[q("r", "id")]]
        paths.append("ppt/" + target.lstrip("/"))
    return paths


def shape_texts(slide_root: ET.Element) -> list[str]:
    texts = []
    for shape in slide_root.findall(".//p:sp", NS):
        lines = []
        for paragraph in shape.findall(".//a:p", NS):
            text = "".join(node.text or "" for node in paragraph.findall(".//a:t", NS))
            text = re.sub(r"\s+", " ", text).strip()
            if text:
                lines.append(text)
        if lines:
            texts.append(" / ".join(lines))
    return texts


def compact_texts(texts: list[str]) -> list[str]:
    compacted = []
    previous = None
    for text in texts:
        if text == previous:
            continue
        compacted.append(text)
        previous = text
    return compacted


def extract_pptx(pptx_path: Path, output_path: Path):
    with zipfile.ZipFile(pptx_path) as package:
        paths = slide_paths(package)
        chunks = [f"# {pptx_path.name}", ""]
        for index, slide_path in enumerate(paths, 1):
            root = ET.fromstring(package.read(slide_path))
            texts = compact_texts(shape_texts(root))
            pictures = len(root.findall(".//p:pic", NS))
            tables = len(root.findall(".//a:tbl", NS))
            charts = len(root.findall(".//c:chart", NS))

            chunks.append(f"## Slide {index}")
            chunks.append(f"- 图片: {pictures}")
            chunks.append(f"- 表格: {tables}")
            chunks.append(f"- 图表: {charts}")
            chunks.append("")
            if texts:
                for text in texts:
                    chunks.append(f"- {text}")
            else:
                chunks.append("- 未抽取到可编辑文字，可能主要由图片构成。")
            chunks.append("")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(chunks), encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("pptx", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    output = args.output or args.pptx.with_suffix(".md")
    extract_pptx(args.pptx, output)
    print(output)


if __name__ == "__main__":
    main()
