# Audit index personnes / lieux — récapitulatif

Fichiers concernés : `data/INDEX-PERSONNES.xml` (35 602 fiches), `data/INDEX-LIEUX.xml` (6 822 fiches).
Backups horodatés créés dans `data/` (`*.before_censier_link_*.xml`).

---

## Tâche 1 — Liage au censier ✅ APPLIQUÉ

Les références censier étaient encodées **en commentaire**, format
`<!--, C <ref n="484" type="censier">484</ref>-->`, où `n` = **numéro de page**
du censier de l'Hôtel-Dieu (HDPAR-HD).

- Vérifié : les 23 pages référencées ont toutes un `<pb xml:id="HDPAR-HD_censier_pNNN">` cible (0 orphelin).
- Transformation appliquée (décommentage + ajout `target`) :
  `, C <ref n="484" type="censier" target="#HDPAR-HD_censier_p484">484</ref>`
- **946 refs activées dans PERSONNES + 75 dans LIEUX** (toutes HDPAR-HD). XML re-validé bien formé.
- Les refs d'**actes** HDPAR restent commentées (liage d'actes = autre chantier, non demandé).

### Reste à faire (non couvert, plus lourd)
Les censiers **SSCO** (102 articles `SSCO-AB_censier_*`) et **SMPA** récemment encodés
n'ont **aucune occurrence dans l'index** : il faudrait extraire les noms de personnes/lieux
de leur texte et créer de nouvelles fiches/refs (travail type NER).

---

## Tâche 2 — Faux positifs de catégorie ⏳ LISTE À VALIDER

Méthode : signal de la catégorie opposée **sans** signal de sa propre catégorie = « fort ».

- `faux_positifs_FORTS.csv` — **359 fiches haute confiance** :
  - **352 lieux classés dans PERSONNES** (concentration : SMPA-AB-01=149, SLES-PR=84, SMPO-AB=30).
    Ex. « Becherel (Terroir de) », « Bouticon, lieu-dit à Compans », « Yverneaux (abbaye d') ».
    Aucun n'existe déjà dans LIEUX → déplacement additif, pas de doublon créé.
  - **7 personnes classées dans LIEUX** : Rollo dux Normannorum ; Suzanne sœur de Raoul le Plombier ;
    Eufémie femme de J. du Bois ; Arnoul fils d'Oudard / de Renard / serviteur ; Longchamp-moniales (renvoi).
- `faux_positifs_faibles.csv` — **13 fiches mixtes** à arbitrer (signaux des deux catégories).

**En attente de ta validation avant tout déplacement entre index.**

---

## Tâche 3 — Doublons ⏳ LISTE À VALIDER

⚠️ Le nom seul n'est PAS un doublon : le corpus distingue les homonymes par la parenté
(ex. 14 « Agnes » = 14 femmes différentes, identifiées par « v. … maritus/mater/filius ejus »).
Le tri strict ne retient donc que :

- `doublons_PERSONNES.csv` :
  - **EXACT : 5 paires strictement identiques** (refs commentées incluses) → dédoublonnage sûr :
    Gislebertus (Vide Gilebertus) ; Orielde ; Petrus (Frater) de Domo Dei ;
    Robinus (Stephanus) de Compenso ; Rogerius prior Vallium Sarnaii.
  - **MÊME_NOM_REFS : 15 groupes** même nom + mêmes refs, texte différent → à revoir.
- `doublons_LIEUX.csv` : 0 exact ; **5 groupes** à revoir (Machault ×6, Melun ×2, Paris ×2, Rambouillet ×2, Saint-Germain-des-Prés ×2).

Cas ambigu à trancher par toi : les HDPAR même-nom à refs (commentées) **différentes**
(ex. « Adam, presbyter » actes 12/19 vs 13) — même personne à fusionner en cumulant les refs,
ou deux homonymes ? Non fusionnés automatiquement.

**En attente de ta validation avant toute fusion.**

---

## Tâche 4 — Censiers SSCO et SMPA → index (EN COURS)

Objectif : faire entrer les personnes/lieux des censiers récemment encodés dans les index
(comme HDPAR : ref `type="censier"` sur la fiche, ou nouvelle fiche si absente).

**Localisation** : censier SSCO = `data/SSCO-AB.xml` (`<group SSCO-AB_censier_group>`, 35 articles) ;
censier SMPA = **`data/SMPA-EG.xml`** (119 articles, PAS dans SMPA-AB).

**Constat bloquant** : les DEUX censiers sont en **prose non balisée** (0 `<persName>`/`<placeName>`/`<rs>`
dans les transcriptions ; les 555 persName de SMPA-EG sont dans la partie *cartulaire*, pas le censier).
Granularité de lien disponible = article (`_censier_0003`) ou page/colonne (`_censier_p114_c3`).
Index déjà existant : SSCO = 477 pers + 69 lieux ; SMPA-EG = 2174 pers + 111 lieux (0 ref censier).

### SSCO — extractible (structure régulière)
Entrées « — Nom, montant. ». Extraction faite → `_AUDIT_index/censier_SSCO_candidats.csv` :
**556 entrées** (504 personnes, 52 lieux « Domus/Ecclesia… »), avec article/page cible et type.
Rapprochement exact avec fiches existantes = seulement 2 (déclinaisons latines/bynames → fuzzy nécessaire).
→ quasi toutes deviendraient de NOUVELLES fiches sous rapprochement naïf ; dédoublonnage fin à prévoir.

### SMPA-EG — non extractible proprement
795 paragraphes de prose discursive en ancien français (372 « Item… »), plusieurs noms enchâssés
par phrase (propriétaire, ancien propriétaire, voisins, rues), ~5000 tokens capitalisés très bruités.
Extraction automatique = faible précision. **Il faut baliser le censier (persName/placeName) d'abord**,
OU indexer manuellement, OU accepter une extraction bruitée à curer.

---

## Tâche 5 — Fusions probables (LISTE À VALIDER, complète)
`_AUDIT_index/FUSIONS_probables.csv` : **89 groupes / 186 fiches** au descriptif identique
(ne diffèrent que par les refs) → probablement même entité. Concentration HDPAR-HD (62), NDVC-AB (11),
SMPO-AB (8). Inclut des paires « forme inversée » (Boucelli (Jacobus) ↔ Jacobus Boucelli) = même
personne doublement indexée. ⚠️ Réserve : noms latins courants (Johannes Faber ×3, Guillelmus ×2)
peuvent être de vrais homonymes → arbitrage éditorial.

---

## Note de synchronisation

J'ai édité `data/INDEX-*.xml` (choix confirmé). La copie servie par DoTS est
`data/cartulaires_index/INDEX-*.xml` (id `cartulaires_index` dans `collection.tsv`) :
il faudra y **répercuter** les changements le moment venu.
