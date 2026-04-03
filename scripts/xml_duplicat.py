#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import re
import hashlib
from pathlib import Path
from lxml import etree

TEI_NS = "http://www.tei-c.org/ns/1.0"
XML_ID = "{http://www.w3.org/XML/1998/namespace}id"

TEI_REF  = f"{{{TEI_NS}}}ref"
TEI_NOTE = f"{{{TEI_NS}}}note"

NCNAME_SAFE_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9._-]*$")

def normalize_xmlid(xid: str) -> str:
    """
    Transforme en NCName safe:
      - remplace tout char interdit par "_"
      - préfixe si commence par chiffre / '.' / '-'
    """
    new = re.sub(r"[^A-Za-z0-9._-]", "_", xid)
    if not new or new[0].isdigit() or new[0] in ".-":
        new = "id_" + new
    return new

def trim_targets(root):
    trimmed = 0
    for el in root.iter():
        tgt = el.get("target")
        if tgt is not None:
            new = tgt.strip()
            if new != tgt:
                el.set("target", new)
                trimmed += 1
    return trimmed

def update_targets(root, old_id: str, new_id: str):
    old = f"#{old_id}"
    new = f"#{new_id}"
    for el in root.iter():
        tgt = el.get("target")
        if tgt == old:
            el.set("target", new)

def fingerprint_node(el):
    """
    Empreinte stable pour dédupliquer notes identiques:
    tag + attrs (sans xml:id) + texte + sérialisation enfants
    """
    attrs = {k: v for k, v in el.attrib.items() if k != XML_ID}
    attrs_items = tuple(sorted(attrs.items()))
    kids = b"".join([etree.tostring(c, with_tail=True) for c in el])
    text = (el.text or "").strip()
    tail = (el.tail or "").strip()
    data = (el.tag, attrs_items, text, tail, kids)
    return hashlib.sha256(repr(data).encode("utf-8")).hexdigest()

def main():
    if len(sys.argv) < 2:
        print("Usage: python fix_one_xml.py <input.xml> [output.xml]")
        sys.exit(1)

    in_path = Path(sys.argv[1]).expanduser().resolve()
    out_path = (
        Path(sys.argv[2]).expanduser().resolve()
        if len(sys.argv) >= 3
        else in_path.with_suffix(".fixed.xml")
    )

    # parse en mode recover pour ne pas bloquer sur certains soucis (hors xml:id invalides)
    parser = etree.XMLParser(recover=True, huge_tree=True, remove_blank_text=False)
    tree = etree.parse(str(in_path), parser)
    root = tree.getroot()

    # 1) trim des target (espaces parasites)
    trimmed_targets = trim_targets(root)

    # 2) Normaliser tous les xml:id invalides -> mapping old->new
    id_map = {}
    for el in root.iter():
        xid = el.get(XML_ID)
        if not xid:
            continue
        if NCNAME_SAFE_RE.match(xid):
            continue
        new = normalize_xmlid(xid)
        # éviter collision si new existe déjà
        base = new
        k = 2
        while root.xpath(f"//*[@xml:id='{new}']"):
            new = f"{base}_{k}"
            k += 1
        el.set(XML_ID, new)
        id_map[xid] = new

    # mettre à jour les targets qui pointaient vers les anciens ids
    for old, new in id_map.items():
        update_targets(root, old, new)

    # 3) Supprimer xml:id sur ref[@type='note'] (évite collisions, recommandé)
    removed_ref_xmlid = 0
    for ref in root.iter(TEI_REF):
        if ref.get("type") == "note" and ref.get(XML_ID):
            del ref.attrib[XML_ID]
            removed_ref_xmlid += 1

    # 4) Dédupliquer notes identiques qui partagent le même xml:id
    # Rebuild mapping xml:id -> notes
    notes_by_id = {}
    for note in root.iter(TEI_NOTE):
        xid = note.get(XML_ID)
        if xid:
            notes_by_id.setdefault(xid, []).append(note)

    removed_dup_notes = 0
    renamed_notes = 0

    for xid, notes in list(notes_by_id.items()):
        if len(notes) <= 1:
            continue

        fps = [fingerprint_node(n) for n in notes]
        if len(set(fps)) == 1:
            # toutes identiques: garder la 1ère
            for n in notes[1:]:
                parent = n.getparent()
                if parent is not None:
                    parent.remove(n)
                    removed_dup_notes += 1
        else:
            # différentes: renommer les doublons (et update target)
            for i, n in enumerate(notes[1:], start=2):
                new_id = f"{xid}_{i}"
                base = new_id
                k = 2
                while root.xpath(f"//*[@xml:id='{new_id}']"):
                    new_id = f"{base}_{k}"
                    k += 1
                n.set(XML_ID, new_id)
                update_targets(root, xid, new_id)
                renamed_notes += 1

    # 5) Vérif: xml:id dupliqués restants (global)
    seen = {}
    dup_ids = []
    for el in root.iter():
        xid = el.get(XML_ID)
        if not xid:
            continue
        seen[xid] = seen.get(xid, 0) + 1
    for xid, c in seen.items():
        if c > 1:
            dup_ids.append(xid)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    tree.write(str(out_path), encoding="utf-8", xml_declaration=True, pretty_print=True)

    print("Input :", in_path)
    print("Output:", out_path)
    print("Trimmed target attrs:", trimmed_targets)
    print("Renamed invalid xml:id:", len(id_map))
    if id_map:
        # affiche un échantillon
        sample = list(id_map.items())[:10]
        print("  sample renames:", sample)
    print("Removed xml:id from ref[@type='note']:", removed_ref_xmlid)
    print("Removed duplicate identical <note>:", removed_dup_notes)
    print("Renamed duplicate <note> ids:", renamed_notes)
    print("Remaining duplicated xml:id groups:", len(dup_ids))
    if dup_ids:
        print("  remaining dup ids sample:", dup_ids[:20])

if __name__ == "__main__":
    main()
