#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
from pathlib import Path
from lxml import etree

TEI_NS = "http://www.tei-c.org/ns/1.0"
NS = {"tei": TEI_NS}
TEI = f"{{{TEI_NS}}}"

PROPERTY = "dct:bibliographicCitation"
USE_EXPR = "descendant::listWit[@type='édition']//witness[@ana='edited']"

def add_biblio_inside_acte(cs: etree._Element) -> bool:
    """
    Ajoute <citeData property="dct:bibliographicCitation" use="..."/> EN DERNIER
    dans un citeStructure unit="acte" si absent. Retourne True si modifié.
    """
    # déjà présent ?
    exists = cs.xpath(f"./tei:citeData[@property='{PROPERTY}']", namespaces=NS)
    if exists:
        return False

    new_cd = etree.Element(f"{TEI}citeData")
    new_cd.set("property", PROPERTY)
    new_cd.set("use", USE_EXPR)

    # "en dernier" DEDANS = après le dernier citeData si présent, sinon append
    cds = cs.xpath("./tei:citeData", namespaces=NS)
    if cds:
        cs.insert(cs.index(cds[-1]) + 1, new_cd)
    else:
        cs.append(new_cd)

    return True

def process_file(in_path: Path, out_path: Path) -> tuple[bool, str]:
    parser = etree.XMLParser(huge_tree=True, remove_blank_text=False)
    tree = etree.parse(str(in_path), parser)
    root = tree.getroot()

    acte_structs = root.xpath("//tei:citeStructure[@unit='acte']", namespaces=NS)

    changed = False
    for cs in acte_structs:
        if add_biblio_inside_acte(cs):
            changed = True

    out_path.parent.mkdir(parents=True, exist_ok=True)
    tree.write(str(out_path), encoding="utf-8", xml_declaration=True, pretty_print=True)
    return changed, "ok"

def iter_xml_files(in_dir: Path, recursive: bool) -> list[Path]:
    if recursive:
        return sorted([p for p in in_dir.rglob("*.xml") if p.is_file()])
    return sorted([p for p in in_dir.glob("*.xml") if p.is_file()])

def main():
    if len(sys.argv) < 3:
        print("Usage: python add_dct_biblio_inside_acte.py <input_dir> <output_dir> [--recursive]")
        sys.exit(1)

    in_dir = Path(sys.argv[1]).expanduser().resolve()
    out_dir = Path(sys.argv[2]).expanduser().resolve()
    recursive = ("--recursive" in sys.argv[3:])

    if not in_dir.is_dir():
        print(f"[ERROR] Input directory not found: {in_dir}")
        sys.exit(2)

    files = iter_xml_files(in_dir, recursive)
    if not files:
        print("[ERROR] No XML files found in input directory.")
        sys.exit(3)

    total = modified = errors = 0

    for f in files:
        rel = f.relative_to(in_dir)
        out_path = out_dir / rel
        total += 1
        try:
            changed, status = process_file(f, out_path)
            if status != "ok":
                errors += 1
                print(f"[{total}] {rel} -> {status}")
                continue
            if changed:
                modified += 1
                print(f"[{total}] {rel} -> modified")
            else:
                print(f"[{total}] {rel} -> unchanged")
        except Exception as e:
            errors += 1
            print(f"[{total}] {rel} -> ERROR: {type(e).__name__}: {e}")

    print(f"[DONE] files={total} modified={modified} errors={errors}")
    print(f"[OUT]  {out_dir}")

if __name__ == "__main__":
    main()
