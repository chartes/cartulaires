from lxml import etree

TEI_NS = "http://www.tei-c.org/ns/1.0"
NS = {"tei": TEI_NS}

def pass_ensure_front_has_index(tree, default_type="tbd") -> int:
    """
    Ajoute <index type="{default_type}"/> dans chaque tei:front qui n'en a pas.
    - Ne touche pas aux front qui ont déjà un index
    - Insère en premier enfant élément du front (déterministe)
    """
    changed = 0
    for front in tree.xpath("//tei:front[not(tei:index)]", namespaces=NS):
        idx = etree.Element(f"{{{TEI_NS}}}index")
        idx.set("type", default_type)

        # insertion en premier enfant (avant tout élément existant)
        front.insert(0, idx)
        changed += 1

    return changed
