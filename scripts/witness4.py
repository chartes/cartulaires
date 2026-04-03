#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
micy_mp_builder.py

TEI fixes (Micy):
1) Pre-pass regex: move stray text after </witness> back inside <witness>.
2) Witness normalization:
   - ensure witness/@n exists (guess from <hi> or first token)
   - special-case: indique/indiqué/Indiq -> n="INDIQUE"
   - rule: <witness><hi rend="i">D</hi>...</witness> -> witness/@n="D" + unwrap hi
   - unwrap ALL <hi> inside <witness> (keep children/text)
3) Quote normalization:
   - fix invalid: <p><quote><p>...</p>...</quote></p> -> unwrap outer <p> (quote becomes sibling)
   - ensure <quote> contains <p> children: if quote has no direct <p>, wrap its mixed content into one <p>
4) Ensure required <back/> directly under each <text> if missing.

Usage:
  python micy_mp_builder.py input.xml output.xml
"""

import re
import sys
from pathlib import Path
from lxml import etree

NS = {"tei": "http://www.tei-c.org/ns/1.0"}
TEI_NS = "http://www.tei-c.org/ns/1.0"
TEI = f"{{{TEI_NS}}}"

# --- (1) regex witness closing fix (text after </witness>)
WITNESS_CLOSING_RE = re.compile(
    r"</witness>(\s*[^<]*\S[^<]*?)(?=\s*<(?:witness\b|/listWit>))",
    flags=re.DOTALL,
)

TOKEN_RE = re.compile(r"^\s*([A-Za-z0-9]+)\b")


def get_text(el) -> str:
    return "".join(el.itertext()) if el is not None else ""


def unwrap_keep_children(el):
    """Remove wrapper element but keep its children/text/tail in place."""
    parent = el.getparent()
    if parent is None:
        return
    idx = parent.index(el)

    # leading text
    if el.text:
        if idx == 0:
            parent.text = (parent.text or "") + el.text
        else:
            prev = parent[idx - 1]
            prev.tail = (prev.tail or "") + el.text

    # move children
    for child in list(el):
        el.remove(child)
        parent.insert(idx, child)
        idx += 1

    # tail
    if el.tail:
        if idx == 0:
            parent.text = (parent.text or "") + el.tail
        else:
            prev = parent[idx - 1]
            prev.tail = (prev.tail or "") + el.tail

    parent.remove(el)


def apply_witness_regex_fix(xml_text: str) -> tuple[str, int]:
    fixed, n = WITNESS_CLOSING_RE.subn(r"\1</witness>", xml_text)
    return fixed, n


def normalize_listwit_type(root) -> int:
    """
    Optionnel mais utile: harmonise listWit/@type pour les variantes 'indique/Indiq/indiqué'.
    (Tu peux commenter si tu veux rien toucher.)
    """
    fixed = 0
    for lw in root.xpath("//tei:listWit[@type]", namespaces=NS):
        t = (lw.get("type") or "").strip()
        tl = t.lower().replace(".", "")
        if tl in {"indique", "indiqué", "indiq"}:
            if lw.get("type") != "indiqué":
                lw.set("type", "indiqué")
                fixed += 1
    return fixed


def guess_witness_n(wit):
    # 1) Prefer <hi> content if it looks like an ID token
    hi = wit.find(".//tei:hi", namespaces=NS)
    if hi is not None:
        cand = get_text(hi).strip()
        if cand and " " not in cand and len(cand) <= 20:
            return cand

    # 2) Else first token of full witness text
    txt = get_text(wit)
    m = TOKEN_RE.match(txt or "")
    if m:
        return m.group(1)

    return None


def fix_witness_nodes(root) -> int:
    fixed = 0
    for wit in root.xpath("//tei:witness", namespaces=NS):
        # If first <hi> is a single-letter id (D, A, B, etc.), prefer that for @n
        first_hi = wit.find(".//tei:hi", namespaces=NS)
        if first_hi is not None:
            cand_hi = get_text(first_hi).strip()
            if cand_hi and " " not in cand_hi and len(cand_hi) <= 20:
                # special-case 'indiqué'
                if cand_hi.lower() in {"indiqué", "indique", "indiq", "indiq:"}:
                    if wit.get("n") != "INDIQUE":
                        wit.set("n", "INDIQUE")
                        fixed += 1
                else:
                    if not wit.get("n"):
                        wit.set("n", cand_hi)
                        fixed += 1

        # If still no @n, guess
        if not wit.get("n"):
            cand = guess_witness_n(wit)
            if cand:
                if cand.lower() in {"indiqué", "indique", "indiq"}:
                    wit.set("n", "INDIQUE")
                else:
                    wit.set("n", cand)
                fixed += 1

        # unwrap ALL <hi> inside witness (your rule)
        for hi in list(wit.xpath(".//tei:hi", namespaces=NS)):
            unwrap_keep_children(hi)
            fixed += 1

    return fixed


def fix_quote_structure(root) -> int:
    """
    - If <p> contains a <quote> that itself contains <p>, unwrap the outer <p>.
    - If <quote> has no direct <p> child, wrap its mixed content into one <p>.
    """
    fixed = 0

    # A) <p><quote><p>...</p>...</quote></p> -> unwrap outer p (conservative)
    for p in list(root.xpath("//tei:p[tei:quote[tei:p]]", namespaces=NS)):
        quotes = p.xpath("./tei:quote[tei:p]", namespaces=NS)
        if len(quotes) != 1:
            continue

        # If p has other element children than the quote, skip
        other_el = [c for c in list(p) if isinstance(c.tag, str) and c.tag != f"{TEI}quote"]
        if other_el:
            continue

        # If p has meaningful leading text besides whitespace, skip
        if (p.text or "").strip():
            continue

        unwrap_keep_children(p)
        fixed += 1

    # B) Ensure quote contains <p> if it has none
    for quote in list(root.xpath("//tei:quote[not(tei:p)]", namespaces=NS)):
        old_text = quote.text or ""
        kids = list(quote)

        if not old_text.strip() and len(kids) == 0:
            continue

        p = etree.Element(f"{TEI}p")
        p.text = old_text
        quote.text = None

        for ch in kids:
            quote.remove(ch)
            p.append(ch)

        quote.append(p)
        fixed += 1

    return fixed


def ensure_back_under_text(root) -> int:
    """
    Add <back/> as a direct child of each <text> if missing.
    Insert after <body> when possible.
    """
    fixed = 0
    for t in root.xpath("//tei:text", namespaces=NS):
        if t.find("tei:back", namespaces=NS) is not None:
            continue
        back = etree.Element(f"{TEI}back")
        body = t.find("tei:body", namespaces=NS)
        if body is not None:
            t.insert(t.index(body) + 1, back)
        else:
            t.append(back)
        fixed += 1
    return fixed


def main(inp: str, out: str) -> None:
    inp_path = Path(inp)
    out_path = Path(out)

    # --- read as text for regex pre-pass
    xml_text = inp_path.read_text(encoding="utf-8", errors="replace")
    xml_text, n_regex = apply_witness_regex_fix(xml_text)

    # --- parse (must be well-formed)
    parser = etree.XMLParser(remove_blank_text=False, recover=False, huge_tree=True)
    root = etree.fromstring(xml_text.encode("utf-8"), parser=parser)
    tree = etree.ElementTree(root)

    n_lw = normalize_listwit_type(root)
    n_wit = fix_witness_nodes(root)
    n_quote = fix_quote_structure(root)
    n_back = ensure_back_under_text(root)

    tree.write(str(out_path), encoding="UTF-8", xml_declaration=True, pretty_print=True)

    print("OK ✅")
    print(f"  - witness regex fixes: {n_regex}")
    print(f"  - listWit/@type normalized: {n_lw}")
    print(f"  - witness node fixes:  {n_wit}")
    print(f"  - quote fixes:         {n_quote}")
    print(f"  - <back/> added:       {n_back}")
    print(f"Wrote: {out_path}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python micy_mp_builder.py input.xml output.xml")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
