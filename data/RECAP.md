# Audit index personnes / lieux — état au 2026-08-28

## État vérifié

- `INDEX-PERSONNES.xml` et `INDEX-LIEUX.xml` sont les index de travail dans ce dossier.
- Les deux copies servies par DoTS ont été synchronisées dans `cartulaires_index/`.
- Les index racine et leurs copies synchronisées sont XML bien formés.
- Les fusions, déplacements de faux positifs et autres arbitrages humains n’ont pas été appliqués.

## Censier HDPAR

Les références `type="censier"` déjà activées dans les index sont conservées.

## Censier SSCO

L’intégration SSCO est déjà présente dans les index de travail :

- fiches portant des identifiants `SSCO-AB_censier_*` ;
- références `type="censier"` ciblant les ancres page/colonne `#SSCO-AB_censier_p...` ;
- personnes et lieux extraits séparément selon la nature de l’entrée.

Aucune fusion supplémentaire n’a été appliquée lors de cette reprise.

## Censier SMPA-EG

Le balisage conservateur du censier est présent dans `SMPA-EG.xml` et son backup est conservé dans `SMPA-EG.before_censier_tagging_20260828_152014.xml`.

L’extraction complète vers les index n’est pas appliquée automatiquement à ce stade : le texte est discursif, plusieurs noms sont enchâssés dans chaque paragraphe et certaines frontières personne/lieu restent à relire. Les balises présentes constituent la base de l’inventaire contrôlé à produire ensuite.

## Comptages XML vérifiés

- `INDEX-PERSONNES.xml` : 36 224 items, 1 412 références censier.
- `INDEX-LIEUX.xml` : 7 048 items, 134 références censier.
- `SMPA-EG.xml` : 1 911 `persName`, 775 `placeName` dans l’ensemble du fichier ; ces balises ne sont pas toutes dans le censier.

## Backups

Les backups de travail présents sont conservés :

- `INDEX-PERSONNES.before_ssco_censier_20260828_152732.xml`
- `INDEX-LIEUX.before_ssco_censier_20260828_152732.xml`
- `SMPA-EG.before_censier_tagging_20260828_152014.xml`
