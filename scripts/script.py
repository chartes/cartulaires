#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import re
from pathlib import Path
from lxml import etree


TEI_NS = "http://www.tei-c.org/ns/1.0"
NS = {"tei": TEI_NS}


def norm_sig(s: str) -> str:
    """Normalize siglum-ish strings for comparison."""
    if s is None:
        return ""
    s = re.sub(r"\s+", " ", s.strip())
    # remove surrounding brackets and trailing punctuation/spaces
    s = re.sub(r"^[\(\[\{]+", "", s)
    s = re.sub(r"[\)\]\}\.\:\s]+$", "", s)
    return s


def clean_tail_after_siglum(tail: str) -> str:
    """Remove leading punctuation that belongs to the removed siglum, keep readable spacing."""
    if not tail:
        return ""
    # e.g. ". Original perdu." -> " Original perdu."
    tail = re.sub(r"^\s*[\.\:]\s*", " ", tail)
    # e.g. " — Original ..." / " - Original ..." -> " Original ..."
    tail = re.sub(r"^\s*[-–—]\s*", " ", tail)
    # normalize leading whitespace to a single space (or empty if tail was only punct)
    tail = re.sub(r"^\s+", " ", tail)
    return tail


def first_element_child(el):
    for ch in el:
        if isinstance(ch.tag, str):
            return ch
    return None


def process_tree(tree: etree._ElementTree, aggressive: bool = False):
    """
    aggressive=False (default): only remove if hi is FIRST element child AND witness.text is empty/whitespace.
    aggressive=True: also remove matching hi even if witness has leading whitespace text.
    """
    root = tree.getroot()
    changes = []
    changed_count = 0

    for w in root.xpath(".//tei:witness[@n]", namespaces=NS):
        n = w.get("n")
        if not n:
            continue

        hi = first_element_child(w)
        if hi is None:
            continue
        if etree.QName(hi).namespace != TEI_NS or etree.QName(hi).localname != "hi":
            continue

        # Optional safety: target mostly hi[@rend='i'] or hi with no @rend
        if hi.get("rend") not in (None, "i"):
            continue

        hi_text = "".join(hi.itertext())
        if norm_sig(hi_text).lower() != norm_sig(n).lower():
            continue

        if not aggressive and (w.text or "").strip():
            # there is meaningful text before the hi => skip (too risky)
            continue

        # Apply edit: remove hi, keep cleaned tail
        old_snippet = etree.tostring(w, encoding="unicode")
        tail = hi.tail or ""
        new_tail = clean_tail_after_siglum(tail)

        w.text = (w.text or "") + new_tail
        w.remove(hi)

        new_snippet = etree.tostring(w, encoding="unicode")
        changed_count += 1
        changes.append((n, hi_text, tail.strip()[:80], old_snippet, new_snippet))

    return changed_count, changes


def process_file(path: Path, inplace: bool, dry_run: bool, aggressive: bool, suffix: str):
    parser = etree.XMLParser(remove_blank_text=False, recover=True, huge_tree=True)
    tree = etree.parse(str(path), parser)

    changed_count, changes = process_tree(tree, aggressive=aggressive)

    if dry_run:
        return changed_count, changes, None

    if changed_count == 0:
        return 0, changes, None

    out_path = path if inplace else path.with_suffix(path.suffix + suffix)

    # Backup if inplace
    if inplace:
        backup = path.with_suffix(path.suffix + ".bak")
        if not backup.exists():
            backup.write_bytes(path.read_bytes())

    tree.write(
        str(out_path),
        encoding="utf-8",
        xml_declaration=True,
        pretty_print=False,  # minimize diffs
    )
    return changed_count, changes, out_path


def iter_xml_files(root: Path):
    if root.is_file():
        yield root
    else:
        yield from root.rglob("*.xml")


def main():
    ap = argparse.ArgumentParser(description="Remove redundant <hi> siglum inside <witness> when it repeats @n.")
    ap.add_argument("path", help="XML file or directory containing XML files")
    ap.add_argument("--inplace", action="store_true", help="Modify files in place (creates .bak backup once)")
    ap.add_argument("--dry-run", action="store_true", help="Do not write files, only report")
    ap.add_argument("--aggressive", action="store_true", help="Less strict matching (use with caution)")
    ap.add_argument("--suffix", default=".cleaned.xml", help="Suffix for output when not --inplace")
    ap.add_argument("--report", default="witness_hi_report.txt", help="Write a text report (default: witness_hi_report.txt)")
    args = ap.parse_args()

    root = Path(args.path).expanduser().resolve()
    if not root.exists():
        raise SystemExit(f"Path not found: {root}")

    total_changed = 0
    report_lines = []
    touched_files = 0

    for f in iter_xml_files(root):
        changed, changes, out_path = process_file(
            f,
            inplace=args.inplace,
            dry_run=args.dry_run,
            aggressive=args.aggressive,
            suffix=args.suffix,
        )
        if changed:
            touched_files += 1
        total_changed += changed

        if changes:
            report_lines.append(f"\n=== {f} ===\nChanged: {changed}\n")
            for (n, hi_text, tail_preview, old_snip, new_snip) in changes[:200]:
                report_lines.append(f"- witness @n={n!r} removed hi={hi_text!r} tail={tail_preview!r}\n")
            if len(changes) > 200:
                report_lines.append(f"... ({len(changes)-200} more in this file)\n")

    report_path = Path(args.report).resolve()
    report_path.write_text("".join(report_lines) if report_lines else "No changes detected.\n", encoding="utf-8")

    print(f"Files scanned: {len(list(iter_xml_files(root)))}")
    print(f"Files changed: {touched_files}")
    print(f"Total <witness> edits: {total_changed}")
    print(f"Report written: {report_path}")


if __name__ == "__main__":
    main()
