#!/usr/bin/env python3
"""
inline_notes.py
===============

Tolere des XML imparfaits et remplace les <ref type="note" .../>
par des <note> inlinees, y compris si la note source est rangee
dans un autre acte.

Regles :
- resolution d'abord dans le meme scope logique (le <text xml:id> courant)
- si rien n'existe localement mais qu'une note existe ailleurs, on la copie
- target multiples : on fusionne toutes les cibles resolues
- si plusieurs cibles donnent le meme contenu, on ne garde qu'une copie
- les cas non resolus et les orphan note sont signales dans un rapport TSV

Usage : python inline_notes.py [dossier_xml] [dossier_output]
"""

import bisect
import glob
import os
import re
import sys
from collections import Counter, defaultdict

INPUT_DIR = sys.argv[1] if len(sys.argv) > 1 else "."
OUTPUT_DIR = sys.argv[2] if len(sys.argv) > 2 else "./inlined"

REF_RE = re.compile(r"<ref\b([^>]*)/>", re.DOTALL)
NOTE_DEF_RE = re.compile(r"<note\b([^>]*)>(.*?)</note>", re.DOTALL)
TEXT_START_RE = re.compile(r"<text\b([^>]*)>", re.DOTALL)
ATTR_RE = re.compile(r'\b([:\w-]+)="([^"]*)"')
WS_RE = re.compile(r"\s+")


def parse_attrs(attrs_raw):
    return {name: value.strip() for name, value in ATTR_RE.findall(attrs_raw)}


def parse_attr(attrs_raw, name):
    attrs = parse_attrs(attrs_raw)
    return attrs.get(name)


def parse_targets(target_raw):
    return [token.lstrip("#").strip() for token in target_raw.split() if token.startswith("#")]


def normalize_xml_space(text):
    return WS_RE.sub(" ", text).strip()


def build_scope_lookup(xml):
    starts = []
    scopes = []
    for match in TEXT_START_RE.finditer(xml):
        attrs = parse_attrs(match.group(1))
        scope_id = attrs.get("xml:id") or f"__TEXT_AT_{match.start()}"
        starts.append(match.start())
        scopes.append(scope_id)
    return starts, scopes


def scope_for_pos(pos, scope_starts, scope_ids):
    if not scope_starts:
        return "__FILE__"
    idx = bisect.bisect_right(scope_starts, pos) - 1
    return scope_ids[idx] if idx >= 0 else "__FILE__"


def build_note_indexes(xml):
    scope_starts, scope_ids = build_scope_lookup(xml)

    notes_by_scope_id = defaultdict(lambda: defaultdict(list))
    notes_by_scope_ref = defaultdict(lambda: defaultdict(list))
    global_note_scopes = defaultdict(set)
    global_notes_by_id = defaultdict(list)

    for match in NOTE_DEF_RE.finditer(xml):
        attrs_raw = match.group(1)
        attrs = parse_attrs(attrs_raw)
        xmlid = attrs.get("xml:id")
        if not xmlid:
            continue

        scope_id = scope_for_pos(match.start(), scope_starts, scope_ids)
        note = {
            "xmlid": xmlid,
            "n": attrs.get("n"),
            "target_raw": attrs.get("target", ""),
            "content": match.group(2),
            "scope_id": scope_id,
            "attrs_raw": attrs_raw,
            "start": match.start(),
        }

        notes_by_scope_id[scope_id][xmlid].append(note)
        for ref_id in parse_targets(note["target_raw"]):
            notes_by_scope_ref[scope_id][ref_id].append(note)
        global_note_scopes[xmlid].add(scope_id)
        global_notes_by_id[xmlid].append(note)

    return (
        scope_starts,
        scope_ids,
        notes_by_scope_id,
        notes_by_scope_ref,
        global_note_scopes,
        global_notes_by_id,
    )


def choose_unique_note(candidates, ref_attrs):
    if not candidates:
        return None, None
    if len(candidates) == 1:
        return candidates[0], "direct"

    ref_xmlid = ref_attrs.get("xml:id")
    ref_n = ref_attrs.get("n")

    if ref_xmlid:
        reciprocal = [note for note in candidates if ref_xmlid in parse_targets(note["target_raw"])]
        if len(reciprocal) == 1:
            return reciprocal[0], "direct+reciprocal"
        if len(reciprocal) > 1:
            candidates = reciprocal

    if ref_n:
        same_n = [note for note in candidates if note.get("n") == ref_n]
        if len(same_n) == 1:
            return same_n[0], "direct+n"
        if len(same_n) > 1:
            candidates = same_n

    return None, "ambiguous"


def resolve_single_target(
    target_id,
    ref_attrs,
    scope_id,
    notes_by_scope_id,
    notes_by_scope_ref,
    global_note_scopes,
    global_notes_by_id,
    total_targets,
):
    local_candidates = notes_by_scope_id.get(scope_id, {}).get(target_id, [])
    note, mode = choose_unique_note(local_candidates, ref_attrs)
    if note is not None:
        return note, mode or "direct"
    if local_candidates:
        return None, "ambiguous-local"

    ref_xmlid = ref_attrs.get("xml:id")
    if total_targets == 1 and ref_xmlid:
        reciprocal_candidates = notes_by_scope_ref.get(scope_id, {}).get(ref_xmlid, [])
        note, mode = choose_unique_note(reciprocal_candidates, ref_attrs)
        if note is not None:
            return note, f"reciprocal:{mode}"
        if reciprocal_candidates:
            return None, "ambiguous-reciprocal"

    global_candidates = [
        note for note in global_notes_by_id.get(target_id, [])
        if note["scope_id"] != scope_id
    ]
    note, mode = choose_unique_note(global_candidates, ref_attrs)
    if note is not None:
        return note, f"cross-scope:{mode}:{note['scope_id']}"
    if global_candidates:
        other_scopes = sorted(scope for scope in global_note_scopes.get(target_id, set()) if scope != scope_id)
        return None, f"ambiguous-cross-scope:{','.join(other_scopes)}"

    return None, "missing"


def resolve_ref(ref_attrs_raw, scope_id, notes_by_scope_id, notes_by_scope_ref, global_note_scopes, global_notes_by_id):
    ref_attrs = parse_attrs(ref_attrs_raw)
    target_raw = ref_attrs.get("target", "")
    targets = parse_targets(target_raw)

    if not targets:
        return {
            "ok": False,
            "issue": "ref without note",
            "detail": "ref note sans target exploitable",
            "targets": [],
            "used_reciprocal": False,
            "used_cross_scope": False,
            "deduped": False,
        }

    resolved_notes = []
    normalized_contents = set()
    issue_details = []
    used_reciprocal = False
    used_cross_scope = False
    deduped = False

    for target_id in targets:
        note, mode = resolve_single_target(
            target_id,
            ref_attrs,
            scope_id,
            notes_by_scope_id,
            notes_by_scope_ref,
            global_note_scopes,
            global_notes_by_id,
            total_targets=len(targets),
        )

        if note is None:
            issue_details.append(f"{target_id}:{mode}")
            continue

        if mode.startswith("reciprocal:"):
            used_reciprocal = True
        if mode.startswith("cross-scope:"):
            used_cross_scope = True

        normalized = normalize_xml_space(note["content"])
        if normalized in normalized_contents:
            deduped = True
            continue

        normalized_contents.add(normalized)
        resolved_notes.append(note)

    if issue_details:
        return {
            "ok": False,
            "issue": "ref without note",
            "detail": ";".join(issue_details),
            "targets": targets,
            "used_reciprocal": used_reciprocal,
            "used_cross_scope": used_cross_scope,
            "deduped": deduped,
        }

    return {
        "ok": True,
        "notes": resolved_notes,
        "targets": targets,
        "used_reciprocal": used_reciprocal,
        "used_cross_scope": used_cross_scope,
        "deduped": deduped,
    }


def build_replacement(ref_attrs_raw, resolved):
    ref_attrs = parse_attrs(ref_attrs_raw)
    target_value = " ".join(f"#{target_id}" for target_id in resolved["targets"])
    combined_content = "".join(note["content"] for note in resolved["notes"])

    new_attrs = ' type="note"'
    if ref_attrs.get("n"):
        new_attrs += f' n="{ref_attrs["n"]}"'
    if target_value:
        new_attrs += f' target="{target_value}"'
    if ref_attrs.get("xml:id"):
        new_attrs += f' xml:id="{ref_attrs["xml:id"]}"'

    return f"<note{new_attrs}>{combined_content}</note>"


def convert_file(xml_path, out_path):
    with open(xml_path, encoding="utf-8", errors="replace") as handle:
        xml = handle.read()

    (
        scope_starts,
        scope_ids,
        notes_by_scope_id,
        notes_by_scope_ref,
        global_note_scopes,
        global_notes_by_id,
    ) = build_note_indexes(xml)

    refs = []
    refs_by_scope_xmlid = defaultdict(set)
    global_ref_scopes = defaultdict(set)
    for match in REF_RE.finditer(xml):
        attrs_raw = match.group(1)
        attrs = parse_attrs(attrs_raw)
        if attrs.get("type") != "note":
            continue
        scope_id = scope_for_pos(match.start(), scope_starts, scope_ids)
        ref_xmlid = attrs.get("xml:id")
        if ref_xmlid:
            refs_by_scope_xmlid[scope_id].add(ref_xmlid)
            global_ref_scopes[ref_xmlid].add(scope_id)
        refs.append({
            "match": match,
            "attrs_raw": attrs_raw,
            "attrs": attrs,
            "scope_id": scope_id,
        })

    if not refs:
        with open(out_path, "w", encoding="utf-8") as handle:
            handle.write(xml)
        return {
            "converted": 0,
            "unresolved": 0,
            "orphan_notes": 0,
            "multi_target": 0,
            "deduped_multi": 0,
            "reciprocal_resolved": 0,
            "cross_scope_copied": 0,
            "report_rows": [],
        }

    stats = Counter()
    report_rows = []
    new_xml = xml

    for ref in reversed(refs):
        match = ref["match"]
        ref_attrs_raw = ref["attrs_raw"]
        ref_attrs = ref["attrs"]
        scope_id = ref["scope_id"]
        resolved = resolve_ref(
            ref_attrs_raw,
            scope_id,
            notes_by_scope_id,
            notes_by_scope_ref,
            global_note_scopes,
            global_notes_by_id,
        )

        if len(resolved["targets"]) > 1:
            stats["multi_target"] += 1
        if resolved.get("deduped"):
            stats["deduped_multi"] += 1

        if not resolved["ok"]:
            stats["unresolved"] += 1
            report_rows.append({
                "file": os.path.basename(xml_path),
                "scope_id": scope_id,
                "ref_xmlid": ref_attrs.get("xml:id", ""),
                "ref_n": ref_attrs.get("n", ""),
                "target_raw": ref_attrs.get("target", "").strip(),
                "issue": resolved["issue"],
                "detail": resolved["detail"],
            })
            continue

        if resolved.get("used_reciprocal"):
            stats["reciprocal_resolved"] += 1
        if resolved.get("used_cross_scope"):
            stats["cross_scope_copied"] += 1

        replacement = build_replacement(ref_attrs_raw, resolved)
        new_xml = new_xml[:match.start()] + replacement + new_xml[match.end():]
        stats["converted"] += 1

    for scope_id, notes_by_id in notes_by_scope_id.items():
        local_ref_ids = refs_by_scope_xmlid.get(scope_id, set())
        for note_list in notes_by_id.values():
            for note in note_list:
                note_target_ids = parse_targets(note["target_raw"])
                if not note_target_ids:
                    continue

                is_back_note_candidate = all(target_id not in global_notes_by_id for target_id in note_target_ids)
                if not is_back_note_candidate:
                    continue

                if any(target_id in local_ref_ids for target_id in note_target_ids):
                    continue

                external_calls = []
                for target_id in note_target_ids:
                    for other_scope in sorted(global_ref_scopes.get(target_id, set())):
                        if other_scope != scope_id:
                            external_calls.append(f"{target_id}:{other_scope}")

                detail_parts = []
                if external_calls:
                    detail_parts.append("called from other act -> " + ",".join(external_calls))
                else:
                    detail_parts.append("no call in same act")
                if not any(target_id in global_ref_scopes for target_id in note_target_ids):
                    detail_parts.append("target ref absent globally")

                report_rows.append({
                    "file": os.path.basename(xml_path),
                    "scope_id": scope_id,
                    "ref_xmlid": note["xmlid"],
                    "ref_n": note.get("n", "") or "",
                    "target_raw": note["target_raw"].strip(),
                    "issue": "orphan note",
                    "detail": "; ".join(detail_parts),
                })
                stats["orphan_notes"] += 1

    with open(out_path, "w", encoding="utf-8") as handle:
        handle.write(new_xml)

    stats["report_rows"] = report_rows
    return stats


def write_report(report_path, rows):
    with open(report_path, "w", encoding="utf-8", newline="") as handle:
        handle.write("file\tscope_id\tref_xmlid\tref_n\ttarget_raw\tissue\tdetail\n")
        for row in rows:
            values = [
                row["file"],
                row["scope_id"],
                row["ref_xmlid"],
                row["ref_n"],
                row["target_raw"],
                row["issue"],
                row["detail"],
            ]
            clean_values = [value.replace("\t", " ").replace("\n", " ") for value in values]
            handle.write("\t".join(clean_values) + "\n")


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    xml_files = sorted(glob.glob(os.path.join(INPUT_DIR, "*.xml")))
    if not xml_files:
        print(f"Aucun fichier XML trouve dans {INPUT_DIR}")
        sys.exit(1)

    print("=" * 60)
    print(f"Inlining <ref type='note'> -> <note> - {len(xml_files)} fichiers")
    print(f"Output : {OUTPUT_DIR}")
    print("=" * 60)
    print()

    total_converted = 0
    total_unresolved = 0
    total_orphan_notes = 0
    total_multi_target = 0
    total_deduped = 0
    total_reciprocal = 0
    total_cross_scope = 0
    all_report_rows = []

    for xml_path in xml_files:
        fname = os.path.basename(xml_path)
        out_path = os.path.join(OUTPUT_DIR, fname)
        result = convert_file(xml_path, out_path)

        total_converted += result["converted"]
        total_unresolved += result["unresolved"]
        total_orphan_notes += result["orphan_notes"]
        total_multi_target += result["multi_target"]
        total_deduped += result["deduped_multi"]
        total_reciprocal += result["reciprocal_resolved"]
        total_cross_scope += result["cross_scope_copied"]
        all_report_rows.extend(result["report_rows"])

        if result["converted"] == 0 and result["unresolved"] == 0 and result["orphan_notes"] == 0:
            print(f"[{fname}] -> OK (aucun ref type=note)")
            continue

        status = [f"{result['converted']} convertis"]
        if result["unresolved"]:
            status.append(f"{result['unresolved']} non resolus")
        if result["orphan_notes"]:
            status.append(f"{result['orphan_notes']} orphan note")
        if result["multi_target"]:
            status.append(f"{result['multi_target']} multi-target")
        if result["deduped_multi"]:
            status.append(f"{result['deduped_multi']} dedoublonnes")
        if result["reciprocal_resolved"]:
            status.append(f"{result['reciprocal_resolved']} resolus par reciprocite")
        if result["cross_scope_copied"]:
            status.append(f"{result['cross_scope_copied']} copies inter-actes")
        print(f"[{fname}] -> {', '.join(status)}")

    report_path = os.path.join(OUTPUT_DIR, "inline_notes_report.tsv")
    write_report(report_path, all_report_rows)

    print()
    print("=" * 60)
    print(f"TOTAL : {total_converted} refs convertis, {total_unresolved} non resolus")
    print(f"Orphan note : {total_orphan_notes}")
    print(f"Multi-target : {total_multi_target}, dedoublonnes : {total_deduped}")
    print(f"Resolutions reciproques : {total_reciprocal}")
    print(f"Copies inter-actes : {total_cross_scope}")
    print(f"Rapport : {report_path}")
    print(f"Fichiers dans : {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
