#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, time
from pathlib import Path
from lxml import etree

TEI_NS = "http://www.tei-c.org/ns/1.0"
NS = {"tei": TEI_NS}

XML_ID = "{http://www.w3.org/XML/1998/namespace}id"
TEI_FRONT = f"{{{TEI_NS}}}front"
TEI_INDEX = f"{{{TEI_NS}}}index"
TEI_TERM  = f"{{{TEI_NS}}}term"


# -----------------------------
# IO
# -----------------------------

def iter_xml_files(path: Path, recursive: bool):
    if path.is_file():
        return [path]
    if recursive:
        return sorted([p for p in path.rglob("*.xml") if p.is_file()])
    return sorted([p for p in path.glob("*.xml") if p.is_file()])


def collect_inputs(inputs, recursive: bool):
    """inputs: list[Path] -> list[Path xml files] (dedup + sorted)"""
    all_files = []
    for p in inputs:
        all_files.extend(iter_xml_files(p, recursive=recursive))
    # dédoublonnage
    uniq = sorted({str(f): f for f in all_files}.values(), key=lambda x: str(x).lower())
    return uniq


# -----------------------------
# Act detection (inchangé)
# -----------------------------

def is_act_text(t: etree._Element) -> bool:
    subtype = (t.get("subtype") or "").lower()
    if subtype == "article":
        return True
    if t.get(XML_ID):
        return True
    if t.get("n"):
        return True
    return t.find("tei:body", namespaces=NS) is not None


# -----------------------------
# Ensure blocks (inchangé)
# -----------------------------

def ensure_front(t: etree._Element):
    front = t.find("tei:front", namespaces=NS)
    if front is not None:
        return front, False

    front = etree.Element(TEI_FRONT)
    body = t.find("tei:body", namespaces=NS)
    if body is not None:
        t.insert(t.index(body), front)
    else:
        t.insert(0, front)
    return front, True


def ensure_index(front: etree._Element):
    idx = front.find("tei:index", namespaces=NS)
    if idx is not None:
        return idx, False
    idx = etree.SubElement(front, TEI_INDEX)
    return idx, True


def ensure_auth_type(idx: etree._Element, tbd_key_mode: str):
    auth = idx.findall("tei:term[@type='auth_type']", namespaces=NS)
    if auth:
        return False

    term = etree.SubElement(idx, TEI_TERM)
    term.set("type", "auth_type")

    # >>> par défaut on veut "tbd"
    if tbd_key_mode == "tbd":
        term.set("key", "tbd")
        term.text = "TBD"
    else:
        term.set("key", "")
        term.text = "TBD"
    return True


def ensure_country(idx: etree._Element, default_country: str):
    if not default_country:
        return False
    country = idx.findall("tei:term[@type='actual_country']", namespaces=NS)
    if country:
        return False
    term = etree.SubElement(idx, TEI_TERM)
    term.set("type", "actual_country")
    term.set("key", default_country.upper())
    term.text = default_country.upper()
    return True


# -----------------------------
# Main
# -----------------------------

def main():
    # Nouveau usage : 1+ input(s) puis output_dir en dernier argument non-option
    # Ex:
    #   python index_bootstrap_multi.py file1.xml file2.xml out_dir
    #   python index_bootstrap_multi.py dirA dirB out_dir --recursive
    #
    # Options:
    #   --recursive
    #   --recover
    #   --default-country FR
    #   --tbd-key empty|tbd   (mais défaut = tbd)

    if len(sys.argv) < 3:
        print("Usage: python index_bootstrap_multi.py <input1> [input2 ...] <output_dir> "
              "[--recursive] [--recover] [--default-country FR] [--tbd-key empty|tbd]")
        sys.exit(1)

    argv = sys.argv[1:]

    recursive = ("--recursive" in argv)
    recover = ("--recover" in argv)

    default_country = ""
    if "--default-country" in argv:
        i = argv.index("--default-country")
        if i + 1 < len(argv):
            default_country = argv[i + 1].strip()

    # >>> défaut demandé: tbd
    tbd_key_mode = "tbd"
    if "--tbd-key" in argv:
        i = argv.index("--tbd-key")
        if i + 1 < len(argv):
            v = argv[i + 1].strip().lower()
            if v in ("empty", "tbd"):
                tbd_key_mode = v

    # retirer les options pour récupérer les positionnels
    option_tokens = set(["--recursive", "--recover", "--default-country", "--tbd-key"])
    positionals = []
    skip_next = False
    for a in argv:
        if skip_next:
            skip_next = False
            continue
        if a in ("--default-country", "--tbd-key"):
            skip_next = True
            continue
        if a in option_tokens:
            continue
        positionals.append(a)

    if len(positionals) < 2:
        print("[ERROR] Il faut au moins 1 input et 1 output_dir.")
        sys.exit(2)

    out_dir = Path(positionals[-1]).expanduser().resolve()
    inputs = [Path(x).expanduser().resolve() for x in positionals[:-1]]

    files = collect_inputs(inputs, recursive=recursive)
    if not files:
        print("[ERROR] No XML files found in inputs.")
        sys.exit(2)

    parser = etree.XMLParser(recover=recover, huge_tree=True, remove_blank_text=False)

    print(f"[START] files={len(files)} recursive={recursive} recover={recover} "
          f"default_country={default_country or '(none)'} tbd_key={tbd_key_mode}")
    t0 = time.time()

    created_front = 0
    created_index = 0
    added_auth = 0
    added_country = 0
    errors = 0

    for idxf, f in enumerate(files, start=1):
        # sortie: on garde le nom du fichier (si inputs multiples, on ne peut pas conserver une base unique propre)
        out_path = out_dir / f.name
        out_path.parent.mkdir(parents=True, exist_ok=True)

        print(f"[{idxf}/{len(files)}] {f.name}")
        try:
            tree = etree.parse(str(f), parser)
            root = tree.getroot()

            texts = root.xpath("//tei:text", namespaces=NS)
            acts = [t for t in texts if is_act_text(t)]

            for t in acts:
                front, did_front = ensure_front(t)
                if did_front:
                    created_front += 1

                idx_el, did_idx = ensure_index(front)
                if did_idx:
                    created_index += 1

                if ensure_auth_type(idx_el, tbd_key_mode=tbd_key_mode):
                    added_auth += 1

                if ensure_country(idx_el, default_country=default_country):
                    added_country += 1

            tree.write(str(out_path), encoding="utf-8", xml_declaration=True, pretty_print=True)

        except Exception as e:
            errors += 1
            print(f"  -> ERROR: {type(e).__name__}: {e}")

    print(f"[DONE] out_dir={out_dir}")
    print(f"[STATS] created_front={created_front} created_index={created_index} "
          f"added_auth_type={added_auth} added_country={added_country} errors={errors}")
    print(f"[TIME]  {time.time()-t0:.1f}s")


if __name__ == "__main__":
    main()
