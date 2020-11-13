
# Cartulaires. Guide d’annotation des Lieux

Plan :
- principes généraux
- balises et noms de lieu
- méthodologie de corrections proposée

## I. Principes généraux

### balises utilisées 

Pour annoter les noms de lieu, nous utiliserons les balises `<rs>` (cf. II.1 ) et `<placeName>` (cf. II.2).

### limites et bornes

Ne sont pas inclus dans la balise :

- les articles

```xml
l'<rs type="place">Arche de <placeName>Corbueil</placeName></rs>, ̀
```

- les diacritiques : ponctuation et guillemets

exemple :
```xml
prises sur l'<rs type="place">Arche de <placeName>Corbueil</placeName></rs>, ̀
```

- les pronoms personnels

exemple avec `ego`:
```xml
ego <rs type="person"><persName>Buccardus</persName> comes</rs>
```

- les adjectifs

Sauf si ils sont inclus dans l'empan de texte annoté :
...
TODO trouver un exemple

**!!! A noter :** L'annotation n'est donc pas discontinue.

### quelles corrections apportées ?

Les cartulaires sont déjà annotés. Le travail à effectuer consiste majoritairement à reprendre, homogénéiser et corriger les annotations en place. 

Ainsi :

- il est préconisé de travailler à partir de listes et de requêtes xpath pour plus d'efficacité. En effet, travailler par liste permet de s'appuyer sur les annotations en place et semble correspondre au mieux à l'homogénéisation du traitement des données  ;
- il est possible d'alterner le travail par lecture cursive d'un texte et le travail par liste, quand ce dernier devient pesant et contre productif ;
- dans un premier temps, par soucis de gain de temps et d'efficacité, il est préconisé de corriger les entités de type 'lieu', mais toute correction évidente (même sur les entités de type 'pers') est possible.
 
#### annotés les exemples à discuter

Il ne faut pas hésiter à repérer dans le texte annoté les doutes de correction. Les correcteurs et correctrices sont invités à utiliser l'argument `cert` pour indiquer une incertitude quand à l'annotation :

 ```xml
<placeName cert="unknown">Sancte Marie in Porticu</placeName>
```

La liste de valeurs proposées est :

- "unknown" : pour épingler une annotation que l'on souhaite rediscuter en groupe ;
- "low" : pour épingler une annotation très incertaine, à rediscuter ;
- "medium" :  pour épingler une annotation sur laquelle le correcteur ou la correctrice souhaite revenir, lors du travail de relecture (annotation d'avantage personnelle, pour lister ses propres doutes de relecture) ;
- "high" : pour épingler une annotation exemplaire, un exemple significatif qui pourrait être mis dans le manuel d'annotation.

**!!! A noter :** il est plus facile de repérer un exemple 'épinglé' au milieu d'une foule de données. Les arguments de type 'cert' pourront être le moment voulu supprimés en masse. Il ne faut donc pas hésiter à utiliser cette méthode!

## II. Balises et noms de lieu

### 1. Annotation avec la balise `<rs>`

Le nom de lieu avec des mots de la langue.

##### Cas 1 : `<rs type="place">`+`<placeName>`

Nom de lieu contenant un nom propre de lieu. Le lieu annoté est *composite*, c'est-à-dire composé de mots de la langue et d'un nom propre de lieu (balise `<placeName>`).

Exemples :
```xml
<rs type="place">Prata <placeName>Reculeti</placeName></rs> ad siccandum…
```

```xml
Omnibus presentes litteras inspecturis, officialis <rs type="place">curie
 <placeName>Carnotensis</placeName></rs>, salutem in Domino.....
```

##### Cas 2: `<rs type="place">`+`<persName>`

Nom de lieu contenant un nom propre de personne. Le lieu annoté est *composite*, c'est-à-dire composé de mots de la langue et d'un nom propre de personne (balise `<persName>`).

Exemples :

```xml
et in <rs type="place">bosco <persName>Buchardi</persName></rs>
```

<!--- in S-Leu-d-Esserent --->
```xml
<rs type="place">carrière <persName>Lambert</persName></rs>
```

```xml
infra pontem tornatilem et 
<rs type="place">portam molendini <persName>Folet</persName></rs>
```

##### cas 3 : utilisation de la seule balise `<rs>`

Il s'agit d'annoter des lieux désignés uniquement par des mots de la langue.

**!!! Attention :** Ne pas systématiser ce type d'annotation. Il en existe quelques cas dans les textes annotés : il s'agit de laisser ces annotations, mais de ne pas ajouter d'annotation de ce type. Nous rejetterons pour nos travaux ultérieurs ce type d'annotation.  

Exemples :
```xml
<rs type="place">Cuvam lapideam</rs>
```
```xml
<rs type="place">Abruvoir aus chevaus</rs>
```
```xml
<rs type="place">Silvam</rs>
```


##### Quantification, xpath et commentaires

**`rs[@type="place"]` : les lieux annotés contiennent au moins un mot de la langue.**

<!--- FMB à Vincent :
(Attention : l'ensemble des effectifs est de 143.L'addition des effectifs n'a pas pour somme 143, certains décompte ne sont pas exclusif.)
remarque entre parenthèse à garder ou non, à reformuler... bref : 449+11+2+25 est diff de 483 puisque placeName et persName peuvent être combinés! --->


|effectif|xpath|definition|exemple|commentaire|
|--------|-----|----------|-------|-----------|
|483|`//rs[@type='place']`|lieu avec des mots de la langue|||
|25|`//rs[@type='place' and not(placeName or persName)]`|lieu avec **uniquement** des mots de la langue|`<rs type="place">Chambre des Comptes</rs>`||
|449|`//rs[@type='place' and placeName]`|lieu avec des mots de la langue et un toponyme|`<rs type="place">Rue du <placeName>Roulle</placeName></rs>`||
|11|`//rs[@type='place' and persName]`|lieu avec des mots de la langue et un patronyme|`<rs type="place">carrière <persName>Lambert</persName></rs>`||
|2|`//rs[@type='place' and placeName and persName]`|lieu avec des mots de la langue, un toponyme **et** un patronyme|`<rs type="place">granchia ipsius <persName>Petri</persName> apud <placeName>Bellovidere</placeName></rs>`|chartes ou bien ?|


### 2. Annotation avec la seule balise `<placeName>`

Le nom de lieu est un nom propre (pas de `<rs>`).

* xpath: `//placeName[not(ancestor::rs)]`

Exemples :

```xml
Donné à <placeName>Pontoise</placeName>
```

```xml
 refutassem, ipse de prebendis et de ęcclesia abbatem et monachos
 <placeName>Majoris-Monasterii</placeName> investiret, et in usus et 
 potestatem eorum redigendas jure perpetuo confirmaret
```

##### Quantification, xpath et commentaires

|effectif|xpath|definition|exemple|commentaire|
|--------|-----|----------|-------|-----------|
|28151|`//placeName[not(ancestor::rs)]`|Un toponyme non inclus dans un `rs`|`<placeName>Chartres</placeName>`|à inclure souvent dans un `rs`?|



### 3. balises `person`et `persName` dans l'annotation de lieux

####  `placeName` dans `rs[@type="person"]`

Nom propre de lieu contenu dans une entité personne.

Par exemple :

```xml
<rs type="person">Roy de <placeName>France</placeName></rs>
```

#### `placeName` dans `persName`

**`placeName` dans `persName` ne devrait pas exister, en revanche, les deux peuvent faire partie d'un même `rs`**.

Désignation d’une personne avec uniquement des noms propres de personne et de lieu.

<!--- TODO on en fait quoi ?--->
**!!! Attention :** 
Ne pas systématiser ce type d'annotation. Il en existe quelques cas dans les textes annotés (13 occurrences), annotation discutable. Il faut plutôt **la corriger**.

- xpath:`//persName//placeName`

Exemples :

```xml
<persName>Radulphus, de <placeName>Pentin</placeName></persName>
```

doit devenir

```xml
<rs type="person"><persName>Radulphus</persName>, de <placeName>Pentin</placeName></rs>
```


```xml
<persName>Anneti dicti Patoul de <placeName>Sancto Lupo</placeName></persName>
```

doit devenir

```xml
<rs type="person"><persName>Anneti dicti Patoul</persName> de <placeName>Sancto Lupo</placeName></rs>
```

(ou?
```xml
<rs type="person"><persName>Anneti</persName> dicti <persName>Patoul</persName> de <placeName>Sancto Lupo</placeName></rs>
```
?

Autres exemples de cas problématiques:

```xml
<persName>Mathurina <placeName>Altebruerie</placeName></persName>
```
```xml
<persName>Pierre le Provost de <placeName>Champaignes</placeName></persName>
```
```xml
<persName>Gautier le Boucher de <placeName>Champaignes</placeName></persName>
```

## III. Méthodes de travail proposées

### Principes généraux

Chaque relectrice ou relecteur...
-  travaillera sur un ensemble de fichiers définis. L'ensemble des fichiers à corriger sera réparti entre les correctrices ;

NB: lire la description de l'état du corpus sur le document partagé.

Répartition proposée:

|ID|placeName|persName|rs place|rs pers|somme cumulée|répartition|
|--|--|--|--|--|--|--|
|Chartres-N-D|2932|3493|2|1624|8051|EG|
|Corbeil-S-Spire|842|1177|22|552|10644|EG|
|Epernon|981|876|5|421|12927|EG|
|Maintenon|273|318|8|114|13640|EG|
|Montmartre|1411|1837|77|625|17590|EG|
|Morienval|987|1006|22|461|20066|EG|
|Paris-S-Martin-des-Champs|10287|13717|40|6183|50293|EG|
|Orleans-S-Croix|3362|3619|37|1381|58692|MV|
|Paris-S-Merri|504|556|3|195|59950|MV|
|Pontoise-Hotel-Dieu|1160|1505|45|123|62783|MV|
|Pontoise-S-Martin|1560|3784|3|1128|69258|MV|
|Port-Royal|1376|1625|65|515|72839|MV|
|Roche|1215|1005|24|430|75513|MV|
|S-Christophe-en-Halatte|601|469|18|193|76794|MV|
|S-Germain-en-Laye|196|278|5|124|77397|MV|
|S-Gondon|352|769|0|269|78787|MV|
|S-Leu-d-Esserent|1046|1761|1|751|82346|MV|
|Vaux-de-Cernay|6380|8941|106|3215|100988|MV|
|**totaux**|35465|46736|483|18304|||


-  importera son jeu de données en local et le rapatriera régulièrement sur github (branch ner) **via des pull requests**.
- éditera les textes et travaillera sous Oxygen.

### Pistes de travail et requêtes Xpath

Il s'agit ici d'aider à prendre en main les données et le travail de relecture. A chacune et chacun des relecteurs de commenter, augmenter, améliorer les méthodologies proposées.

Les tâches suivantes ne sont ni exhaustives, ni donné dans un ordre à respecté obligatoirement, liberté à chacun et chacune d'adapter la tâche en fonction des besoins et constatations de travail. 

Une requête xpath peut aider à vérifier l'exactitude des données et ne lister aucune erreur.

#### Sondages et lecture proche

Pour vérifier la qualité de la préannotation, il est demandé de procéder pour chaque document à un sondage: sélection de trois passages (quelle longueur?) au hasard, et relecture/inspection directe, pour se faire une idée des erreurs, bruit ou surtout silences.

#### contenu de la balise `<rs>`

##### Une balise `<rs>` doit forcément contenir du texte

Elle ne peut englober et donc annoter le même segment qu'une balise `<placeName>`

- xpath à appliquer : //rs[@type='place' and not(text())]
- Ne concerne qu'une seule annotation, annotation fausse à corriger (in Pontoise-Hotel-Dieu.xml) :
```xml
<rs type="place"><placeName>Grant rue</placeName></rs>
```
##### corriger les contenus mots de la langue des balises `<rs>` 

Le fichier baliseRS_MotsLangue.txt recense l'ensemble des mots de langues des balises <rs> du corpus annoté, et donne leur nombre d'occurrence.

##### essayer de trouver les oublis d'annotation `<rs>` 

Vérifier qu'un balise `<placeName>` (non incluse dans une balise `<rs>`) n'est ni précédée ni suivie d'un mot de la langue désignant un lieu (de type : cité, mont, pont, rue, ...). Cette liste peut donner des idées de correction à apporter, et pourquoi pas de requêtes xpath à développer.

- xpath à appliquer : //placeName[not(ancestor::rs)] 

Il est possible de s'aider de la liste contenu dans le fichier : baliseRS_MotsLangue.txt Cette liste recense l'ensemble des mots de langues des balises <rs> du corpus annoté.

#####  Une balise `<rs>` doit forcément avoir un argument

- xpath à appliquer : //rs[not(@type='person' or @type='place')]
- pas d'exemples trouvés

De plus, la valeur de cet argument doit être soit 'person' soit 'place' :

- xpath : distinct-values(//rs/@type)
- pas d'erreur à corriger

##### Une balise `<rs>` n'est a priori pas inclus dans une balise `<placeName>`

- xpath : //rs[(ancestor::placeName)]
- pas d'exemples touvés





