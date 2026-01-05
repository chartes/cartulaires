#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re
import sys
from pathlib import Path
from lxml import etree

TEI_NS = "http://www.tei-c.org/ns/1.0"
NS = {"tei": TEI_NS}

def iter_xml_files(p: Path):
    return [p] if p.is_file() else list(p.rglob("*.xml"))

def first_element_child(el):
    for ch in el:
        if isinstance(ch.tag, str):
            return ch
    return None

def norm(s: str) -> str:
    s = re.sub(r"\s+", " ", (s or "")).strip()
    s = re.sub(r"^[\(\[\{]+", "", s)
    s = re.sub(r"[\)\]\}\s]+$", "", s)
    return s

def looks_like_siglum(s: str) -> bool:
    s = norm(s)
    # Ajuste si besoin: ici on accepte 1-4 caractères alphanum simples (A, B, a, b, A1...)
    return bool(re.fullmatch(r"[A-Za-z0-9]{1,4}", s))

def clean_tail_after_siglum(tail: str) -> str:
    if not tail:
        return ""
    tail = re.sub(r"^\s*[\.\:]\s*", " ", tail)
    tail = re.sub(r"^\s*[-–—]\s*", " ", tail)
    tail = re.sub(r"^\s+", " ", tail)
    return tail

def find_act_prefix_from_context(el):
    ctx = el.xpath("ancestor::*[@xml:id][1]/@xml:id", namespaces=NS)
    if not ctx:
        return None, None
    xmlid = ctx[0]
    if "_" in xmlid:
        prefix, num = xmlid.rsplit("_", 1)
        return prefix, num
    return xmlid, None

def pass1_fill_n_from_hi(tree):
    changed = 0
    for w in tree.xpath("//tei:witness[not(@n)]", namespaces=NS):
        hi = first_element_child(w)
        if hi is None:
            continue
        q = etree.QName(hi)
        if q.namespace != TEI_NS or q.localname != "hi":
            continue
        if hi.get("rend") not in (None, "i"):
            continue
        hi_txt = "".join(hi.itertext()).strip()
        if not looks_like_siglum(hi_txt):
            continue

        w.set("n", norm(hi_txt))
        changed += 1
    return changed

def pass1_fill_n_indique(tree):
    changed = 0
    for lw in tree.xpath("//tei:listWit[@type='indiqué']", namespaces=NS):
        missing = lw.xpath("./tei:witness[not(@n)]", namespaces=NS)
        if not missing:
            continue
        _, actnum = find_act_prefix_from_context(lw)
        actnum = actnum or "XXXX"
        for i, w in enumerate(missing, 1):
            w.set("n", f"IND_{actnum}_{i:04d}")
            changed += 1
    return changed

def pass1_patch_voir_charte(tree):
    changed = 0
    for w in tree.xpath("//tei:witness[not(@n)]", namespaces=NS):
        txt = " ".join("".join(w.itertext()).split())
        m = re.match(r"^Voir charte\s+(\d+)\.?\s*$", txt)
        if not m:
            continue
        num = int(m.group(1))
        padded = f"{num:04d}"

        prefix, _ = find_act_prefix_from_context(w)
        if not prefix:
            continue
        target_id = f"{prefix}_{padded}"

        if not tree.xpath(f"//*[@xml:id='{target_id}']", namespaces=NS):
            continue  # on ne touche pas si on ne peut pas résoudre

        # rewrite witness content
        for ch in list(w):
            w.remove(ch)
        w.text = "Voir charte "
        ref = etree.Element(f"{{{TEI_NS}}}ref")
        ref.set("target", f"#{target_id}")
        ref.text = str(num)
        w.append(ref)
        ref.tail = "."
        w.set("n", f"RENVOI_{padded}")
        changed += 1
    return changed

def pass2_remove_redundant_hi(tree):
    changed = 0
    for w in tree.xpath("//tei:witness[@n]", namespaces=NS):
        n = (w.get("n") or "").strip()
        if not n:
            continue
        hi = first_element_child(w)
        if hi is None:
            continue
        q = etree.QName(hi)
        if q.namespace != TEI_NS or q.localname != "hi":
            continue
        if hi.get("rend") not in (None, "i"):
            continue
        hi_txt = norm("".join(hi.itertext()))
        if hi_txt.lower() != norm(n).lower():
            continue
        # Safety: ne pas supprimer si texte significatif avant hi
        if (w.text or "").strip():
            continue

        # remove and stitch tail
        w.text = (w.text or "") + clean_tail_after_siglum(hi.tail or "")
        w.remove(hi)
        changed += 1
    return changed

def process_file(f: Path, inplace: bool):
    parser = etree.XMLParser(recover=True, huge_tree=True, remove_blank_text=False)
    tree = etree.parse(str(f), parser)

    c1 = pass1_fill_n_from_hi(tree)
    c2 = pass1_fill_n_indique(tree)
    c3 = pass1_patch_voir_charte(tree)
    c4 = pass2_remove_redundant_hi(tree)

    total = c1 + c2 + c3 + c4
    if total:
        out = f if inplace else f.with_suffix(f.suffix + ".cleaned.xml")
        if inplace:
            bak = f.with_suffix(f.suffix + ".bak")
            if not bak.exists():
                bak.write_bytes(f.read_bytes())
        tree.write(str(out), encoding="utf-8", xml_declaration=True, pretty_print=False)

    print(f"[FILE] {f.name} | fill@hi={c1} | fill@indique={c2} | voir_charte={c3} | rm_redundant_hi={c4} | total={total}")
    return total

def main():
    if len(sys.argv) < 2:
        print("Usage: python witness_pipeline.py <xml_file_or_folder> [--inplace]")
        sys.exit(1)
    target = Path(sys.argv[1]).expanduser().resolve()
    inplace = ("--inplace" in sys.argv[2:])

    files = iter_xml_files(target)
    if not files:
        print("[ERROR] No XML files found.")
        sys.exit(2)

    changed_files = 0
    total_edits = 0
    for f in files:
        edits = process_file(f, inplace=inplace)
        total_edits += edits
        if edits:
            changed_files += 1

    print(f"\n=== SUMMARY ===\nFiles scanned: {len(files)}\nFiles changed: {changed_files}\nTotal edits: {total_edits}")

if __name__ == "__main__":
    main()

