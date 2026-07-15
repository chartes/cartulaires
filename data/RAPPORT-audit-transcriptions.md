# Audit des erreurs de transcription XML

Date de l'audit : 15 juillet 2026.

## Objet et méthode

Cet audit porte sur les transcriptions de tous les fichiers XML du dossier `data`, et non sur les seuls témoins, les seuls fichiers récemment modifiés ou les seuls cartulaires NDPA.

Le corpus analysé comprend 35 fichiers XML (dont `MAUB-AB-02.xml`, vide), 12 308 actes, 12 009 divisions de transcription et 26 538 609 caractères. Un lien direct vers un fac-similé est présent dans un `<pb>` pour 7 801 actes ; 4 507 actes ne disposent pas d'un tel lien dans le XML.

Le contrôle a été effectué en trois temps :

1. analyse XML structurée de toutes les divisions `div[@type="transcription"]` ;
2. détection de mots soudés, corruptions d'encodage, répétitions et formes rares proches d'une forme fréquente ;
3. comparaison manuelle des candidats prioritaires avec les images de Gallica, Internet Archive, Bayerische Staatsbibliothek et Persée.

Le fichier [audit-transcriptions-candidats.csv](audit-transcriptions-candidats.csv) contient le tri automatique complet. Ses 11 944 lignes sont des **candidats**, pas 11 944 erreurs : la grande majorité des formes rares sont des graphies historiques, des noms propres ou des leçons de l'édition.

Le fichier [audit-transcriptions-verifiees.csv](audit-transcriptions-verifiees.csv) contient la liste courte avec statut, acte, page, lecture XML, lecture imprimée et lien de preuve.

## Résultat principal

Vingt actes ont été directement contrôlés sur une image et présentent un écart certain. Deux autres actes de `SMCP-PR.xml` répètent exactement la note fautive déjà confirmée p. 43 (`MaroIles` pour `Marolles`). Au total, la liste vérifiée concerne donc 22 actes, 34 substitutions textuelles et un `<pb>` mal placé.

Aucun XML n'a été corrigé pendant cet audit.

## Erreurs confirmées

| Fichier | Acte | Page | XML | Imprimé / correction |
|---|---|---:|---|---|
| `HDPO-HD.xml` | `HDPO-HD_0022` | 15 | `Domns Dei` | `Domus Dei` |
| `HDPO-HD.xml` | `HDPO-HD_0052` | 33 | `JohannesFrancie` | `Johannes Francie` |
| `HDPO-HD.xml` | `HDPO-HD_0083` | 56 | `bargensis` | `burgensis` |
| `NDPR-AB.xml` | `NDPR-AB_0137` | 137 | `Actum auno` | `Actum anno` |
| `NDVC-AB.xml` | `NDVC-AB_0226` | 220 | `lilteras` | `litteras` |
| `NDVC-AB.xml` | `NDVC-AB_0321` | 296 | `salatem` | `salutem` |
| `NDVC-AB.xml` | `NDVC-AB_0403` | 370 | `lilteras` | `litteras` |
| `NDVC-AB.xml` | `NDVC-AB_0448` | 409 | `dieti abbas` | `dicti abbas` |
| `NDVC-AB.xml` | `NDVC-AB_0640` | 598 | `faturi, qaod` | `futuri, quod` |
| `NDVC-AB.xml` | `NDVC-AB_0693` | 648 | `apod` | `apud` |
| `SCHA-PR.xml` | `SCHA-PR_0012` | 11 | `sanctiChristofori` | `sancti Christofori` |
| `SCOR-EG.xml` | `SCOR-EG_0014` | 27 | `StephaniBerruarii` | `Stephani Berruarii` |
| `SCOR-EG.xml` | `SCOR-EG_0096` | 178 | `anao ab incarnatione` | `anno ab incarnatione` |
| `SCOR-EG.xml` | `SCOR-EG_0178` | 267 | `homnibus` | `hominibus` |
| `SCOR-EG.xml` | `SCOR-EG_0263` | 357-358 | `JohannesBelehere`, puis `<pb n="358">` | `Johannes` finit p. 357 et `Belehere` commence p. 358 : espace à ajouter et `<pb>` à déplacer entre les mots |
| `SCOR-EG.xml` | `SCOR-EG_0289` | 385 | `SanctiPaterni` | `Sancti Paterni` |
| `SMCP-PR.xml` | `SMCP-PR_0214` | 40 | `Sancli Leonorii` | `Sancti Leonorii` |
| `SMCP-PR.xml` | `SMCP-PR_0215`, `_0263`, `_0406` | 43, 123, 313 | `MaroIles-en-Brie` | `Marolles-en-Brie` |
| `SMPA-AB-03.xml` | `SMPA-AB-03_64` | 137 | douze `?` dans la note 15 | accents et apostrophes imprimés : `Marnières`, `peut-être`, `Marnière`, `Sablonnière`, `située`, `à`, `lisière`, `qu’il`, `s’agisse`, etc. |
| `STEP-AB.xml` | `STEP-AB_0050` | 53 | `SanctiThome` | `Sancti Thome` |

## Anomalies qui ne sont pas des erreurs de transcription

Les lectures suivantes paraissent fautives linguistiquement, mais elles sont bien imprimées ainsi. Elles ne doivent pas être silencieusement « corrigées » comme erreurs d'OCR :

| Fichier | Acte | Page | Lecture commune au XML et à l'imprimé |
|---|---|---:|---|
| `HDPO-HD.xml` | `HDPO-HD_0058` | 38 | `quod quod` |
| `HDPO-HD.xml` | `HDPO-HD_0080` | 54 | `ejus ejus` |
| `NDMT-AB.xml` | `NDMT-AB_0003` | 63 | `nominus nostri` |
| `NDMT-AB.xml` | `NDMT-AB_0146` | 255 | `dcti prioratus` |
| `SCOR-EG.xml` | `SCOR-EG_0262` | 357 | `scitorum` |
| `SCOR-EG.xml` | `SCOR-EG_0358` | 480 | `mensse aprilli` |
| `SLES-PR.xml` | `SLES-PR_0108` | 105 | `eccclesie` |

## Candidats prioritaires encore à vérifier

Les candidats les plus nets non encore confirmés sont notamment :

| Fichier | Acte | Lecture XML | Lecture probable |
|---|---|---|---|
| `HDPAR-HD.xml` | `HDPAR-HD_0705` | `Santi Severini` | `Sancti Severini` |
| `MAUB-AB-01.xml` | `MAUB-AB-01_0274` | `mandamua` | `mandamus` |
| `MAUB-AB-01.xml` | `MAUB-AB-01_0438` | `suis suis juribus` | `suis juribus` |
| `NDMT-AB.xml` | `NDMT-AB_0004` | `tenneram` | `teneram` |
| `NDMV-AB.xml` | `NDMV-AB_0075` | `cens cens` | `cens` |
| `NDPA-EG-01.xml` | `NDPA-EG-01_0540` | `gordus gordus de Castello` | un seul `gordus` probable |
| `NDPA-EG-04.xml` | `NDPA-EG-04_0214` | `dictii Johannis` | `dicti Johannis` |
| `SAPC-AB.xml` | `SAPC-AB_0038`, `_0356` | `Parisicnsis`, `Parsiensis` | `Parisiensis` probable |
| `SLES-PR.xml` | `SLES-PR_0190` | `trecentesimo trecentesimo` | un seul `trecentesimo` probable |
| `SMCP-PR.xml` | `SMCP-PR_0459`, `_0524`, `_0835` | `Sanctii`, `ecelesie`, `annno` | `Sancti`, `ecclesie`, `anno` probables |
| `SMPA-AB-01.xml` | `SMPA-AB-01_0078` | `Acctum` | `Actum` probable |
| `SMPA-EG.xml` | `SMPA-EG_0050`, `_0054` | `Perisiensis`, `Prarisiensis` | `Parisiensis` probable |
| `STEP-AB.xml` | `STEP-AB_0039`, `_0073` | `Saucti`, `saluttem` | `Sancti`, `salutem` probables |

Pour `MAUB-AB-01.xml`, l'édition est bien trouvée : *Cartulaire de l'abbaye de Maubuisson (Notre-Dame-la-Royale). Première partie*, publié par Adolphe Dutilleux et Joseph Depoin, Pontoise, 1890. Le `sourceDesc` [renvoie à Gallica](https://gallica.bnf.fr/ark:/12148/bpt6k992853w), mais les `<pb>` ne portent aucun lien de fac-similé ; les p. 132 et 163 doivent donc encore être raccordées manuellement aux images avant de statuer sur `mandamua` et `suis suis`.

Les signes `A?` et `fi?` de `SAPC-AB.xml` ont été laissés hors des erreurs confirmées : ils peuvent représenter une incertitude éditoriale ou une abréviation, et non une corruption d'encodage.

## Couverture par fichier

| Fichier | Actes | Transcriptions | Actes avec fac-similé direct | Erreurs confirmées / répétées |
|---|---:|---:|---:|---:|
| `HDPAR-HD.xml` | 868 | 868 | 0 | 0 |
| `HDPO-HD.xml` | 183 | 182 | 183 | 3 |
| `MAUB-AB/MAUB-AB-01.xml` | 461 | 461 | 0 | 0 |
| `MAUB-AB/MAUB-AB-02.xml` | 0 | 0 | 0 | 0 |
| `NDCH-EG.xml` | 395 | 322 | 395 | 0 |
| `NDMA-AB.xml` | 42 | 41 | 42 | 0 |
| `NDMT-AB.xml` | 194 | 165 | 194 | 0 |
| `NDMV-AB.xml` | 110 | 110 | 110 | 0 |
| `NDPA-EG/NDPA-EG-01.xml` | 613 | 613 | 355 | 0 |
| `NDPA-EG/NDPA-EG-02.xml` | 928 | 928 | 444 | 0 |
| `NDPA-EG/NDPA-EG-03.xml` | 627 | 627 | 316 | 0 |
| `NDPA-EG/NDPA-EG-04.xml` | 364 | 364 | 173 | 0 |
| `NDPR-AB.xml` | 337 | 295 | 337 | 1 |
| `NDRC-AB.xml` | 135 | 135 | 135 | 0 |
| `NDVC-AB.xml` | 1 092 | 1 091 | 1 092 | 6 |
| `SAPC-AB.xml` | 395 | 395 | 0 | 0 |
| `SCCO-AB/SCCO-AB-01.xml` | 324 | 324 | 0 | 0 |
| `SCCO-AB/SCCO-AB-02.xml` | 351 | 351 | 0 | 0 |
| `SCCO-AB/SCCO-AB-03.xml` | 269 | 269 | 0 | 0 |
| `SCHA-PR.xml` | 70 | 70 | 70 | 1 |
| `SCOR-EG.xml` | 387 | 386 | 387 | 5 |
| `SGDP-AB.xml` | 477 | 477 | 404 | 0 |
| `SGGO-PR.xml` | 35 | 35 | 35 | 0 |
| `SGLY-PR.xml` | 26 | 23 | 0 | 0 |
| `SLES-PR.xml` | 222 | 169 | 222 | 0 |
| `SMCP-PR.xml` | 1 375 | 1 326 | 1 374 | 4 |
| `SMMI-AB.xml` | 372 | 372 | 0 | 0 |
| `SMPA-AB/SMPA-AB-01.xml` | 282 | 282 | 275 | 0 |
| `SMPA-AB/SMPA-AB-02.xml` | 418 | 418 | 366 | 0 |
| `SMPA-AB/SMPA-AB-03.xml` | 375 | 375 | 347 | 1 |
| `SMPA-EG.xml` | 57 | 57 | 35 | 0 |
| `SMPO-AB.xml` | 221 | 209 | 221 | 0 |
| `SSCO-AB.xml` | 125 | 124 | 125 | 0 |
| `STEP-AB.xml` | 135 | 102 | 135 | 1 |
| `VNDP-AB.xml` | 43 | 43 | 29 | 0 |

Cette colonne « erreurs confirmées » ne signifie pas que les autres fichiers sont exempts d'erreurs : elle indique seulement le nombre d'actes déjà validés visuellement dans ce passage d'audit.
