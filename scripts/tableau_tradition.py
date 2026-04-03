#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import csv
from pathlib import Path
from lxml import etree

TEI_NS = "http://www.tei-c.org/ns/1.0"
NS = {"tei": TEI_NS}
XML_ID = "{http://www.w3.org/XML/1998/namespace}id"

PARSER = etree.XMLParser(resolve_entities=False, huge_tree=True)

def iter_xml_files(input_path: Path, recursive: bool):
    if input_path.is_file():
        yield input_path
        return
    pattern = "**/*.xml" if recursive else "*.xml"
    for p in sorted(input_path.glob(pattern)):
        if p.is_file():
            yield p

def act_has_tradition(act_text: etree._Element) -> bool:
    # On considère "tableau de la tradition" = div@type='tradition' (en général dans front)
    return bool(act_text.xpath("./tei:front//tei:div[@type='tradition']", namespaces=NS))

def audit_file(path: Path) -> dict:
    tree = etree.parse(str(path), PARSER)
    root = tree.getroot()

    acts = root.xpath(".//tei:text[@subtype='article']", namespaces=NS)
    total = len(acts)

    missing_ids = []
    missing_count = 0
    has_count = 0

    for act in acts:
        if act_has_tradition(act):
            has_count += 1
        else:
            missing_count += 1
            missing_ids.append(act.get(XML_ID, ""))

    return {
        "file": str(path),
        "acts_total": total,
        "acts_with_tradition": has_count,
        "acts_missing_tradition": missing_count,
        "missing_act_xml_ids": " ".join([x for x in missing_ids if x])  # vide si pas d'xml:id
    }

def main():
    ap = argparse.ArgumentParser(description="Audit: détecte les fichiers/actes sans tableau de la tradition.")
    ap.add_argument("input", help="Dossier (ou fichier) XML à auditer")
    ap.add_argument("--recursive", action="store_true", help="Parcourt aussi les sous-dossiers")
    ap.add_argument("--csv", default="missing_tradition_report.csv", help="Chemin du CSV rapport")
    ap.add_argument("--only-missing", action="store_true", help="N'affiche que les fichiers où il manque quelque chose")
    args = ap.parse_args()

    in_path = Path(args.input)
    rows = []

    for f in iter_xml_files(in_path, args.recursive):
        try:
            r = audit_file(f)
            rows.append(r)

            if args.only_missing and r["acts_missing_tradition"] == 0:
                continue

            status = "MISSING" if r["acts_missing_tradition"] > 0 else "OK"
            print(
                f"[{status}] {Path(r['file']).name} | acts={r['acts_total']} | "
                f"with_trad={r['acts_with_tradition']} | missing={r['acts_missing_tradition']}"
            )
        except Exception as e:
            print(f"[ERROR] {f} | {e}")
            rows.append({
                "file": str(f),
                "acts_total": "",
                "acts_with_tradition": "",
                "acts_missing_tradition": "",
                "missing_act_xml_ids": "",
                "error": repr(e),
            })

    # write CSV
    csv_path = Path(args.csv)
    fieldnames = ["file", "acts_total", "acts_with_tradition", "acts_missing_tradition", "missing_act_xml_ids", "error"]
    with csv_path.open("w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=fieldnames)
        w.writeheader()
        for r in rows:
            if "error" not in r:
                r["error"] = ""
            w.writerow(r)

    print(f"\n[DONE] Rapport CSV: {csv_path}")

if __name__ == "__main__":
    main()
