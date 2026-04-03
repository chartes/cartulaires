#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
from pathlib import Path
from lxml import etree

TEI_NS = "http://www.tei-c.org/ns/1.0"
NS = {"tei": TEI_NS}


def iter_xml_files(p: Path):
    return [p] if p.is_file() else list(p.rglob("*.xml"))


def relpath_under_input(file_path: Path, input_root: Path) -> Path:
    if input_root.is_dir():
        return file_path.relative_to(input_root)
    return Path(file_path.name)


def ensure_parent_dir(p: Path):
    p.parent.mkdir(parents=True, exist_ok=True)


def purge_n_in_indique(tree: etree._ElementTree) -> int:
    """
    Dans <listWit type="indiqué">, supprime tous les @n portés par <witness>.
    """
    changed = 0
    for w in tree.xpath("//tei:listWit[@type='indiqué']//tei:witness[@n]", namespaces=NS):
        del w.attrib["n"]
        changed += 1
    return changed


def process_file(src: Path, input_root: Path, outdir: Path) -> int:
    parser = etree.XMLParser(recover=True, huge_tree=True, remove_blank_text=False)
    tree = etree.parse(str(src), parser)

    edits = purge_n_in_indique(tree)

    rel = relpath_under_input(src, input_root)
    dst = outdir / rel
    ensure_parent_dir(dst)

    # On écrit toujours un fichier de sortie (modifié ou non), pour avoir un miroir complet.
    tree.write(str(dst), encoding="utf-8", xml_declaration=True, pretty_print=False)

    print(f"[FILE] {src.name} | rm_n_in_indiqué={edits} | out={dst}")
    return edits


def main():
    if len(sys.argv) < 2:
        print("Usage: python purge_indique_n.py <xml_file_or_folder> [--outdir OUT]")
        sys.exit(1)

    target = Path(sys.argv[1]).expanduser().resolve()

    outdir = None
    args = sys.argv[2:]
    if "--outdir" in args:
        i = args.index("--outdir")
        if i + 1 >= len(args):
            print("[ERROR] --outdir requires a path")
            sys.exit(2)
        outdir = Path(args[i + 1]).expanduser().resolve()
    else:
        outdir = Path.cwd() / "out_purge_indique_n"

    outdir.mkdir(parents=True, exist_ok=True)

    files = iter_xml_files(target)
    if not files:
        print("[ERROR] No XML files found.")
        sys.exit(2)

    input_root = target if target.is_dir() else target.parent

    changed_files = 0
    total_edits = 0

    for f in files:
        edits = process_file(f, input_root=input_root, outdir=outdir)
        total_edits += edits
        if edits:
            changed_files += 1

    print(
        f"\n=== SUMMARY ===\n"
        f"Input: {target}\n"
        f"Output dir: {outdir}\n"
        f"Files scanned: {len(files)}\n"
        f"Files changed (>=1 edit): {changed_files}\n"
        f"Total @n removed: {total_edits}\n"
    )


if __name__ == "__main__":
    main()
