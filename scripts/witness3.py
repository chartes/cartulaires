#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Audit witness/@n vs premier <hi>.

Tu as décrit le pattern :
<witness n="A"><hi rend="i">A</hi> ... du texte ... <hi rend="i">Title</hi> ...</witness>

Objectif :
- Compter les witnesses QUI ONT @n et AU MOINS UN <hi>
- Comparer @n avec le texte du "premier hi"
- Identifier les cas où ça ne rentre pas, et pourquoi

Définitions utilisées :
- "first_hi_mode=first_child" : on prend le 1er ENFANT ÉLÉMENT du witness, s’il est un <hi>
- "first_hi_mode=first_hi"    : sinon on prend le premier <hi> enfant direct (./tei:hi[1]) s’il existe
Tu peux choisir avec --mode first_child (par défaut) ou --mode first_hi

Sorties :
- witness_hi_n_by_file.csv
- witness_hi_n_details.csv

Usage :
  python audit_witness_hi_vs_n.py <xml_file_or_folder> [--mode first_child|first_hi]
"""

import csv
import re
import sys
from pathlib import Path
from collections import Counter, defaultdict
from lxml import etree

TEI_NS = "http://www.tei-c.org/ns/1.0"
NS = {"tei": TEI_NS}

WS_RE = re.compile(r"\s+")


def iter_xml_files(p: Path):
    return [p] if p.is_file() else list(p.rglob("*.xml"))


def norm_ws(s: str) -> str:
    return WS_RE.sub(" ", (s or "")).strip()


def first_element_child(el):
    for ch in el:
        if isinstance(ch.tag, str):
            return ch
    return None


def is_tei(el) -> bool:
    return isinstance(el.tag, str) and etree.QName(el).namespace == TEI_NS


def localname(el) -> str:
    return etree.QName(el).localname if is_tei(el) else ""


def get_first_hi_text(witness, mode: str) -> tuple[str, str]:
    """
    Retourne (hi_text, hi_kind)
    hi_kind ∈ {"first_child", "first_hi", "none"}
    """
    if mode == "first_child":
        ch = first_element_child(witness)
        if ch is not None and is_tei(ch) and localname(ch) == "hi":
            return norm_ws("".join(ch.itertext())), "first_child"

    # fallback / ou mode explicit first_hi
    hi = witness.xpath("./tei:hi[1]", namespaces=NS)
    if hi:
        return norm_ws("".join(hi[0].itertext())), "first_hi"

    return "", "none"


def act_xmlid(w) -> str:
    return w.xpath("string(ancestor::*[@xml:id][1]/@xml:id)", namespaces=NS) or ""


def listwit_type(w) -> str:
    return w.xpath("string(ancestor::tei:listWit[1]/@type)", namespaces=NS) or ""


def safe_parse(path: Path):
    try:
        parser = etree.XMLParser(recover=True, huge_tree=True, remove_blank_text=False)
        tree = etree.parse(str(path), parser)
        return tree, ""
    except Exception as e:
        return None, f"{type(e).__name__}: {e}"


def process_file(path: Path, mode: str):
    tree, err = safe_parse(path)
    if tree is None:
        return {
            "file": path.name,
            "path": str(path),
            "parse_error": err,
            "by_file": None,
            "details": [],
        }

    # périmètre: witness[@n] ayant au moins un <hi> (descendant)
    witnesses = tree.xpath("//tei:witness[@n][.//tei:hi]", namespaces=NS)

    counts = Counter()
    details = []

    for w in witnesses:
        n_val = norm_ws(w.get("n") or "")
        hi_txt, hi_kind = get_first_hi_text(w, mode=mode)

        # catégorisation
        if hi_kind == "none":
            category = "HAS_HI_BUT_NO_DIRECT_HI"  # hi existe en descendant mais pas enfant direct
        elif not hi_txt:
            category = "FIRST_HI_EMPTY"
        elif n_val.lower() == hi_txt.lower():
            category = "MATCH"
        else:
            category = "MISMATCH"

        counts[category] += 1

        snippet = norm_ws(" ".join("".join(w.itertext()).split()))
        if len(snippet) > 220:
            snippet = snippet[:220] + "…"

        details.append({
            "file": path.name,
            "line": getattr(w, "sourceline", "") or "",
            "act_xmlid": act_xmlid(w),
            "listWit_type": listwit_type(w),
            "n": n_val,
            "first_hi_text": hi_txt,
            "first_hi_kind": hi_kind,
            "category": category,
            "snippet": snippet,
            "path": str(path),
        })

    by_file = {
        "file": path.name,
        "total_witness_n_with_hi": len(witnesses),
        "match": counts["MATCH"],
        "mismatch": counts["MISMATCH"],
        "first_hi_empty": counts["FIRST_HI_EMPTY"],
        "has_hi_but_no_direct_hi": counts["HAS_HI_BUT_NO_DIRECT_HI"],
        "parse_error": "",
        "path": str(path),
    }

    return {"file": path.name, "path": str(path), "parse_error": "", "by_file": by_file, "details": details}


def write_csv(rows, out_path: Path, fieldnames):
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        for r in rows:
            w.writerow(r)


def main():
    if len(sys.argv) < 2:
        print("Usage: python audit_witness_hi_vs_n.py <xml_file_or_folder> [--mode first_child|first_hi] "
              "[--byfile out_by_file.csv] [--details out_details.csv]")
        sys.exit(1)

    target = Path(sys.argv[1]).expanduser().resolve()

    mode = "first_child"
    out_byfile = Path.cwd() / "witness_hi_n_by_file.csv"
    out_details = Path.cwd() / "witness_hi_n_details.csv"

    args = sys.argv[2:]
    if "--mode" in args:
        i = args.index("--mode")
        mode = args[i + 1].strip()
        if mode not in ("first_child", "first_hi"):
            print("[ERROR] --mode must be 'first_child' or 'first_hi'")
            sys.exit(2)

    if "--byfile" in args:
        i = args.index("--byfile")
        out_byfile = Path(args[i + 1]).expanduser().resolve()

    if "--details" in args:
        i = args.index("--details")
        out_details = Path(args[i + 1]).expanduser().resolve()

    files = iter_xml_files(target)
    if not files:
        print("[ERROR] No XML files found.")
        sys.exit(2)

    byfile_rows = []
    detail_rows = []
    parse_errors = 0

    for f in files:
        res = process_file(f, mode=mode)
        if res["parse_error"]:
            parse_errors += 1
            byfile_rows.append({
                "file": res["file"],
                "total_witness_n_with_hi": "",
                "match": "",
                "mismatch": "",
                "first_hi_empty": "",
                "has_hi_but_no_direct_hi": "",
                "parse_error": res["parse_error"],
                "path": res["path"],
            })
            continue

        if res["by_file"]["total_witness_n_with_hi"] > 0:
            byfile_rows.append(res["by_file"])
            detail_rows.extend(res["details"])

    # Tri
    byfile_rows.sort(key=lambda r: (-int(r["mismatch"] or 0), -int(r["total_witness_n_with_hi"] or 0), r["file"].lower()))

    write_csv(
        byfile_rows,
        out_byfile,
        fieldnames=[
            "file",
            "total_witness_n_with_hi",
            "match",
            "mismatch",
            "first_hi_empty",
            "has_hi_but_no_direct_hi",
            "parse_error",
            "path",
        ],
    )

    write_csv(
        detail_rows,
        out_details,
        fieldnames=[
            "file", "line", "act_xmlid", "listWit_type",
            "n", "first_hi_text", "first_hi_kind", "category",
            "snippet", "path",
        ],
    )

    # Console summary
    total = sum(int(r["total_witness_n_with_hi"] or 0) for r in byfile_rows)
    mism = sum(int(r["mismatch"] or 0) for r in byfile_rows)
    match = sum(int(r["match"] or 0) for r in byfile_rows)

    print(f"[OK] Mode: {mode}")
    print(f"[OK] Files scanned: {len(files)} (parse errors: {parse_errors})")
    print(f"[OK] Witness[@n] with some <hi>: {total}")
    print(f"[OK] MATCH: {match} | MISMATCH: {mism}")
    print(f"[OK] CSV by file: {out_byfile}")
    print(f"[OK] CSV details: {out_details}")

    print("\n=== FILES WITH MISMATCHES ===")
    for r in byfile_rows:
        if int(r["mismatch"] or 0) > 0:
            print(f"- {r['file']}: mismatch={r['mismatch']} / total={r['total_witness_n_with_hi']}")


if __name__ == "__main__":
    main()
