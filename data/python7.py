#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re
import sys
from pathlib import Path
from lxml import etree

TEI_NS = "http://www.tei-c.org/ns/1.0"
NS = {"tei": TEI_NS}


# -----------------------------
# Utils
# -----------------------------

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
    """
    Sigle court (par sécurité) : 1–4 alphanum.
    (A, B, a, b, A1...) ; élargis si besoin.
    """
    s = norm(s)
    return bool(re.fullmatch(r"[A-Za-z0-9]{1,4}", s))


def clean_tail_after_siglum(tail: str) -> str:
    """
    Après suppression d'un <hi> sigle, on "lisse" la ponctuation.
    """
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


def element_children(el):
    return [ch for ch in el if isinstance(ch.tag, str)]


# -----------------------------
# Passes
# -----------------------------

def pass0_count_indique_literal(tree) -> int:
    # log seulement (ne modifie rien)
    return int(tree.xpath(
        "count(.//tei:listWit[@type='indiqué']//tei:witness[translate(@n,'indique','INDIQUE')='INDIQUE'])",
        namespaces=NS
    ))


def pass1_remove_n_in_indique(tree) -> int:
    """
    Règle validée : dans <listWit type="indiqué">, AUCUN <witness> ne doit porter @n.
    On supprime donc tous les @n existants dans ce contexte (D, a/b/c, INDIQUE, etc.).
    """
    changed = 0
    for w in tree.xpath("//tei:listWit[@type='indiqué']//tei:witness[@n]", namespaces=NS):
        del w.attrib["n"]
        changed += 1
    return changed


def pass2_fill_n_from_hi_except_indique(tree) -> int:
    """
    Remplit @n depuis un <hi rend="i">SIGLE</hi> UNIQUEMENT si:
    - le witness n'est PAS dans un listWit[@type='indiqué']
    - le hi est le 1er enfant élément du witness
    - le hi ressemble à un sigle court (1-4 alphanum)
    """
    changed = 0
    for w in tree.xpath(
        "//tei:witness[not(@n) and not(ancestor::tei:listWit[@type='indiqué'])]",
        namespaces=NS
    ):
        ch = first_element_child(w)
        if ch is None:
            continue
        q = etree.QName(ch)
        if q.namespace != TEI_NS or q.localname != "hi":
            continue
        if ch.get("rend") not in (None, "i"):
            continue

        hi_txt = "".join(ch.itertext()).strip()
        if not looks_like_siglum(hi_txt):
            continue

        w.set("n", norm(hi_txt))
        changed += 1

    return changed


def pass3_fill_n_original_singleton(tree) -> int:
    """
    Si listWit[@type='original'] a un witness unique sans @n -> n="A"
    (convention inchangée)
    """
    changed = 0
    for lw in tree.xpath("//tei:listWit[@type='original']", namespaces=NS):
        ws = lw.xpath("./tei:witness", namespaces=NS)
        if len(ws) != 1:
            continue
        w = ws[0]
        if w.get("n") is not None:
            continue
        w.set("n", "A")
        changed += 1
    return changed


def pass4_patch_voir_charte_except_indique(tree) -> int:
    """
    Transforme <witness>Voir charte 44.</witness>
    en <witness n="RENVOI_0044">Voir charte <ref target="#PREFIX_0044">44</ref>.</witness>
    si la cible existe dans le document.

    IMPORTANT: on n'applique PAS dans les indiqués (car aucun @n autorisé).
    """
    changed = 0
    for w in tree.xpath(
        "//tei:witness[not(@n) and not(ancestor::tei:listWit[@type='indiqué'])]",
        namespaces=NS
    ):
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
            continue

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


def pass5_remove_redundant_hi_siglum_except_indique(tree) -> int:
    """
    Supprime <hi rend='i'>X</hi> redondant avec @n (hors indiqués),
    dans 2 cas:
      A) 1er enfant élément du witness = <hi>
      B) 1er enfant élément = <pb> et 2e = <hi>

    Sécurité:
    - on ne supprime QUE si le hi est un sigle court (1–4 alphanum)
    - on ne touche pas si du texte non-vide précède
    - on ne touche pas si pb.tail a du texte non-vide avant le hi (cas b)
    """
    changed = 0

    for w in tree.xpath(
        "//tei:witness[@n and not(ancestor::tei:listWit[@type='indiqué'])]",
        namespaces=NS
    ):
        n = norm(w.get("n") or "")
        if not n:
            continue

        kids = element_children(w)
        if not kids:
            continue

        target_hi = None
        mode = None  # "A" or "B"
        pb_el = None

        # Case A: hi is first element child
        q1 = etree.QName(kids[0])
        if q1.namespace == TEI_NS and q1.localname == "hi":
            target_hi = kids[0]
            mode = "A"
            # refuse if text before hi
            if (w.text or "").strip():
                continue

        # Case B: pb then hi
        elif q1.namespace == TEI_NS and q1.localname == "pb" and len(kids) >= 2:
            pb_el = kids[0]
            q2 = etree.QName(kids[1])
            if q2.namespace == TEI_NS and q2.localname == "hi":
                target_hi = kids[1]
                mode = "B"
                # refuse if text before pb
                if (w.text or "").strip():
                    continue
                # refuse if pb.tail has significant text before hi
                if (pb_el.tail or "").strip():
                    continue

        if target_hi is None:
            continue

        if target_hi.get("rend") not in (None, "i"):
            continue

        hi_txt = norm("".join(target_hi.itertext()))
        # sécurité: sigle court uniquement
        if not looks_like_siglum(hi_txt):
            continue

        if hi_txt.lower() != n.lower():
            continue

        # remove and stitch tail
        tail = target_hi.tail or ""
        stitched = clean_tail_after_siglum(tail)

        if mode == "A":
            w.text = (w.text or "") + stitched
        else:
            # mode B: stitch onto pb.tail
            pb_el.tail = (pb_el.tail or "") + stitched

        w.remove(target_hi)
        changed += 1

    return changed


# -----------------------------
# IO / driver
# -----------------------------

def process_file(f: Path, inplace: bool) -> int:
    parser = etree.XMLParser(recover=True, huge_tree=True, remove_blank_text=False)
    tree = etree.parse(str(f), parser)

    c_indique_literal = pass0_count_indique_literal(tree)

    # 1) Règle Olivier: purge @n dans indiqués
    c0 = pass1_remove_n_in_indique(tree)

    # 2) Normalisations hors indiqués
    c1 = pass2_fill_n_from_hi_except_indique(tree)
    c2 = pass3_fill_n_original_singleton(tree)
    c3 = 0  # plus de a/b/c automatiques dans les indiqués
    c4 = pass4_patch_voir_charte_except_indique(tree)

    # 3) Nettoyage redondance @n + hi (inclut cas pb + hi)
    c5 = pass5_remove_redundant_hi_siglum_except_indique(tree)

    total = c0 + c1 + c2 + c3 + c4 + c5
    if total:
        out = f if inplace else f.with_suffix(f.suffix + ".cleaned.xml")
        if inplace:
            bak = f.with_suffix(f.suffix + ".bak")
            if not bak.exists():
                bak.write_bytes(f.read_bytes())
        tree.write(str(out), encoding="utf-8", xml_declaration=True, pretty_print=False)

    warn = f" | WARNING n='INDIQUE'={c_indique_literal}" if c_indique_literal else ""
    print(
        f"[FILE] {f.name}"
        f" | rm_n_in_indiqué={c0}"
        f" | from_hi(except_indiqué)={c1}"
        f" | original->A={c2}"
        f" | indiqué->a/b/...={c3}"
        f" | voir_charte(except_indiqué)={c4}"
        f" | rm_redundant_hi_siglum(except_indiqué)={c5}"
        f" | total={total}"
        f"{warn}"
    )
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

    print(
        f"\n=== SUMMARY ===\n"
        f"Files scanned: {len(files)}\n"
        f"Files changed: {changed_files}\n"
        f"Total edits: {total_edits}\n"
        f"Note: any @n inside listWit[@type='indiqué'] are removed. "
        f"Redundant sigle <hi> are removed only when they match @n and are short (1-4 chars), "
        f"including the 'pb then hi' case."
    )


if __name__ == "__main__":
    main()
