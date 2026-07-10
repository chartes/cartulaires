# -*- coding: utf-8 -*-
"""
Croise les index consolides (personnes / lieux) pour trouver les lemmes
attestes dans PLUSIEURS cartulaires distincts.

Sortie : un rapport texte, une par entree groupee, tri par nb de cartulaires
puis alpha. Les renvois "voir / vide / voy." ne sont pas comptes comme
attestations reelles (marques a part).
"""
import re
import sys
import unicodedata
from collections import defaultdict

ITEM_RE = re.compile(r'<item xml:id="([A-Z0-9-]+)_rs_[^"]*">(.*?)</item>', re.S)
RS_RE = re.compile(r'<rs\b[^>]*>(.*?)</rs>', re.S)
TAG_RE = re.compile(r'<[^>]+>')
SEE_RE = re.compile(r'\b(voir|vide|voy\.?|v\.)\b', re.I)


def strip_tags(s):
    # retire les segments de renvoi <seg>...</seg> avant de compter le lemme
    s = re.sub(r'<seg\b.*?</seg>', '', s, flags=re.S)
    s = TAG_RE.sub('', s)
    s = s.replace('&amp;', '&').replace('&lt;', '<').replace('&gt;', '>')
    return re.sub(r'\s+', ' ', s).strip()


def normalize(lemma):
    """Cle de regroupement : tete du lemme (avant 1re virgule), sans
    diacritiques, minuscule, sans crochets/ponctuation/parentheses."""
    head = lemma.split(',')[0]
    head = re.sub(r'\([^)]*\)', ' ', head)      # retire (Yvelines), (abbe d')...
    head = head.replace('[', '').replace(']', '')
    head = unicodedata.normalize('NFKD', head)
    head = ''.join(c for c in head if not unicodedata.combining(c))
    head = head.lower()
    head = re.sub(r'[^a-z0-9 ]', ' ', head)
    head = re.sub(r'\s+', ' ', head).strip()
    return head


def analyze(path, label):
    text = open(path, encoding='utf-8').read()
    groups = defaultdict(list)   # cle -> list of (cartu, lemma_affiche, is_see)
    for cartu, body in ITEM_RE.findall(text):
        m = RS_RE.search(body)
        if not m:
            continue
        lemma = strip_tags(m.group(1))
        if not lemma:
            continue
        key = normalize(lemma)
        if not key:
            continue
        is_see = bool(SEE_RE.search(strip_tags(m.group(1))) or 'type="see"' in body)
        groups[key].append((cartu, lemma, is_see))

    # ne garder que les cles presentes dans >=2 cartulaires distincts (attestations reelles)
    multi = []
    for key, entries in groups.items():
        cartus = {c for c, l, see in entries if not see}
        if len(cartus) >= 2:
            multi.append((key, entries, cartus))

    multi.sort(key=lambda x: (-len(x[2]), x[0]))

    out = [f"=== {label} : {len(multi)} lemmes attestes dans >=2 cartulaires ===\n"]
    for key, entries, cartus in multi:
        out.append(f"[{len(cartus)} cartul.] {key}")
        for cartu, lemma, see in sorted(entries):
            flag = '  (renvoi)' if see else ''
            out.append(f"    {cartu:<14} {lemma}{flag}")
        out.append("")
    return "\n".join(out), multi


if __name__ == '__main__':
    for path, label, tag in [
        ('INDEX-PERSONNES.xml', 'PERSONNES', 'personnes'),
        ('INDEX-LIEUX.xml', 'LIEUX', 'lieux'),
    ]:
        report, multi = analyze(path, label)
        outfile = f'croisement-{tag}.txt'
        open(outfile, 'w', encoding='utf-8').write(report)
        print(f'{label}: {len(multi)} lemmes multi-cartulaires -> {outfile}')
