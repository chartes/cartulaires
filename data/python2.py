#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
from pathlib import Path
from lxml import etree

TEI_NS = "http://www.tei-c.org/ns/1.0"
NS = {"tei": TEI_NS}

def count_xpath(tree, xp, namespaces=None):
    try:
        return int(tree.xpath(f"count({xp})", namespaces=namespaces))
    except Exception as e:
        print(f"[XPATH ERROR] {xp} -> {e}")
        return -1

def check_file(f: Path):
    print(f"\n--- {f} ---")
    parser = etree.XMLParser(recover=True, huge_tree=True)
    tree = etree.parse(str(f), parser)

    # TEI namespace version
    total_tei = count_xpath(tree, ".//tei:witness", namespaces=NS)
    missing_tei = count_xpath(tree, ".//tei:witness[not(@n)]", namespaces=NS)

    # Fallback no-namespace version
    total_no = count_xpath(tree, ".//witness", namespaces=None)
    missing_no = count_xpath(tree, ".//witness[not(@n)]", namespaces=None)

    print(f"[TEI ns] witness total={total_tei} | missing @n={missing_tei}")
    print(f"[no ns ] witness total={total_no}  | missing @n={missing_no}")

    # Decide which is relevant
    if total_tei > 0:
        return total_tei, missing_tei
    else:
        return total_no, missing_no

def iter_xml_files(p: Path):
    if p.is_file():
        return [p]
    files = list(p.rglob("*.xml"))
    return files

def main():
    print("[START] check_witness_n.py")
    if len(sys.argv) < 2:
        print("Usage: python check_witness_n.py <xml_file_or_folder>")
        sys.exit(1)

    target = Path(sys.argv[1]).expanduser().resolve()
    print(f"[PATH] target={target}")

    if not target.exists():
        print("[ERROR] Path does not exist.")
        sys.exit(2)

    files = iter_xml_files(target)
    print(f"[INFO] xml files found: {len(files)}")
    if len(files) == 0:
        print("[ERROR] No .xml files found under this path.")
        sys.exit(3)

    grand_total = 0
    grand_missing = 0
    files_with_missing = 0

    for f in files:
        total, missing = check_file(f)
        grand_total += max(total, 0)
        grand_missing += max(missing, 0)
        if missing and missing > 0:
            files_with_missing += 1

    print("\n=== SUMMARY ===")
    print(f"Files scanned: {len(files)}")
    print(f"Witness total: {grand_total}")
    print(f"Missing @n:    {grand_missing}")
    print(f"Files w/ missing: {files_with_missing}")
    print("[END]")

if __name__ == "__main__":
    main()
