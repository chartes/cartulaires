# -*- coding: utf-8 -*-
"""
Fait entrer les personnes et lieux du censier de Saint-Spire de Corbeil (SSCO)
dans les index consolides INDEX-PERSONNES.xml et INDEX-LIEUX.xml.

- Extrait les entrees du censier (<p> commencant par un tiret) du group
  SSCO-AB_censier_group dans data/SSCO-AB.xml.
- Cible du lien = dernier <pb> rencontre en document order (page/colonne).
- Rapprochement flou avec les fiches SSCO existantes ; si match -> ajout d'un
  <ref type="censier"> avant le point final ; sinon -> creation d'une fiche
  (regroupee par noyau normalise, une ref par page).
- Ne modifie QUE les deux index. Ne touche pas SSCO-AB.xml.
"""
import os, re, csv, sys, datetime, io
from lxml import etree

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(BASE, "data")
AUDIT = os.path.join(BASE, "_AUDIT_index")
SRC = os.path.join(DATA, "SSCO-AB.xml")
IDX_PERS = os.path.join(DATA, "INDEX-PERSONNES.xml")
IDX_LIEUX = os.path.join(DATA, "INDEX-LIEUX.xml")

TEI = "http://www.tei-c.org/ns/1.0"
NS = {"t": TEI}

# ---------------------------------------------------------------------------
# 1. EXTRACTION DU CENSIER
# ---------------------------------------------------------------------------

# mots-cles LIEU : le nom commence par l'un d'eux -> LIEU
LIEU_PREFIXES = (
    "domus", "domuncule", "domuncula", "ecclesia", "ecclesie", "capella",
    "cappella", "capelle", "hospitale", "hospitalis", "grangia", "granchia",
    "terra", "terre", "vinea", "vinee", "molendin", "borda", "refectorium",
    "refectorii", "vinum", "vineis", "platea",
)

# titres / fonctions a retirer pour la normalisation onomastique
TITLES = {
    "dominus", "domina", "domini", "magister", "magistri", "frater", "fratres",
    "fratris", "presbiter", "presbiteri", "presbyter", "clericus", "clerici",
    "cantor", "cantoris", "judeus", "judei", "canonicus", "canonici",
    "capellanus", "capellani", "cappellanus", "carnifex", "carnificis",
    "diaconus", "subdiaconus", "miles", "militis", "constabularius",
    "camerarius", "cancellarius", "capicerius", "capicerii", "prepositus",
    "prepositi", "talemerarius", "carpentarius", "plastarius", "olearius",
    "relicta", "uxor", "filius", "filia", "filii", "major", "monachi",
    "monachus", "canonicorum", "templarii", "presbiteri", "capicier",
}

def strip_tags_text(el):
    """Texte concatene d'un element (comme <p>), y compris avant/apres pb."""
    return "".join(el.itertext())

# entrees qui ne sont PAS des censitaires nominatifs : rubriques de revenus du
# chapitre, continuations 'Item', clauses toponymiques/prose. Detectees sur le
# texte de tete -> SKIP (reportees au CSV).
RUBRIQUE_HEAD_RE = re.compile(
    r"^(item\b|in festo\b|apud\b|si aliquis\b|si\s|et sciendum\b|"
    r"distribucio\b|distribuciones\b|matutine\b|summa\b|de his\b|"
    r"priori de\b|hoc est\b|hic est\b|hii sunt\b|census\b)",
    re.IGNORECASE)

# marqueurs de clause VERBALE (revenu du chapitre) : on coupe le nom juste
# avant. NB : on ne coupe PAS sur 'que/qui/quod/fuit/est' car ils font partie
# de descripteurs de lieu distinctifs ('Domus que fuit X', 'Domus que est ...').
CLAUSE_CUT_RE = re.compile(
    r"(\bde omnibus\b|\bde quibus\b|\bhabet\b|\bhabent\b|\bhabemus\b|"
    r"\bhabebit\b|\bdebentur\b|\bdebet\b|\bredditur\b|\breddi\b|"
    r"\bpertinet\b|\btenetur\b|\bfecerit\b)", re.IGNORECASE)

def is_rubrique(head_text):
    s = re.sub(r"^[\s—–\-]+", "", head_text).strip()
    return bool(RUBRIQUE_HEAD_RE.match(s))

def extract_name(entry_text):
    """Extrait le noyau nominal : jusqu'a la 1re virgule, ou 'pro'/'pour',
    ou le 1er nombre, ou une clause subordonnee/verbe."""
    s = entry_text
    # retirer le tiret de tete et espaces
    s = re.sub(r"^[\s—–\-]+", "", s).strip()
    # couper au 1er 'pro '/'pour ' (mot entier)
    cut_positions = []
    for kw in (r"\bpro\b", r"\bpour\b"):
        m = re.search(kw, s, re.IGNORECASE)
        if m:
            cut_positions.append(m.start())
    # couper a la 1re clause subordonnee / verbe (que/qui/habet/est/fuit...)
    mc = CLAUSE_CUT_RE.search(s)
    if mc and mc.start() > 0:
        cut_positions.append(mc.start())
    # couper au 1er chiffre (avec romains possibles precedes d'espace : on
    # coupe seulement sur chiffres arabes ; les nombres romains isoles comme
    # 'VI d.' sont geres via le point ci-dessous mais restent rares au sein du nom)
    m = re.search(r"\d", s)
    if m:
        cut_positions.append(m.start())
    # couper a la 1re virgule
    m = re.search(r",", s)
    if m:
        cut_positions.append(m.start())
    if cut_positions:
        s = s[: min(cut_positions)]
    s = s.strip().rstrip(".").strip()
    # retirer un eventuel nombre romain de tete qui serait un montant colle : non.
    return s

def classify(name):
    low = name.lower().lstrip("+ ").strip()
    # retirer parentheses/asterisques de tete
    low = re.sub(r"^[\(\*\+\s]+", "", low)
    first = low.split()[0] if low.split() else ""
    first = first.strip("()*.,")
    # 'capellanus/cappellanus' = un chapelain (PERSONNE), a ne pas confondre
    # avec 'capella' (la chapelle = LIEU).
    if first.startswith("capellan") or first.startswith("cappellan"):
        return "PERSONNE"
    for p in LIEU_PREFIXES:
        if first.startswith(p):
            return "LIEU"
    return "PERSONNE"

def normalize_core(name):
    """Noyau onomastique normalise pour le matching flou."""
    s = name.lower()
    # retirer marques d'obit / asterisques / parentheses de contenu
    s = s.replace("(*)", " ").replace("*", " ").replace("+", " ")
    s = re.sub(r"\(.*?\)", " ", s)       # retirer contenu entre parentheses
    s = re.sub(r"[^\w\s]", " ", s, flags=re.UNICODE)  # ponctuation -> espace
    # accents -> base
    trans = str.maketrans("àáâãäåèéêëìíîïòóôõöùúûüçñ", "aaaaaaeeeeiiiiooooouuuucn")
    s = s.translate(trans)
    toks = [t for t in s.split() if t]
    # retirer titres/fonctions
    core = [t for t in toks if t not in TITLES]
    if not core:
        core = toks
    # lemmatisation grossiere des terminaisons latines
    def lemma(w):
        for suf in ("orum", "arum", "ibus", "us", "um", "is", "i", "o", "e", "a"):
            if len(w) > len(suf) + 2 and w.endswith(suf):
                return w[: -len(suf)]
        return w
    lem = [lemma(w) for w in core]
    return " ".join(lem)

# honorifiques non distinctifs : retires en tete du nom d'affichage et de la
# cle de regroupement (mais on GARDE les fonctions distinctives : carnifex,
# canonicus, prepositus... qui distinguent des homonymes).
HONORIFICS = {"dominus", "domina", "domini", "magister", "magistri"}

def group_key(name):
    """Cle de regroupement des NOUVELLES fiches : conserve les mots de fonction
    (distinctifs) mais normalise casse/accents/declinaisons et retire les
    honorifiques + parentheses. 'Robertus Carnifex' != 'Robertus canonicus'."""
    s = name.lower()
    s = s.replace("(*)", " ").replace("*", " ").replace("+", " ")
    s = re.sub(r"\(.*?\)", " ", s)
    s = re.sub(r"[^\w\s]", " ", s, flags=re.UNICODE)
    trans = str.maketrans("àáâãäåèéêëìíîïòóôõöùúûüçñ", "aaaaaaeeeeiiiiooooouuuucn")
    s = s.translate(trans)
    toks = [t for t in s.split() if t and t not in HONORIFICS]
    def lemma(w):
        for suf in ("orum", "arum", "ibus", "us", "um", "is", "i", "o", "e", "a"):
            if len(w) > len(suf) + 2 and w.endswith(suf):
                return w[: -len(suf)]
        return w
    return " ".join(lemma(w) for w in toks)

def display_name(name):
    """Nom d'affichage : retire l'honorifique de tete (Dominus/Magister...) et
    les marques '(efface)/(effacé)/(?)/(*)' ; conserve le reste tel quel."""
    s = name.strip()
    s = re.sub(r"\s*\((?:efface|effac[ée]|\*|\?)[^)]*\)", "", s, flags=re.IGNORECASE)
    s = re.sub(r"\(\s*\*?\s*\)", "", s)
    s = s.replace("(*)", "").strip()
    parts = s.split()
    if parts and parts[0].lower().rstrip(".") in HONORIFICS:
        parts = parts[1:]
    out = " ".join(parts).strip()
    if not out:
        out = re.sub(r"\s+", " ", name.strip())
    return out

def parse_censier():
    """Retourne une liste d'entrees dans l'ordre du document.
    Chaque entree = dict(name, type, page, pb_id, raw)."""
    parser = etree.XMLParser(recover=False)
    tree = etree.parse(SRC, parser)
    root = tree.getroot()
    XMLID = "{http://www.w3.org/XML/1998/namespace}id"
    group = None
    for g in root.iter("{%s}group" % TEI):
        if g.get(XMLID) == "SSCO-AB_censier_group":
            group = g
            break
    if group is None:
        raise SystemExit("group censier introuvable")

    entries = []
    # on parcourt chaque <text> article dans l'ordre
    for text in group.findall("t:text", NS):
        div = text.find(".//t:div[@type='transcription']", NS)
        if div is None:
            continue
        # last pb au niveau de l'article : commence par le pb de <text> lui-meme
        # (les pb de tete sont hors du div, on les prend en compte)
        last_pb = {"id": None, "n": None}
        # d'abord, pb situes avant le div (frere direct ou dans text)
        for pb in text.iter("{%s}pb" % TEI):
            # on ne prend en compte ici que ceux precedant le div en doc order
            break
        # On refait proprement en parcourant TOUT l'article en document order,
        # en s'arretant a chaque pb pour memoriser, et a chaque <p> pour traiter.
        for el in text.iter():
            tag = etree.QName(el).localname
            if tag == "pb":
                pbid = el.get("{http://www.w3.org/XML/1998/namespace}id")
                n = el.get("n")
                if pbid:
                    last_pb = {"id": pbid, "n": n}
            elif tag == "p":
                # NB: un pb peut etre enfant du <p> ; el.iter le verrait mais
                # ici on traite le <p> quand on l'atteint. Les pb internes au
                # <p> apparaissent APRES dans l'iteration globale car .iter()
                # est en document order (parent avant enfants). Donc pour un pb
                # en milieu de <p>, le texte AVANT le pb appartient a la page
                # courante et le texte APRES a la nouvelle page. On segmente.
                _process_p(el, last_pb, entries)
    return entries

def _process_p(p, last_pb_ref, entries):
    """Traite un <p>. Gere les pb internes : le texte est segmente par pb.
    Chaque segment devient une entree potentielle (les entrees du censier sont
    en principe un <p> = une entree, mais un pb interne peut introduire une
    2e entree collee, ex. '... , 2 s.<pb .../> — Domus refectorii, 18 d.')."""
    # Construire la sequence : morceaux de texte + pb, en document order,
    # en tenant compte de p.text, puis pour chaque enfant : (enfant, enfant.tail)
    segments = []  # liste de (texte, pb_apres) ; pb_apres = dict ou None
    cur_text = p.text or ""
    for child in p:
        ctag = etree.QName(child).localname
        if ctag == "pb":
            pbid = child.get("{http://www.w3.org/XML/1998/namespace}id")
            n = child.get("n")
            segments.append((cur_text, {"id": pbid, "n": n}))
            cur_text = child.tail or ""
        else:
            # autre element inline (num, hi, abbr...) : integrer son texte
            cur_text += "".join(child.itertext())
            cur_text += child.tail or ""
    segments.append((cur_text, None))

    # Reconstituer les "sous-entrees" separees par tiret, en gardant la page
    # active AU MOMENT du tiret.
    # On accumule le texte segment par segment ; le pb entre deux segments
    # met a jour la page courante pour la suite.
    # Chaque sous-entree commence a un tiret et court jusqu'au tiret suivant.
    # Approche : reconstruire une liste de (char_pos_page) ? Plus simple :
    # traiter chaque segment ; a l'interieur d'un segment, on peut avoir
    # plusieurs tirets. On garde la page courante = last_pb_ref (mise a jour).
    def page_now():
        return {"id": last_pb_ref["id"], "n": last_pb_ref["n"]}

    for seg_text, pb_after in segments:
        # decouper le segment sur les tirets d'entree
        # un tiret d'entree = '—' (u2014) precede d'espace/debut
        parts = re.split(r"(?<!\S)[—](?=\s)", seg_text)
        # le 1er 'part' est le prefixe (suite d'une entree precedente ou rubrique)
        for i, part in enumerate(parts):
            if i == 0:
                # texte avant le 1er tiret de ce segment : suite d'entree
                # precedente -> on l'ignore pour l'extraction de nom.
                continue
            entry_raw = "— " + part.strip()
            name = extract_name(entry_raw)
            if not name:
                continue
            pg = page_now()
            entries.append({
                "name": name,
                "type": classify(name),
                "page": pg["n"],
                "pb_id": pg["id"],
                "raw": entry_raw.strip(),
                "rubrique": is_rubrique(entry_raw),
            })
        # apres avoir traite le segment, appliquer le pb pour la suite
        if pb_after and pb_after["id"]:
            last_pb_ref["id"] = pb_after["id"]
            last_pb_ref["n"] = pb_after["n"]


# ---------------------------------------------------------------------------
# 2. LECTURE DES FICHES EXISTANTES (matching)
# ---------------------------------------------------------------------------

ITEM_RE = re.compile(r'(<item xml:id="(?P<id>[^"]+)">.*?</item>)')
HI_RE = re.compile(r'<hi rend="[a-z]+">(?P<hi>.*?)</hi>', re.S)

def strip_inner_tags(s):
    return re.sub(r"<[^>]+>", "", s)

def load_existing(path):
    """Retourne (text, list de dict(id, hi_name, norm, line_index, full_line))
    pour les fiches SSCO-AB_rs_* (pas censier)."""
    with open(path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    fiches = []
    for li, line in enumerate(lines):
        if "SSCO-AB_rs_" not in line:
            continue
        mid = re.search(r'<item xml:id="(SSCO-AB_rs_[^"]+)">', line)
        if not mid:
            continue
        m = HI_RE.search(line)
        if not m:
            continue
        hi = strip_inner_tags(m.group("hi")).strip()
        fiches.append({
            "id": mid.group(1),
            "hi": hi,
            "norm": normalize_core(hi),
            "li": li,
        })
    return lines, fiches


# ---------------------------------------------------------------------------
# 3. INSERTION / EDITION
# ---------------------------------------------------------------------------

def xml_escape(s):
    return (s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))

def build_ref(page, pb_id):
    return ('<ref n="%s" type="censier" target="#%s">Saint-Spire de Corbeil, censier, p. %s</ref>'
            % (xml_escape(page or "?"), xml_escape(pb_id), xml_escape(page or "?")))

def add_ref_to_line(line, ref_html):
    """Insere ', REF' avant le point final de l'item.
    Cherche le dernier '.</item>' ou '. </item>' et insere avant le point."""
    # forme la plus courante : ...</ref>.</item>
    idx = line.rfind("</item>")
    if idx == -1:
        return line, False
    before = line[:idx]
    after = line[idx:]
    # retirer espaces de fin dans 'before'
    stripped = before.rstrip()
    trailing_ws = before[len(stripped):]
    if stripped.endswith("."):
        core = stripped[:-1].rstrip()
        new = core + ", " + ref_html + "." + trailing_ws + after
        return new, True
    else:
        # pas de point final (ex. refs commentees) : on ajoute ', REF.'
        new = stripped + ", " + ref_html + "." + trailing_ws + after
        return new, True

def build_new_item(new_id, name, refs_html, list_indent):
    name_esc = xml_escape(name)
    refs = ", ".join(refs_html)
    item = ('<item xml:id="%s"><rs><hi rend="sc">%s</hi></rs>, %s.</item>'
            % (new_id, name_esc, refs))
    return list_indent + item + "\n"

def sortkey(name):
    s = name.lower()
    trans = str.maketrans("àáâãäåèéêëìíîïòóôõöùúûüçñ", "aaaaaaeeeeiiiiooooouuuucn")
    s = s.translate(trans)
    s = re.sub(r"^[^\wà-ÿ]+", "", s)
    return s

def initial_letter(name):
    s = sortkey(name)
    for ch in s:
        if ch.isalpha():
            return ch.upper()
    return None

def find_list_bounds(lines, list_xmlid):
    """Retourne (start_line, end_line) : start = ligne de <list ...>, end =
    ligne de </list> correspondante."""
    start = None
    for i, l in enumerate(lines):
        if 'xml:id="%s"' % list_xmlid in l and "<list" in l:
            start = i
            break
    if start is None:
        return None, None
    for j in range(start + 1, len(lines)):
        if "</list>" in lines[j]:
            return start, j
    return start, None

def insert_item_alpha(lines, list_start, list_end, new_line, name):
    """Insere new_line dans la liste en position alphabetique par 'name'.
    Insere avant le 1er item existant dont le nom trie est > name."""
    key = sortkey(name)
    insert_at = list_end  # par defaut avant </list>
    for i in range(list_start + 1, list_end):
        line = lines[i]
        if "<item" not in line:
            continue
        m = HI_RE.search(line)
        if not m:
            continue
        other = strip_inner_tags(m.group("hi")).strip()
        if sortkey(other) > key:
            insert_at = i
            break
    lines.insert(insert_at, new_line)
    return insert_at


# ---------------------------------------------------------------------------
# 4. MAIN
# ---------------------------------------------------------------------------

def main():
    ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")

    # backups
    for path in (IDX_PERS, IDX_LIEUX):
        with open(path, "rb") as f:
            data = f.read()
        bak = path.replace(".xml", ".before_ssco_censier_%s.xml" % ts)
        with open(bak, "wb") as f:
            f.write(data)
        print("backup:", os.path.basename(bak))

    entries = parse_censier()
    print("entrees censier extraites:", len(entries))

    # charger fiches existantes
    pers_lines, pers_fiches = load_existing(IDX_PERS)
    lieu_lines, lieu_fiches = load_existing(IDX_LIEUX)

    pers_index = {}
    for fi in pers_fiches:
        pers_index.setdefault(fi["norm"], fi)  # 1er gagne
    lieu_index = {}
    for fi in lieu_fiches:
        lieu_index.setdefault(fi["norm"], fi)

    # separer par type et regrouper les NOUVEAUX par (type, noyau normalise)
    csv_rows = []
    # actions differees
    pers_ref_adds = {}   # li -> [ref_html,...]
    lieu_ref_adds = {}
    new_groups = {}      # (type, norm) -> dict(name, type, refs=[(page,pbid)], raws=[])

    n_skip = 0
    for e in entries:
        if e.get("rubrique"):
            csv_rows.append([e["name"], e["type"], e["page"],
                             "SKIPPED_RUBRIQUE", e["raw"]])
            n_skip += 1
            continue
        norm = normalize_core(e["name"])
        if not norm:
            csv_rows.append([e["name"], e["type"], e["page"], "NON_PARSABLE", e["raw"]])
            continue
        if e["type"] == "LIEU":
            idx = lieu_index
        else:
            idx = pers_index
        match = idx.get(norm)
        # GARDE-FOU anti-homonymes : un noyau normalise reduit a un seul token
        # (praenomen nu, ex. 'Robertus' apres avoir retire 'canonicus') est trop
        # ambigu -> on NE matche PAS et on cree une fiche (reversible), comme
        # demande par la consigne ("en cas de doute, ne matche pas").
        if match and len(norm.split()) < 2:
            match = None
        if match:
            # ajout differe (une ref par entree ; on dedoublonne par page)
            ref = (e["page"], e["pb_id"])
            store = pers_ref_adds if e["type"] == "PERSONNE" else lieu_ref_adds
            lst = store.setdefault(match["li"], {"refs": [], "id": match["id"]})
            if ref not in [(p, i) for (p, i) in lst["refs"]]:
                lst["refs"].append(ref)
            csv_rows.append([e["name"], e["type"], e["page"],
                             "REF_AJOUTEE->%s" % match["id"], e["raw"]])
        else:
            # regroupement fin : conserve les fonctions distinctives
            gk = group_key(e["name"])
            key = (e["type"], gk)
            disp = display_name(e["name"])
            g = new_groups.setdefault(key, {
                "name": disp, "type": e["type"], "refs": [], "raws": []})
            # garder le nom d'affichage le plus complet (le plus long)
            if len(disp) > len(g["name"]):
                g["name"] = disp
            ref = (e["page"], e["pb_id"])
            if ref not in g["refs"]:
                g["refs"].append(ref)
            g["raws"].append(e["raw"])

    # --- appliquer les ajouts de ref sur fiches existantes ---
    def apply_ref_adds(lines, adds):
        cnt = 0
        for li, info in adds.items():
            refs_html = [build_ref(p, i) for (p, i) in info["refs"]]
            joined = ", ".join(refs_html)
            newline, ok = add_ref_to_line(lines[li], joined)
            if ok:
                lines[li] = newline
                cnt += 1
        return cnt

    n_ref_pers = apply_ref_adds(pers_lines, pers_ref_adds)
    n_ref_lieu = apply_ref_adds(lieu_lines, lieu_ref_adds)

    # --- creer les nouvelles fiches ---
    counter = 0
    def next_id():
        nonlocal counter
        counter += 1
        return "SSCO-AB_censier_rs_%04d" % counter

    # indentation type d'un item de liste : on prend l'indentation d'un item
    def sample_indent(lines, list_start, list_end):
        for i in range(list_start + 1, list_end):
            if "<item" in lines[i]:
                m = re.match(r"[ \t]*", lines[i])
                return m.group(0)
        return ""

    n_new_pers = 0
    n_new_lieu = 0
    # trier les groupes pour un ordre de creation stable (par nom)
    for key in sorted(new_groups.keys(), key=lambda k: (k[0], sortkey(new_groups[k]["name"]))):
        g = new_groups[key]
        typ = g["type"]
        name = g["name"]
        new_id = next_id()
        refs_html = [build_ref(p, i) for (p, i) in g["refs"]]
        if typ == "LIEU":
            lines = lieu_lines
            prefix = "index_lieu_liste_"
        else:
            lines = pers_lines
            prefix = "index_personne_liste_"
        letter = initial_letter(name)
        if letter is None:
            letter = "A"
        list_id = prefix + letter
        ls, le = find_list_bounds(lines, list_id)
        if ls is None:
            # lettre absente : rattacher a la lettre la plus proche existante
            # (fallback : parcourir l'alphabet en arriere)
            import string
            alpha = string.ascii_uppercase
            pos = alpha.index(letter)
            found = False
            for delta in range(1, 26):
                for cand in (alpha[(pos - delta) % 26], alpha[(pos + delta) % 26]):
                    lid = prefix + cand
                    ls, le = find_list_bounds(lines, lid)
                    if ls is not None:
                        found = True
                        break
                if found:
                    break
        indent = sample_indent(lines, ls, le)
        new_line = build_new_item(new_id, name, refs_html, indent)
        insert_item_alpha(lines, ls, le, new_line, name)
        pages = ",".join(str(p) for (p, i) in g["refs"])
        csv_rows.append([name, typ, pages, "FICHE_CREEE->%s" % new_id,
                         " | ".join(g["raws"])])
        if typ == "LIEU":
            n_new_lieu += 1
        else:
            n_new_pers += 1

    # --- ecrire les fichiers (UTF-8 sans BOM, LF) ---
    def write_lines(path, lines):
        with io.open(path, "w", encoding="utf-8", newline="") as f:
            f.write("".join(lines))

    write_lines(IDX_PERS, pers_lines)
    write_lines(IDX_LIEUX, lieu_lines)

    # --- CSV rapport ---
    csv_path = os.path.join(AUDIT, "ssco_censier_applique.csv")
    with io.open(csv_path, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["nom", "type", "page(s)", "action", "source"])
        for r in csv_rows:
            w.writerow(r)

    print("---")
    print("refs ajoutees a fiches existantes  : personnes=%d lieux=%d" % (n_ref_pers, n_ref_lieu))
    print("nouvelles fiches creees            : personnes=%d lieux=%d" % (n_new_pers, n_new_lieu))
    print("rubriques ignorees (SKIPPED)       :", n_skip)
    print("total entrees traitees             :", len(entries))
    print("CSV:", csv_path)
    return {
        "n_ref_pers": n_ref_pers, "n_ref_lieu": n_ref_lieu,
        "n_new_pers": n_new_pers, "n_new_lieu": n_new_lieu,
        "total": len(entries), "csv": csv_path, "ts": ts,
    }

if __name__ == "__main__":
    main()
