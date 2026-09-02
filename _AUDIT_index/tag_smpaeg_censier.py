# -*- coding: utf-8 -*-
"""
tag_smpaeg_censier.py

Baliser (persName / placeName) les noms de personnes et de lieux dans le
CENSIER de Saint-Merry (SMPA-EG), première passe conservatrice (haute precision).

Perimetre STRICT :
  - fichier data/SMPA-EG.xml uniquement ;
  - uniquement entre les marqueurs
        <!-- BEGIN SMPA-EG CENSIER WORKING COPY -->
        ...
        <!-- END SMPA-EG CENSIER WORKING COPY -->
  - uniquement dans les <div type="transcription"> ;
  - uniquement dans les <p> de transcription qui NE sont PAS <p type="note"> ;
  - on ne touche jamais aux <pb .../> (attributs) ni au texte deja balise.

Style de balisage : imite le corpus (ex. NDMA/NDMT) -> balises nues
  <persName>...</persName> et <placeName>...</placeName>, le mot introducteur
  (rue, porte, eglise, meison...) reste HORS de la balise, on n'englobe que le
  nom propre (prenom + byname "de X" / "le X" pour la meme personne).

Sortie :
  - reecrit data/SMPA-EG.xml en place (UTF-8, sans BOM, fins de ligne inchangees) ;
  - ecrit _AUDIT_index/smpaeg_censier_tags.csv (type,texte,article,page,contexte).

Le backup doit avoir ete fait AVANT par l'appelant.
"""
import re
import csv
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
XML = os.path.join(ROOT, "data", "SMPA-EG.xml")
CSV_OUT = os.path.join(ROOT, "_AUDIT_index", "smpaeg_censier_tags.csv")

BEGIN = "<!-- BEGIN SMPA-EG CENSIER WORKING COPY -->"
END = "<!-- END SMPA-EG CENSIER WORKING COPY -->"

# ---------------------------------------------------------------------------
# Vocabulaire de reference (graphies telles qu'elles apparaissent dans le texte)
# ---------------------------------------------------------------------------

# Prenoms medievaux (ancien/moyen francais + formes latines) attestes dans le
# censier ou l'index. On reste sur des prenoms non ambigus.
FORENAMES = {
    # francais
    "Jehan", "Jehane", "Jehanne", "Pierre", "Perrin", "Perronelle",
    "Guilleume", "Guillaume", "Guillot", "Guiart", "Guy", "Gui",
    "Estiene", "Estienne", "Robert", "Thomas", "Richart", "Richard",
    "Jaque", "Jaquet", "Jaqueline", "Symon", "Simon", "Nicholas", "Nicole",
    "Henri", "Michiel", "Michel", "Raoul", "Heude", "Eude", "Hue", "Huon",
    "Adam", "Alain", "Rogier", "Roger", "Girart", "Girard", "Gerart",
    "Daniel", "Aubert", "Lambert", "Andri", "Andriu", "Andrieu", "Hervi",
    "Hervieu", "Geufroi", "Geufroy", "Gieffre", "Gieffroi", "Gieffroy",
    "Maci", "Mace", "Katherine", "Katerine", "Ysabieu", "Ysabel", "Isabeau",
    "Margarite", "Marguerite", "Marie", "Basile", "Gile", "Gille",
    "Gencien", "Bertaut", "Bertault", "Colin", "Colart", "Ancel",
    "Baudouin", "Baudoin", "Arnoul", "Ernoul", "Renaut", "Renaud", "Renier",
    "Renier", "Eustache", "Evrart", "Evrard", "Gautier", "Gauthier",
    "Vincent", "Yves", "Yve", "Clement", "Denise", "Doulce", "Erembourc",
    "Erembourg", "Jourdain", "Lancelot", "Laurens", "Laurent", "Lucas",
    "Martin", "Maurice", "Odart", "Odard", "Philippe", "Phelippe",
    "Thibaut", "Thibault", "Tiebaut", "Tiebout", "Thierry", "Agnes", "Agnès",
    "Aden", "Adenot", "Gencelin", "Enjorren", "Enjoren", "Gandolfe",
    "Berthelot", "Berthelemi", "Berthemi", "Sanson", "Sandrin", "Ameline",
    "Aveline", "Emeline", "Jaquemin", "Jaquemart", "Colinet",
    "Nicholaus", "Petrus", "Johannes", "Robertus", "Guillelmus", "Stephanus",
    "Odo", "Hugo", "Radulfus", "Simon", "Michael",
}

# Formes latines de prenoms => tag mais sans byname francais (contextes latins)
LATIN_FORENAMES = {
    "Nicholaus", "Petrus", "Johannes", "Robertus", "Guillelmus",
    "Stephanus", "Odo", "Hugo", "Radulfus", "Michael", "Guido",
}

# Toponymes / hagionymes surs (partie apres rue/porte/eglise/... = nom propre).
# Noms de saints frequents pour rues, portes, paroisses, autels.
SAINT_NAMES = {
    "Merri", "Merry", "Martin", "Denis", "Germain", "Remi", "Remy",
    "Jaque", "Jaques", "Jacques", "Estiene", "Estienne", "Anthoine",
    "Antoine", "Ladre", "Lazare", "Gervais", "Gervès", "Innocent",
    "Innocens", "Ynnocens", "Ynnocens", "Marceau", "Marcel", "Jehan",
    "Sepulchre", "Josse", "Bon", "Leu", "Gille", "Gilles", "Nicolas",
    "Nicholas", "Katherine", "Genevieve", "Geneviève", "Croix", "Esperit",
}

# Toponymes parisiens surs, tagues comme placeName la ou ils apparaissent
# comme lieu (Temple, Encloistre, Chastellet, Biaubourc, etc.).
STANDALONE_PLACES = {
    "Encloistre", "Biaubourc", "Beaubourc", "Chastellet", "Trinite",
    "Trinité", "Grève", "Greve", "Baudoyer", "Baudoel",
}

# Titres / mots qui precedent un nom (a laisser hors de la balise, mais qui
# aident a confirmer qu'un anthroponyme suit).
TITLE_HINT = {
    "mestre", "messire", "mons", "monseigneur", "monsseigneur", "sire",
    "feu", "feue", "dame", "damoiselle", "maistre", "monsieur",
}

# ---------------------------------------------------------------------------
# Regex de construction des spans
# ---------------------------------------------------------------------------

# Un "token capitalise" (mot commencant par majuscule, avec lettres/accents/tiret)
CAPWORD = r"[A-ZÉÈÊÀÂÎÏÔÛÇ][a-zA-Zàâäéèêëïîôûùçñ’'’\-]*"

# Connectifs de byname (particules) : de, du, des, le, la, l', d'
# On accepte une chaine : (particule + CAPWORD) repetee, ou CAPWORD nu.
PARTICLE = r"(?:de|du|des|le|la|les|l['’]|d['’])"

FORENAME_ALT = "|".join(sorted((re.escape(f) for f in FORENAMES), key=len, reverse=True))
SAINT_ALT = "|".join(sorted((re.escape(s) for s in SAINT_NAMES), key=len, reverse=True))
PLACE_ALT = "|".join(sorted((re.escape(s) for s in STANDALONE_PLACES), key=len, reverse=True))

# Un byname : une ou plusieurs unites, chaque unite = particule optionnelle + CAPWORD,
# ou bien un CAPWORD nu (surnom : Marceu, Aulart...).
BYUNIT = r"(?:\s+(?:" + PARTICLE + r"\s+)?" + CAPWORD + r")"
BYNAME = BYUNIT + r"*"

# persName : prenom (+ byname). On borne a droite : on ne traverse pas un
# separateur fort (virgule, ; : . apres) car le regex CAPWORD s'arrete sur
# la ponctuation de toute facon.
RE_PERS = re.compile(r"\b(?:" + FORENAME_ALT + r")" + BYNAME)

# placeName saint : le mot "S.", "Seint", "Seinte", "Sainte", "Saint" suivi du
# nom du saint (+ eventuel complement "de X"). On tague le nom propre y compris
# le "Seint" (comme le corpus latin tague "Sancti Martini de Campis").
# Le complement "de X" ne doit PAS engloutir un mot qui demarre un NOUVEAU
# hagionyme (Seint/Seinte/Saint/S/Nostre) : negative lookahead sur ce mot.
COMPL = (
    r"(?:\s+(?:de|du|des)\s+"
    r"(?!S\b|S\.|Seint\b|Seinte\b|Saint\b|Sainte\b|St\b|Ste\b|Nostre\b)"
    + CAPWORD + r")?"
)
RE_SAINT = re.compile(
    r"\b(?:S\.|Seint|Seinte|Saint|Sainte|Sein|Ste|St)\s+(?:" + SAINT_ALT + r")"
    + COMPL
)

# placeName toponyme isole
RE_PLACE = re.compile(r"\b(?:" + PLACE_ALT + r")\b")

# Detection des "jours de terme" (fetes) : "à le/la/l' " + saint-terme
FEAST_LEFT = re.compile(r"à\s+l[ea]?['’]?\s*$")
FEAST_SAINT = re.compile(r"(?:S\.|Seint|Seinte|Saint)\s+(?:Jehan|Remi|Remy)\b")

# ---------------------------------------------------------------------------
# Faux positifs a exclure explicitement (contextes ambigus)
# ---------------------------------------------------------------------------
# "Estiene de Nostre-Dame" / "S. Estiene" = autel/saint, pas une personne :
# gere par le fait que RE_SAINT capte "S. Estiene" AVANT, et par exclusion ci-dessous.
# On refuse de taguer comme persName un prenom immediatement precede de S./Seint.
PERS_LEFT_BLOCK = re.compile(r"(?:S\.|Seint|Seinte|Saint|Sainte|St|Ste)\s+$")

# Marqueurs de voie/lieu : si un nom (forme anthroponymique) est immediatement
# precede de "rue "/"porte "/"eglise "/"paroisse "/"carrefour ", c'est un nom
# de VOIE -> on le tague placeName (le proche derive d'un nom de personne).
STREET_LEFT = re.compile(
    r"(?:rue|Rue|porte|Porte|eglise|église|Eglise|paroisse|parroisse|"
    r"carrefour|kairefourc|cairefourc|carrefourc|cul-de-sac|ruelle)\s+$"
)

# Mots communs capitalises en debut de phrase a NE PAS prendre comme surnom/toponyme.
COMMON_CAP_STOP = {
    "Item", "Ce", "Les", "Le", "La", "En", "Il", "Et", "Ou", "Summa",
    "Rente", "Rentes", "Meison", "Meson", "Terme", "Premiere", "Premierement",
    "Fol", "Transcrit", "Asit", "Voy",
}


def find_transcription_paras(segment):
    """Renvoie une liste (start, end, inner) des <p> de transcription NON-note,
    a l'interieur des <div type="transcription">, dans 'segment'."""
    spans = []
    for div in re.finditer(
        r'<div type="transcription"[^>]*>(.*?)</div>', segment, re.S
    ):
        div_inner_start = div.start(1)
        div_inner = div.group(1)
        # p non-note : <p> ... </p>  (on exclut <p type="note">)
        for p in re.finditer(r"<p>(.*?)</p>", div_inner, re.S):
            abs_start = div_inner_start + p.start(1)
            abs_end = div_inner_start + p.end(1)
            spans.append((abs_start, abs_end, p.group(1)))
    return spans


def protect_pb(text):
    """Remplace chaque <pb .../> par un placeholder pour ne jamais matcher dedans.
    Renvoie (texte_protege, mapping)."""
    placeholders = {}
    idx = [0]

    def repl(m):
        key = "\x00PB%d\x00" % idx[0]
        placeholders[key] = m.group(0)
        idx[0] += 1
        return key

    protected = re.sub(r"<pb\b[^>]*/>", repl, text)
    return protected, placeholders


def restore_pb(text, placeholders):
    for key, val in placeholders.items():
        text = text.replace(key, val)
    return text


def build_intervals(text):
    """Calcule les intervalles a baliser dans 'text' (deja protege des pb).
    Renvoie liste de (start, end, tag, matched_text), sans chevauchement,
    priorite placeName-saint > placeName-toponyme > persName."""
    taken = []  # liste de (start, end)

    def overlaps(s, e):
        for (a, b) in taken:
            if s < b and a < e:
                return True
        return False

    results = []

    # 1) placeName saint (le plus specifique)
    for m in RE_SAINT.finditer(text):
        s, e = m.start(), m.end()
        if overlaps(s, e):
            continue
        # Exclusion "jour de terme" : "à le/la/l' S. Jehan|Remi" = fete (date de
        # paiement), pas un lieu -> ne pas taguer. Saints-termes parisiens.
        if FEAST_LEFT.search(text[max(0, s - 8):s]) and FEAST_SAINT.search(
            m.group(0)
        ):
            continue
        taken.append((s, e))
        results.append((s, e, "placeName", m.group(0)))

    # 2) placeName toponyme isole
    for m in RE_PLACE.finditer(text):
        s, e = m.start(), m.end()
        if overlaps(s, e):
            continue
        taken.append((s, e))
        results.append((s, e, "placeName", m.group(0)))

    # 3) persName
    for m in RE_PERS.finditer(text):
        s, e = m.start(), m.end()
        if overlaps(s, e):
            continue
        # bloquer si precede immediatement par S./Seint (=> saint, pas personne)
        left = text[max(0, s - 12):s]
        if PERS_LEFT_BLOCK.search(left):
            continue
        # premier mot ne doit pas etre un mot commun capitalise
        first = re.match(CAPWORD, text[s:e]).group(0)
        if first in COMMON_CAP_STOP:
            continue
        # nom precede d'un marqueur de voie => nom de VOIE (placeName)
        left_full = text[max(0, s - 12):s]
        this_tag = "persName"
        if STREET_LEFT.search(left_full):
            this_tag = "placeName"
        taken.append((s, e))
        results.append((s, e, this_tag, m.group(0)))

    results.sort(key=lambda r: r[0])
    return results


def apply_tags(text, intervals):
    """Insere les balises dans 'text' selon 'intervals' (tries croissants)."""
    out = []
    prev = 0
    for (s, e, tag, _t) in intervals:
        out.append(text[prev:s])
        out.append("<%s>%s</%s>" % (tag, text[s:e], tag))
        prev = e
    out.append(text[prev:])
    return "".join(out)


def context_of(full, abs_pos, width=60):
    a = max(0, abs_pos - width // 2)
    b = min(len(full), abs_pos + width // 2)
    ctx = full[a:b]
    ctx = re.sub(r"\s+", " ", ctx)
    ctx = re.sub(r"<pb\b[^>]*/>", "", ctx)
    return ctx.strip()


def main():
    with open(XML, "r", encoding="utf-8", newline="") as f:
        content = f.read()

    b = content.find(BEGIN)
    e = content.find(END)
    if b == -1 or e == -1 or e <= b:
        print("ERREUR: marqueurs censier introuvables.", file=sys.stderr)
        sys.exit(2)

    head = content[:b]
    segment = content[b:e]          # zone censier (marqueur BEGIN inclus)
    tail = content[e:]

    # localiser article courant (xml:id ..._censier_NNNN) et page (pb n=...)
    # pour le CSV : on precalcule les positions des <text ...censier...> et <pb>
    text_marks = [
        (m.start(), m.group(1))
        for m in re.finditer(r'<text xml:id="(SMPA-EG_censier_\d+)"', segment)
    ]
    pb_marks = [
        (m.start(), m.group(1))
        for m in re.finditer(r'<pb n="([^"]+)"', segment)
    ]

    def article_at(pos):
        cur = None
        for (mp, aid) in text_marks:
            if mp <= pos:
                cur = aid
            else:
                break
        return cur or ""

    def page_at(pos):
        cur = ""
        for (mp, pn) in pb_marks:
            if mp <= pos:
                cur = pn
            else:
                break
        return cur

    paras = find_transcription_paras(segment)

    csv_rows = []
    n_pers = 0
    n_place = 0
    touched = 0

    # On reconstruit le segment en remplacant chaque <p> transcription par sa
    # version balisee. On traite de la fin vers le debut pour garder les offsets.
    seg_list = list(segment)
    for (p_start, p_end, inner) in sorted(paras, key=lambda x: x[0], reverse=True):
        protected, ph = protect_pb(inner)
        intervals = build_intervals(protected)
        if not intervals:
            continue
        tagged_protected = apply_tags(protected, intervals)
        tagged = restore_pb(tagged_protected, ph)
        # remplacement dans seg_list
        seg_list[p_start:p_end] = list(tagged)
        touched += 1
        # CSV : positions absolues (dans le segment original) pour article/page
        art = article_at(p_start)
        pg = page_at(p_start)
        for (s, e_, tag, matched) in intervals:
            # retirer placeholders eventuels du texte matche
            mtext = restore_pb(matched, ph)
            ctx = context_of(protected, s)
            ctx = restore_pb(ctx, ph)
            if tag == "persName":
                n_pers += 1
            else:
                n_place += 1
            csv_rows.append({
                "type": tag,
                "texte": mtext,
                "article": art,
                "page": pg,
                "contexte": ctx,
            })

    new_segment = "".join(seg_list)
    new_content = head + new_segment + tail

    with open(XML, "w", encoding="utf-8", newline="") as f:
        f.write(new_content)

    # trier le CSV par article puis type
    csv_rows.sort(key=lambda r: (r["article"], r["type"], r["texte"]))
    with open(CSV_OUT, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(
            f, fieldnames=["type", "texte", "article", "page", "contexte"]
        )
        w.writeheader()
        for r in csv_rows:
            w.writerow(r)

    print("persName ajoutes :", n_pers)
    print("placeName ajoutes:", n_place)
    print("paragraphes touches:", touched)
    print("CSV:", CSV_OUT)


if __name__ == "__main__":
    main()
