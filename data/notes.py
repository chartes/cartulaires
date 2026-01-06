#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
from pathlib import Path
from lxml import etree

TEI_NS = "http://www.tei-c.org/ns/1.0"
NS = {"tei": TEI_NS}


def iter_xml_files(p: Path):
    return [p] if p.is_file() else list(p.rglob("*.xml"))


def pass_ref_note_to_note(tree) -> int:
    """
    Convertit strictement:
      <ref type="note" .../>  -->  <note .../>
      <ref type="note" ...>...</ref> --> <note ...>...</note>

    - Ne touche qu'aux tei:ref[@type='note']
    - Conserve @n, @target, etc.
    - Supprime l'attribut type="note" (redondant puisque l'élément devient <note>)
    - Conserve texte/enfants et la tail
    """
    changed = 0
    refs = tree.xpath("//tei:ref[@type='note']", namespaces=NS)

    for r in refs:
        note = etree.Element(f"{{{TEI_NS}}}note")

        # Copy attributes except type="note"
        for k, v in r.attrib.items():
            if k == "type" and v == "note":
                continue
            note.set(k, v)

        # Copy content
        note.text = r.text
        for ch in list(r):
            r.remove(ch)
            note.append(ch)

        # Keep tail
        note.tail = r.tail

        # Replace
        parent = r.getparent()
        parent.replace(r, note)
        changed += 1

    return changed


def pass_report_broken_note_targets(tree) -> int:
    """
    Report (ne modifie pas) : notes inline qui ont @target mais la cible n'existe pas (xml:id introuvable).
    """
    broken = tree.xpath(
        "//tei:note[@target and not(//*[@xml:id = substring-after(@target,'#')])]",
        namespaces=NS
    )
    return len(broken)


def process_file(f: Path, inplace: bool) -> tuple[int, int]:
    parser = etree.XMLParser(recover=True, huge_tree=True, remove_blank_text=False)
    tree = etree.parse(str(f), parser)

    c1 = pass_ref_note_to_note(tree)
    broken = pass_report_broken_note_targets(tree)

    if c1:
        out = f if inplace else f.with_suffix(f.suffix + ".notes.xml")
        if inplace:
            bak = f.with_suffix(f.suffix + ".bak")
            if not bak.exists():
                bak.write_bytes(f.read_bytes())
        tree.write(str(out), encoding="utf-8", xml_declaration=True, pretty_print=False)

    return c1, broken


def main():
    if len(sys.argv) < 2:
        print("Usage: python notes_pipeline.py <xml_file_or_folder> [--inplace]")
        sys.exit(1)

    target = Path(sys.argv[1]).expanduser().resolve()
    inplace = ("--inplace" in sys.argv[2:])

    files = iter_xml_files(target)
    if not files:
        print("[ERROR] No XML files found.")
        sys.exit(2)

    total_conv = 0
    total_broken = 0
    changed_files = 0

    for f in files:
        conv, broken = process_file(f, inplace=inplace)
        total_conv += conv
        total_broken += broken
        if conv:
            changed_files += 1

        print(f"[FILE] {f.name} | ref(type=note)->note={conv} | broken_note_targets={broken}")

    print(
        "\n=== SUMMARY ===\n"
        f"Files scanned: {len(files)}\n"
        f"Files changed: {changed_files}\n"
        f"Total ref(type=note) converted: {total_conv}\n"
        f"Total broken note targets (report only): {total_broken}\n"
    )


if __name__ == "__main__":
    main()
