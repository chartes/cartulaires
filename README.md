# Cartulaires. Guide d’annotation des Lieux


## 1. Annotation avec la balise `<rs>`

Le nom de lieu avec des mots de la langue.


### Cas 1 : `<rs type="place">`+`<placeName>`

Nom de lieu contenant un nom propre de lieu. Le lieu annoté est *composite*, c'est-à-dire composé de mots de la langue et d'un nom propre de lieu (balise `<placeName>`).

Exemples :
```xml
<rs type="place">Prata <placeName>Reculeti</placeName></rs> ad siccandum…
```

```xml
Omnibus presentes litteras inspecturis, officialis <rs type="place">curie
 <placeName>Carnotensis</placeName></rs>, salutem in Domino.....
```

### Cas 2: `<rs type="place">`+`<persName>`

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

### Annotation rejetée

On ne balise pas les lieux désignés uniquement par des mots de la langue.

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


### Quantification, xpath et commentaires

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



## 2. Annotation avec la seule balise `<placeName>`

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

### Quantification, xpath et commentaires

|effectif|xpath|definition|exemple|commentaire|
|--------|-----|----------|-------|-----------|
|28151|`//placeName[not(ancestor::rs)]`|Un toponyme non inclus dans un `rs`|`<placeName>Chartres</placeName>`|à inclure souvent dans un `rs`?|



## 3. `placeName` dans `rs[@type="person"]`

Nom propre de lieu contenu dans une entité personne.

Par exemple :

```xml
<rs type="person">Roy de <placeName>France</placeName></rs>
```

## 4. `placeName` dans `persName`

Désignation d’une personne avec uniquement des noms propres de personne et de lieu. Rare (13 occurrences), et annotation discutable.

- xpath:`//persName//placeName`

Exemples :

```xml
<persName>Mathurina <placeName>Altebruerie</placeName></persName>
```
```xml
<persName>Radulphus, de <placeName>Pentin</placeName></persName>
```
```xml
<persName>Pierre le Provost de <placeName>Champaignes</placeName></persName>
```
```xml
<persName>Gautier le Boucher de <placeName>Champaignes</placeName></persName>
```
```xml
<persName>Anneti dicti Patoul de <placeName>Sancto Lupo</placeName></persName>
```
