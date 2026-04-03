#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, time, csv
from pathlib import Path
from lxml import etree

TEI_NS = "http://www.tei-c.org/ns/1.0"

NOTE_TAG = f"{{{TEI_NS}}}note"
REF_TAG  = f"{{{TEI_NS}}}ref"
DIV_TAG  = f"{{{TEI_NS}}}div"
INDEX_TAG= f"{{{TEI_NS}}}index"
P_TAG    = f"{{{TEI_NS}}}p"
HEAD_TAG = f"{{{TEI_NS}}}head"
TABLE_TAG= f"{{{TEI_NS}}}table"
ROW_TAG  = f"{{{TEI_NS}}}row"
CELL_TAG = f"{{{TEI_NS}}}cell"
WITNESS_TAG = f"{{{TEI_NS}}}witness"
FRONT_TAG = f"{{{TEI_NS}}}front"
BODY_TAG  = f"{{{TEI_NS}}}body"
BACK_TAG  = f"{{{TEI_NS}}}back"

XML_ID = "{http://www.w3.org/XML/1998/namespace}id"

# ---------------------------
# Files: NO recursion
# ---------------------------
def iter_xml_files_non_recursive(p: Path):
    if p.is_file():
        return [p]
    return sorted([f for f in p.iterdir() if f.is_file() and f.suffix.lower() == ".xml"])

def has_ancestor_with(el, tag, attr=None, value=None):
    cur = el.getparent()
    while cur is not None:
        if cur.tag == tag:
            if attr is None:
                return True
            if cur.get(attr) == value:
                return True
        cur = cur.getparent()
    return False

def analyze_file_fast(xml_path: Path, recover: bool):
    parser = etree.XMLParser(recover=recover, huge_tree=True, remove_blank_text=False)
    tree = etree.parse(str(xml_path), parser)
    root = tree.getroot()

    # collect xml:id for target checks
    ids = set()
    for el in root.iter():
        xid = el.get(XML_ID)
        if xid:
            ids.add(xid)

    counts = {
        "note_total": 0,
        "note_front": 0,
        "note_body": 0,
        "note_back": 0,

        "note_tradition": 0,
        "note_index": 0,
        "note_in_p": 0,
        "note_in_head": 0,
        "note_in_table": 0,
        "note_in_row": 0,
        "note_in_cell": 0,
        "note_in_witness": 0,

        "note_no_attrs": 0,
        "note_with_rend": 0,
        "note_with_target": 0,
        "note_with_xmlid": 0,
        "note_target_broken": 0,

        "ref_type_note": 0,
        "ref_missing_target": 0,
        "ref_target_broken": 0,

        "note_back_with_xmlid_no_target": 0,
    }

    for el in root.iter():
        if el.tag == NOTE_TAG:
            counts["note_total"] += 1

            # position
            if has_ancestor_with(el, FRONT_TAG): counts["note_front"] += 1
            if has_ancestor_with(el, BODY_TAG):  counts["note_body"] += 1
            if has_ancestor_with(el, BACK_TAG):  counts["note_back"] += 1

            # contexts
            if has_ancestor_with(el, DIV_TAG, "type", "tradition"): counts["note_tradition"] += 1
            if has_ancestor_with(el, INDEX_TAG): counts["note_index"] += 1
            if has_ancestor_with(el, P_TAG): counts["note_in_p"] += 1
            if has_ancestor_with(el, HEAD_TAG): counts["note_in_head"] += 1
            if has_ancestor_with(el, TABLE_TAG): counts["note_in_table"] += 1
            if has_ancestor_with(el, ROW_TAG): counts["note_in_row"] += 1
            if has_ancestor_with(el, CELL_TAG): counts["note_in_cell"] += 1
            if has_ancestor_with(el, WITNESS_TAG): counts["note_in_witness"] += 1

            # attrs
            if len(el.attrib) == 0: counts["note_no_attrs"] += 1
            if "rend" in el.attrib: counts["note_with_rend"] += 1
            if "target" in el.attrib: counts["note_with_target"] += 1
            if el.get(XML_ID): counts["note_with_xmlid"] += 1

            # broken note@target
            tgt = el.get("target")
            if tgt and tgt.startswith("#") and tgt[1:] not in ids:
                counts["note_target_broken"] += 1

            # back note with xml:id no target
            if has_ancestor_with(el, BACK_TAG) and el.get(XML_ID) and "target" not in el.attrib:
                counts["note_back_with_xmlid_no_target"] += 1

        elif el.tag == REF_TAG:
            if el.get("type") == "note":
                counts["ref_type_note"] += 1

            if "target" not in el.attrib:
                counts["ref_missing_target"] += 1
            else:
                tgt = el.get("target")
                if tgt and tgt.startswith("#") and tgt[1:] not in ids:
                    counts["ref_target_broken"] += 1

    return counts

def main():
    if len(sys.argv) < 2:
        print("Usage: python notes_audit_fast_norec.py <xml_dir_or_file> [--out notes_audit.csv] [--recover]")
        sys.exit(1)

    target = Path(sys.argv[1]).expanduser().resolve()
    out = Path("notes_audit.csv")
    if "--out" in sys.argv:
        i = sys.argv.index("--out")
        if i + 1 < len(sys.argv):
            out = Path(sys.argv[i + 1])

    recover = ("--recover" in sys.argv)

    files = iter_xml_files_non_recursive(target)
    if not files:
        print(f"[ERROR] No XML files found in: {target}")
        sys.exit(2)

    print(f"[START] Found {len(files)} XML files (non-recursive). recover={recover}")

    rows = []
    errors = 0
    t0 = time.time()

    for idx, f in enumerate(files, start=1):
        print(f"[{idx}/{len(files)}] START {f.name}")
        t_file = time.time()
        try:
            stats = analyze_file_fast(f, recover=recover)
            dt = time.time() - t_file
            print(f"[{idx}/{len(files)}] OK {f.name} | notes={stats['note_total']} | rend={stats['note_with_rend']} | brokenTargets={stats['note_target_broken']} | {dt:.1f}s")
            rows.append({"file": f.name, "path": str(f), "status": "OK", "error": "", **stats})
        except Exception as e:
            errors += 1
            dt = time.time() - t_file
            print(f"[{idx}/{len(files)}] ERROR {f.name} | {type(e).__name__}: {e} | {dt:.1f}s")
            rows.append({"file": f.name, "path": str(f), "status": "ERROR", "error": f"{type(e).__name__}: {e}"})

    # write CSV
    keys = set()
    for r in rows:
        keys |= set(r.keys())
    base = ["file", "path", "status", "error"]
    fieldnames = base + sorted([k for k in keys if k not in base])

    with out.open("w", newline="", encoding="utf-8") as fp:
        w = csv.DictWriter(fp, fieldnames=fieldnames)
        w.writeheader()
        w.writerows(rows)

    print(f"[DONE] Wrote CSV: {out.resolve()}")
    print(f"[SUMMARY] files={len(files)} | ok={len(files)-errors} | errors={errors} | total_time={time.time()-t0:.1f}s")

if __name__ == "__main__":
    main()
