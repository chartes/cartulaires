#!/usr/bin/env python3
"""
inline_notes.py
===============
Pour chaque fichier XML du corpus, remplace les <ref type="note" target="#nXXX"/>
par le contenu de la <note xml:id="nXXX"> correspondante, inliné à la place du ref.

Règles :
- Chaque <ref type="note"> est remplacé par <note> avec le contenu de la note cible
- Les attributs n= et xml:id= viennent du <ref> (pas de la note source)
- La note source originale est conservée telle quelle
- Fonctionne aussi pour les doublons (même note inlinée plusieurs fois)

Usage : python3 inline_notes.py [dossier_xml] [dossier_output]
"""

import re, os, sys, glob
from collections import Counter

INPUT_DIR  = sys.argv[1] if len(sys.argv) > 1 else "/home/claude"
OUTPUT_DIR = sys.argv[2] if len(sys.argv) > 2 else "/mnt/user-data/outputs/inlined"

REF_RE = re.compile(r'<ref type="note"([^>]*)/>') 
NOTE_DEF_RE = re.compile(r'<note\b([^>]*)>(.*?)</note>', re.DOTALL)

def parse_attr(attrs, name):
    m = re.search(rf'\b{name}="([^"]*)"', attrs)
    return m.group(1).strip() if m else None

def build_note_map(xml):
    """Construit un dict xml:id → (attrs_bruts, contenu_interne)."""
    note_map = {}
    for m in NOTE_DEF_RE.finditer(xml):
        attrs = m.group(1)
        xmlid = parse_attr(attrs, "xml:id")
        if xmlid:
            note_map[xmlid] = (attrs, m.group(2))
    return note_map

def convert_file(xml_path, out_path):
    with open(xml_path, encoding="utf-8", errors="replace") as f:
        xml = f.read()

    note_map = build_note_map(xml)
    refs = list(REF_RE.finditer(xml))

    if not note_map or not refs:
        with open(out_path, "w", encoding="utf-8") as f:
            f.write(xml)
        return 0, 0, [], {}

    n_converted = 0
    n_not_found = 0
    not_found_list = []
    target_counts = Counter()

    new_xml = xml
    for m in reversed(refs):
        ref_attrs = m.group(1)
        target_raw = parse_attr(ref_attrs, "target") or ""
        # Peut contenir plusieurs targets : "#na001 #na002"
        targets = [t.lstrip("#").strip() for t in target_raw.split() if t.startswith("#")]

        # Chercher la première target qui existe dans note_map
        found_target = None
        found_content = None
        for t in targets:
            if t in note_map:
                found_target = t
                _, found_content = note_map[t]
                break

        if not found_target:
            n_not_found += 1
            not_found_list.append(target_raw.strip() or "?")
            continue

        target_counts[found_target] += 1

        # Si plusieurs targets → inliner toutes celles qui existent, concaténées
        all_contents = []
        for t in targets:
            if t in note_map:
                all_contents.append(note_map[t][1])

        combined_content = "".join(all_contents)
        full_target = " ".join(f"#{t}" for t in targets)

        n_val     = parse_attr(ref_attrs, "n")
        xmlid_val = parse_attr(ref_attrs, "xml:id")

        new_attrs = ' type="note"'
        if n_val:     new_attrs += f' n="{n_val}"'
        new_attrs += f' target="{full_target}"'
        if xmlid_val: new_attrs += f' xml:id="{xmlid_val}"'

        replacement = f'<note{new_attrs}>{combined_content}</note>'
        new_xml = new_xml[:m.start()] + replacement + new_xml[m.end():]
        n_converted += 1

    with open(out_path, "w", encoding="utf-8") as f:
        f.write(new_xml)

    duplicates = {t: c for t, c in target_counts.items() if c > 1}
    return n_converted, n_not_found, not_found_list, duplicates


# ── MAIN ─────────────────────────────────────────────────────────
os.makedirs(OUTPUT_DIR, exist_ok=True)

xml_files = sorted(glob.glob(os.path.join(INPUT_DIR, "*.xml")))
if not xml_files:
    print(f"Aucun fichier XML trouvé dans {INPUT_DIR}")
    sys.exit(1)

print(f"{'='*60}")
print(f"Inlining <ref type='note'> → <note> — {len(xml_files)} fichiers")
print(f"Output : {OUTPUT_DIR}")
print(f"{'='*60}\n")

total_converted = 0
total_not_found = 0

for xml_path in xml_files:
    fname = os.path.basename(xml_path)
    out_path = os.path.join(OUTPUT_DIR, fname)
    result = convert_file(xml_path, out_path)

    if len(result) == 2:
        # Pas de refs ni notes
        print(f"[{fname}] → OK (aucun ref type=note)")
        continue

    n_conv, n_nf, nf_list, dupes = result

    if n_conv == 0 and n_nf == 0:
        print(f"[{fname}] → OK (aucun ref type=note)")
        continue

    status = f"{n_conv} convertis"
    if n_nf:    status += f", {n_nf} non trouvés"
    if dupes:   status += f", {len(dupes)} notes dupliquées"
    print(f"[{fname}] → {status}")

    if dupes:
        for t, c in sorted(dupes.items()):
            print(f"  DUPLICATE x{c} : #{t}")
    if nf_list:
        for t in nf_list:
            print(f"  NOT FOUND : #{t}")

    total_converted += n_conv
    total_not_found += n_nf

print(f"\n{'='*60}")
print(f"TOTAL : {total_converted} refs convertis, {total_not_found} non résolus")
print(f"Fichiers dans : {OUTPUT_DIR}")
