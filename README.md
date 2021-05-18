
# Cartulaires, guide d’annotation des lieux

- I. Principes généraux
- II. Noms de lieu
- III. Imbrications d’entités
- IV. Consignes et méthode de travail
- V. Analyse des annotations


## I. Principes généraux

### Balises utilisées 

Pour annoter les noms de lieu, nous utilisons les balises TEI `<rs>` et `<placeName>`.

### Limites et bornes

Ne sont pas inclus dans la balise :

- les articles

```xml
l’<rs type="place">Arche de <placeName>Corbueil</placeName></rs>,
```

- la ponctuation et les guillemets

```xml
prises sur l’<rs type="place">Arche de <placeName>Corbueil</placeName></rs>,
```

- les pronoms personnels

```xml
ego <rs type="person"><persName>Buccardus</persName> comes</rs>
```

- les adjectifs

Sauf s’ils sont inclus dans l’empan de texte annoté :

```xml
TODO trouver un exemple
```

**Une annotation ne doit donc pas être discontinue.**


## II. Noms de lieu

- `tei:rs` : nom de lieu avec des mots de la langue.
- `tei:placeName` : nom propre de lieu.


#### Cas 1 : `<rs type="place">`+`<placeName>`

Nom de lieu contenant un nom propre de lieu. Le lieu annoté est *composite*, c’est-à-dire composé de mots de la langue et d’un nom propre de lieu (balise `placeName`).

Exemples :

```xml
<rs type="place">Prata <placeName>Reculeti</placeName></rs> ad siccandum…
```

```xml
…officialis <rs type="place">curie <placeName>Carnotensis</placeName></rs>, salutem…
```

#### Cas 2 : `<rs type="place">`+`<persName>`

Nom de lieu contenant un nom propre de personne. Le lieu annoté est *composite*, c’est-à-dire composé de mots de la langue et d’un nom propre de personne (balise `persName`).

Exemples :

```xml
et in <rs type="place">bosco <persName>Buchardi</persName></rs>
```

<!--- in S-Leu-d-Esserent --->
```xml
<rs type="place">carrière <persName>Lambert</persName></rs>
```

```xml
infra pontem tornatilem et <rs type="place">portam molendini <persName>Folet</persName></rs>
```

#### Cas 3 (rejeté) : utilisation de la seule balise `<rs>`

Lieux désignés uniquement par des mots de la langue.

**!!! Attention :** Ne pas systématiser ce type d’annotation. Il en existe quelques cas dans les textes annotés : il s’agit de laisser ces annotations, mais de ne pas ajouter d’annotation de ce type. **Nous rejetterons pour nos travaux ultérieurs ce type d’annotation**.  

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

#### Cas 4 : utilisation de la seule balise `<placeName>`

Le nom de lieu est un nom propre.

* xpath: `//placeName[not(ancestor::rs)]`

Exemples :

```xml
Donné à <placeName>Pontoise</placeName>
```

```xml
de ęcclesia abbatem et monachos <placeName>Majoris-Monasterii</placeName> investiret…
```


#### Cas ambigus

##### 1. `placeName` ou `persName` ?

Il peut être difficile de déterminer la nature (`placeName` ou `persName`) du nom propre contenu dans le nom de lieu (`rs`), par ex. :

- "église Saint-Nicolas"
- "ecclesiam Sanctæ Crucis"
- "iter S. Jacobi"
- "maison de Marguerite"
- "carrière Lambert"

**Règle : on retient la balise `persName` si la personne désignée doit figurer dans l’index des personnes.**  
En cas d’indécision, et si l’on ne peut pas déterminer si le nom propre fait encore référence à une personne (propriétaire du lieu, habitant, etc.) ou est figé comme nom de lieu,
 on choisit toujours `persName` dans la mesure ou la nature de l’entité (lieu) est définie par l’élément parent `rs[@type=’place’]`.

On retiendra donc :

- `<rs type="place">église <placeName>Saint-Nicolas</placeName></rs>`
- `<rs type="place">ecclesiam <placeName>Sanctæ Crucis</placeName></rs>`
- `<rs type="place">iter <placeName><abbr>S.</abbr> Jacobi</placeName></rs>`
- `<rs type="place">bosco <persName>Buchardi</persName></rs>`
- `<rs type="place">carrière <persName>Lambert</persName></rs>`
- `<rs type="place">portam molendini <persName>Folet</persName></rs>`

##### 2. `placeName` ou `orgName` ?

Certaines désignations peuvent être ambiguës (lieu ou organisation), par ex. : *capitulo Sanctæ Crucis*. S’agit-il du lieu (`rs[@type=’place’]`) ou de l’institution (`orgName`) ? C’est à l’annotateur de choisir selon le contexte, et de signaler le doute dans l’annotation, à l’aide de l’attribut `@cert` :

```xml
<rs type="place" cert="low">capitulo <placeName>Sanctæ Crucis</placeName></rs>
```

##### 3. Les mots de la langue

Pour les noms de lieux on ne conserve que les mots de la langue qui participent à la désignation du lieu, qu’on sache ou non s’ils participent d’une appellation figée. Par ex. :

- `<rs type="place">cheminum de <placeName>Magduno</placeName></rs>`
- `<rs type="place">granea de <placeName>Crevenz</placeName></rs>`
- `<rs type="place" >terra de <placeName>Ostentio</placeName></rs>`
- `<rs type="place">fori <placeName>Balgenciaci</placeName></rs>`
- `<rs type="place">molendinis <placeName>Firmitatis Nerbe</placeName></rs>`



## III. Imbrications d’entités

Les entités de type `place` et `person` sont souvent imbriquése. Ce paragraphe définit les règles à cette fin :

- Cas 1 : `rs[@type='person']` > `placeName`
- Cas 2 : `rs[@type='person']` > `rs[@type='place']
- Cas 3 : `persName` > `placeName`, annotation rejetée


### Cas 1 : `placeName` dans `rs[@type="person"]`

Nom propre de lieu contenu dans une entité personne.

Par exemple :

```xml
<rs type="person">Roy de <placeName>France</placeName></rs>
```


### Cas 2 : `rs[@type="place"]` dans `rs[@type="person"]`

`rs` peut contenir un `rs` d’un type différent uniquement, avec certaines contraintes.

Par exemple :

```xml
<rs type="person">capellanus
	<rs type="place">turris <placeName>Balgenciaci</placeName></rs>
</rs>
```

```xml
<rs type="person">
	<rs type="place"><placeName>Carnotensis</placeName> ecclesie</rs>
	episcopus
</rs>
```


**NB. On choisira toujours l’extension maximale**, quel que soit le nombre d’entités imbriquées.

Exemple 1. On décrit "Hugo" (fils de Rainald) et non "Hugo" ET "Rainald", dans un unique `rs` :

```xml
<rs type="person">
	<persName>Hugone</persName>
	filio
	<persName>Rainaldi</persName>
</rs>
```

et non :

```xml
<rs type="person">
	<persName>Hugone</persName>
	filio
	<rs type="person"><persName>Rainaldi</persName></rs>
</rs>
```

Exemple 2. On décrit le "pré du château de Bonneval" et non le "pré" ET le "château de Bonneval", dans un unique `rs` :

```xml
in <rs type="place">prata 
	<rs type="person">
		<persName>Hugonis</persName> de castello <placeName>Bonavallis</placeName>
	</rs>
</rs>
```

et non :

```xml
in <rs type="place">prata
	<rs type="person">
		<persName>Hugonis</persName> de
		<rs type="place">castello <placeName>Bonavallis</placeName></rs>
	</rs>
</rs>
```

On considère ici, qu’on décrit le lieu le plus spécifique (le "pré du château de Bonneval") et non pas 2 lieux (le "pré" et le "château de Bonneval").


Cas limites (à statuer?)

```xml
<rs type="person">
	<persName>Garinus</persName>,
	filius <persName>Achardi</persName> de
	<rs type="place>castello <placeName>Bonavallis</placeName></rs>
</rs>
```

```xml
<rs type="person">vir venerabilis
	<persName>Guillermus dictus Boulains</persName>,
	<rs type="person">canonicus
		<rs type="place">ecclesie <placeName>Aurelianensis</placeName></rs>
	</rs>
</rs>
```

### Cas 3 : `placeName` dans `persName`

Désignation d’une personne avec uniquement des noms propres de personne et de lieu.

- xpath:`//persName//placeName`

`placeName` et `persName` ne peuvent s’imbriquer (ni l’un l’autre, ni eux-mêmes).

Il convient d’**éviter cette annotation** : `placeName` ne devrait pas être contenu dans `persName`. Ces deux éléments peuvent être associés dans un même `rs`.


Exemples :

1) L’annotation fautive :

```xml
<persName>Radulphus, de <placeName>Pentin</placeName></persName>
```

doit être corrigée :

```xml
<rs type="person"><persName>Radulphus</persName>, de <placeName>Pentin</placeName></rs>
```

2) L’annotation fautive :

```xml
<persName>Anneti dicti Patoul de <placeName>Sancto Lupo</placeName></persName>
```

doit être corrigée :

```xml
<rs type="person"><persName>Anneti dicti Patoul</persName> de <placeName>Sancto Lupo</placeName></rs>
```


Subsistent quelques cas problématiques, par ex. :

```xml
<persName>Mathurina <placeName>Altebruerie</placeName></persName>
```
```xml
<persName>Pierre le Provost de <placeName>Champaignes</placeName></persName>
```
```xml
<persName>Gautier le Boucher de <placeName>Champaignes</placeName></persName>
```



## IV. Consignes et méthode de travail

### Consignes

#### Quelles corrections apporter ?

Les cartulaires sont déjà annotés. Le travail consiste majoritairement à reprendre, homogénéiser et corriger les annotations en place. 

Ainsi :

- il est préconisé de travailler à partir de listes et de requêtes xpath pour plus d’efficacité. En effet, travailler par liste permet de s’appuyer sur les annotations en place et semble correspondre au mieux à l’homogénéisation du traitement des données  ;
- il est possible d’alterner le travail par lecture cursive d’un texte et le travail par liste, quand ce dernier devient pesant et contre productif ;
- dans un premier temps, par soucis de gain de temps et d’efficacité, il est préconisé de corriger les entités de type `lieu`, mais toute correction évidente (même sur les entités de type `pers`) est possible.
 
#### Annoter les exemples à discuter

Il ne faut pas hésiter à repérer dans le texte annoté les doutes de correction. Les correcteurs et correctrices sont invités à utiliser l’attribut `cert` pour indiquer une incertitude quand à l’annotation :

```xml
<placeName cert="unknown">Sancte Marie in Porticu</placeName>
```

La liste de valeurs autorisées est :

- `unknown` : épingler une annotation que l’on souhaite rediscuter en groupe ;
- `low` : épingler une annotation très incertaine, à rediscuter ;
- `medium` :  épingler une annotation sur laquelle le correcteur ou la correctrice souhaite revenir, lors de son propre travail de relecture ;
- `high` : épingler une annotation exemplaire, un exemple significatif qui pourrait être mis dans le manuel d’annotation.

**Il est facile de repérer un exemple *épinglé*. Les arguments de type `cert` pourront être le moment voulu supprimés en masse. Il ne faut donc pas hésiter à utiliser cette méthode!**


#### Répartition des fichiers

|ID|placeName|persName|rs place|rs pers|somme cumulée|répartition|
|--|---------|--------|--------|-------|-------------|-----------|
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


-  Importer son jeu de données en local et le rapatrie régulièrement sur Github (branch `ner`) **via des pull requests**.
- Éditer les textes et travailler sous Oxygen.


### Pistes de travail et requêtes Xpath

Il s’agit ici d’aider à prendre en main les données et le travail de relecture. A chacune et chacun des relecteurs de commenter, augmenter, améliorer les méthodologies proposées.

Les tâches suivantes ne sont ni exhaustives, ni donné dans un ordre à respecté obligatoirement, liberté à chacun et chacune d’adapter la tâche en fonction des besoins et constatations de travail. 

Une requête xpath peut aider à vérifier l’exactitude des données et ne lister aucune erreur.

#### Sondages et lecture proche

Pour vérifier la qualité de la préannotation, il est demandé de procéder pour chaque document à un sondage: sélection de trois passages (quelle longueur?) au hasard, et relecture/inspection directe, pour se faire une idée des erreurs, bruit ou surtout silences.

#### Contenu de la balise `<rs>`

##### Une balise `<rs>` doit forcément contenir du texte

Elle ne peut englober et donc annoter le même segment qu’une balise `<placeName>`

- xpath à appliquer : `//rs[@type='place' and not(text())]`
- Ne concerne qu’une seule annotation, annotation fausse à corriger (in Pontoise-Hotel-Dieu.xml) :

```xml
<rs type="place"><placeName>Grant rue</placeName></rs>
```

##### Corriger les contenus mots de la langue des balises `<rs>` 

Le fichier `baliseRS_MotsLangue.txt` recense l’ensemble des mots de langues des balises <rs> du corpus annoté, et donne leur nombre d’occurrence.

##### Essayer de trouver les oublis d’annotation `<rs>` 

Vérifier qu’un balise `<placeName>` (non incluse dans une balise `<rs>`) n’est ni précédée ni suivie d’un mot de la langue désignant un lieu (de type : cité, mont, pont, rue, ...). Cette liste peut donner des idées de correction à apporter, et pourquoi pas de requêtes xpath à développer.

- xpath à appliquer : `//placeName[not(ancestor::rs)]`

Il est possible de s’aider de la liste contenu dans le fichier : baliseRS_MotsLangue.txt Cette liste recense l’ensemble des mots de langues des balises <rs> du corpus annoté.


##### Une balise `<rs>` n’est a priori pas inclus dans une balise `<placeName>`

- xpath : `//rs[(ancestor::placeName)]`
- pas d’exemples touvés



## V. Analyse des annotations

### Tests

#### 1) Des `rs` sans mot de la langue ?

- test : `//rs[@type=’place’ and not(text())]`

6 résultats :

- Orleans-S-Croix.xml : `<rs type="place"><placeName>Sancte Crucis de Bella</placeName></rs>`
- Paris-S-Merri.xml : `<rs type="place"><placeName>Vico Novo</placeName></rs>`
- Pontoise-Hotel-Dieu.xml : `<rs type="place"><placeName>Grant rue</placeName></rs>`
- Pontoise-S-Martin.xml : `<rs type="place"><placeName>Ainval</placeName></rs>`
- Vaux-de-Cernay.xml : `<rs type="place"><placeName>Portarii</placeName></rs>`
- Vaux-de-Cernay.xml : `<rs type="place"><placeName>Vallis Sarnaii</placeName></rs>`


#### 2) Contenu autorisé, rejet des ponctuations initiales et conclusive ?

 - test : regex search `[,;:!?.]</rs>` : 90 résultats à corriger.
 - test : regex search `[,;:!?.]</placeName>` : 144 résultats à corriger.
 - test : xpath `//rs[@type='place' and matches(., '^[,;:.]')]` : 0 résultat.
 - test : xpath `//rs[@type='place' and matches(., '^l[’e]?s? ')]` : 4 résultats à revoir.

Valider avec JBC les questions de segmentation, par ex. in S-Christophe-en-Halatte.xml :

```xml
<rs type="place">leglise <placeName>Sainct Christophe</placeName></rs>
```

TODO : compléter ces tests.

#### 3) Quid des mots autorisés dans `rs` ?

cf consignes de FM :

- `baliseRS_MotsLangue.txt` ?
- balisage lacunaire des mots précédents `//placeName[not(ancestor::rs)]` ? -> déterminer si des `placeName` doivent être insérés dans un `rs`.


#### 4) Des noms de lieu sans nom propre ?

- test : xpath `//rs[@type='place'][not(rs) and not(placeName) and not(persName)]`

86 résultats à revoir, par ex. : 

- Paris-S-Martin-des-Champs.xml : `<rs type="place">stallas Carnificum</rs>`
- Pontoise-Hotel-Dieu.xml : `<rs type="place">ecclesie </rs>`
- Pontoise-Hotel-Dieu.xml : `<rs type="place">jardinum</rs>`
- Port-Royal.xml : `<rs type="place">Officialis Curie Parisiensis</rs>`

#### 5) Des noms de lieu avec plusieurs noms propres ?

- test : xpath : `//rs[@type='place'][count(placeName) >1]`

157 résultats à discuter, par ex. : 

Orleans-S-Croix.xml : 

```xml
<rs type="place">prebendis
	<placeName>Sanctorum Petri Cluniacensis</placeName>,
	<placeName>Benedicti</placeName>,
	<placeName>Maximini</placeName>,
	<placeName>Aviti</placeName> et
	<placeName>Liphardi</placeName>
</rs>
```

#### 6) Des imbrications (rejetées) `persName`> `placeName` ?

- test : xpath `//persName/placeName`

10 résultats à revoir, par ex. :

- Pontoise-Hotel-Dieu.xml : `<persName>Mathurina <placeName>Altebruerie</placeName></persName>`
- Pontoise-Hotel-Dieu.xml : `<persName>Guillaume le Barbier des <placeName>Mesieres</placeName></persName>`

#### 7) Des imbrications (rejetées) `rs[@type='place']`> `rs[@type='place']` ?

- test : xpath `//rs[@type='place'][ancestor::rs[@type='place']]`

3 résultats à revoir :

Orleans-S-Croix.xml :

```xml
<rs type="place">
	<placeName>Gilo</placeName>, de 
	<rs type="place">
		<placeName>Arebrachio</placeName> et de
		<placeName>Loriaco</placeName> ecclesias
	</rs>
</rs>
```

Pontoise-Hotel-Dieu.xml : 

```xml
<rs type="place">terre seans es
	<rs type="place">monz de <placeName>Champaignes</placeName></rs>
</rs>
```

Vaux-de-Cernay.xml : 

```xml
<rs type="place">prato
	<rs type="place">domini
		<persName>Andree</persName>, dicti
		<persName><foreign xml:lang="fro">Polin</foreign></persName>
	</rs>
</rs>
```


#### 8) Profondeur max des imbrications ?

- test : `//rs/rs`, 879 résultats
- test : `//rs/rs/rs`, 1 résultat

```xml
<rs type="person">vir venerabilis
	<persName>Guillermus dictus Boulains</persName>,
	<rs type="person">canonicus
		<rs type="place">ecclesie <placeName>Aurelianensis</placeName></rs>
	</rs>
</rs>
```
- test : `//rs/rs/rs/rs`, 0 résultat

#### 9) Analyse des incertitude

- `//rs[@type='place'][@cert]` : 0 résultat
- `//placeName[@cert]` : 1 résultat


### Décomptes

Corpus des seuls fichiers dont l’annotation a été revue par EG et MV.

#### Effectifs

|xpath| effectif |définition|
|--------|-----|----------|
|`//placeName[not(ancestor::rs)]`|15381|Nom propre seul|
|`//rs[@type='place'][count(placeName) > 1]`|157|Nom de lieu avec plusieurs noms propres de lieu|
|`//rs[@type='place'][count(placeName) = 1]`|12526|Nom de lieu avec un unique nom propre de lieu|
|`//rs[@type='place'][count(persName) > 1]`|42|Nom de lieu avec plusieurs noms propres de personne|
|`//rs[@type='place'][count(persName) = 1]`|945|Nom de lieu avec un unique nom propre de personne|
|`//rs[@type=’place’ and not(placeName or persName)]`|253|Nom de lieu avec uniquement des mots de la langue|
|`//rs[@type='place' and placeName and persName]`|18|Nom de lieu avec noms propres de lieu et de personne|

#### Imbrications

|xpath| effectif |définition|
|--------|-----|----------|
|`//placeName[ancestor::rs[@type='person']]`|12084|Nom propre de lieu contenu dans un nom de personne|
|`//placeName[ancestor::persName]`|10|Nom propre de lieu contenu dans un nom propre de personne|
|`//rs[@type='place'][ancestor::rs[@type='person']]`|587|Nom de lieu contenu dans un nom de personne|
|`//rs[@type='place'][ancestor::rs[@type='place']]`|3|???|
|`//rs[@type='place'][ancestor::persName]`|0|OUF!|
|`//rs[@type='place'][ancestor::placeName]`|0|OUF!|

