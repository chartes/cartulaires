<?xml version="1.0" encoding="UTF-8"?>
<!-- Tableau triable et filtrable, module commun (2026-10-13).
     Import : <xsl:import href="tableau-filtrable.xsl"/> après le xsl:import de hteiml (un import,
     pas un include, pour que le corpus puisse redéfinir la variable tf-prefixe) ;
     la copie maîtresse est transform/commun/tableau-filtrable.xsl, chaque corpus en garde une
     copie à côté de sa feuille pour que son dépôt reste autonome.

     La XSL ne produit que des marqueurs (classes tf-* et attributs data-*) : aucun
     JavaScript dans le HTML. Le comportement vit dans tableau-filtrable.js (dossier
     commun des settings dots-vue), importé par le <corpus>.customJs.js du corpus.

     Contrat HTML, tel que le script le lit :
       div.tf-cadre                     enveloppe un tableau et sa barre
         div.tf-barre                   barre : span.tf-compteur[data-unite], button.tf-effacer, button.tf-csv
         table[data-csv-nom][data-csv-entetes="A|B|C"]
           thead tr  th[aria-sort][data-type="n" si numérique] > button.tf-tri
           thead tr.tf-filtres  td > input|select[data-col][data-k]
               data-k : t (contient), eq (un des mots), min / max (bornes sur data-sort),
                        num (numéros ou intervalle « 12 », « 12-15 », « de 12 à 15 », sur les mots de data-f)
           tbody tr[data-o]             ordre d'origine (départage du tri)
             td[data-sort][data-f]      valeur de tri ; valeur de filtre aplatie (tf:plat)
             td[data-csv]               valeur CSV (sinon le texte affiché) ; [data-csv-plus] ajoute une colonne
             .tf-vide                   contenu tenu pour vide dans le CSV (tiret)
       a.tf-voir[href="…#id"]           renvoi vers une ligne d'un tableau de la page : efface les
                                        filtres si la ligne est cachée, la surligne (dots-target) et
                                        la place sous l'en-tête ; sinon le lien suit son cours.

     Variable tf-prefixe (ou paramètre prefixe d'un appel) : ajoute aux classes tf-* les classes
     historiques d'un corpus (tf-prefixe 'mf' : mf-barre-filtres, mf-compteur…), pour que sa CSS
     reste valable. Le corpus la redéfinit : <xsl:variable name="tf-prefixe" select="'mf'"/>. -->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:tf="urn:elec:tableau-filtrable"
  exclude-result-prefixes="xs tf">

  <xsl:variable name="tf-prefixe" select="''"/>

  <!-- Forme aplatie d'une valeur de filtre : minuscules, sans accents ni espaces superflues. -->
  <xsl:function name="tf:plat" as="xs:string">
    <xsl:param name="s" as="xs:string?"/>
    <xsl:sequence select="normalize-space(lower-case(replace(normalize-unicode(string($s), 'NFD'), '\p{Mn}', '')))"/>
  </xsl:function>

  <!-- Classe tf-x, suivie de la classe historique du corpus quand prefixe est donné. -->
  <xsl:function name="tf:classe" as="xs:string">
    <xsl:param name="nom" as="xs:string"/>
    <xsl:param name="historique" as="xs:string"/>
    <xsl:param name="prefixe" as="xs:string"/>
    <xsl:sequence select="if ($prefixe = '') then 'tf-' || $nom else 'tf-' || $nom || ' ' || $prefixe || '-' || $historique"/>
  </xsl:function>

  <!-- Barre au-dessus du tableau : compteur, effacement (caché tant qu'aucun filtre n'est posé), CSV. -->
  <xsl:template name="tf-barre">
    <xsl:param name="total"/>
    <xsl:param name="unite"/>
    <xsl:param name="prefixe" select="$tf-prefixe"/>
    <div class="{tf:classe('barre', 'barre-filtres', $prefixe)}">
      <span class="{tf:classe('compteur', 'compteur', $prefixe)}" aria-live="polite" data-unite="{$unite}"><xsl:value-of select="concat($total, ' ', $unite)"/></span>
      <button type="button" class="{tf:classe('effacer', 'effacer', $prefixe)}" hidden="hidden">
        <xsl:text>Effacer les filtres</xsl:text>
      </button>
      <button type="button" class="{tf:classe('csv', 'csv', $prefixe)}" title="Télécharger les lignes affichées, dans l’ordre du tri, au format CSV">
        <xsl:text>Télécharger (CSV)</xsl:text>
      </button>
    </div>
  </xsl:template>

  <!-- En-tête de colonne triable. -->
  <xsl:template name="tf-th">
    <xsl:param name="classe" select="''"/>
    <xsl:param name="libelle"/>
    <xsl:param name="numerique" select="false()"/>
    <xsl:param name="prefixe" select="$tf-prefixe"/>
    <th scope="col">
      <xsl:if test="$classe != ''"><xsl:attribute name="class" select="$classe"/></xsl:if>
      <xsl:attribute name="aria-sort">none</xsl:attribute>
      <xsl:if test="$numerique"><xsl:attribute name="data-type">n</xsl:attribute></xsl:if>
      <button type="button" class="{tf:classe('tri', 'tri', $prefixe)}" title="Trier par cette colonne (cliquer de nouveau pour inverser)">
        <xsl:value-of select="$libelle"/>
      </button>
    </th>
  </xsl:template>

  <!-- Cellule de filtre de la ligne tr.tf-filtres.
       type : texte (défaut), liste (options), intervalle (min, max), numeros.
       suggestions + liste (id) : datalist facultative d'un champ texte. -->
  <xsl:template name="tf-filtre">
    <xsl:param name="col"/>
    <xsl:param name="libelle"/>
    <xsl:param name="type" select="'texte'"/>
    <xsl:param name="min" select="''"/>
    <xsl:param name="max" select="''"/>
    <xsl:param name="options" select="()"/>
    <xsl:param name="tous" select="'Toutes'"/>
    <xsl:param name="suggestions" select="()"/>
    <xsl:param name="liste" select="''"/>
    <xsl:param name="placeholder" select="'Filtrer…'"/>
    <xsl:param name="prefixe" select="$tf-prefixe"/>
    <td>
      <xsl:choose>
        <xsl:when test="$type = 'intervalle'">
          <span class="{tf:classe('intervalle', 'intervalle', $prefixe)}">
            <input type="number" data-col="{$col}" data-k="min" placeholder="{$min}" min="{$min}" max="{$max}" aria-label="{$libelle} : au moins"/>
            <span class="{tf:classe('tiret', 'tiret', $prefixe)}" aria-hidden="true">–</span>
            <input type="number" data-col="{$col}" data-k="max" placeholder="{$max}" min="{$min}" max="{$max}" aria-label="{$libelle} : au plus"/>
          </span>
        </xsl:when>
        <xsl:when test="$type = 'liste'">
          <select data-col="{$col}" data-k="eq" aria-label="{$libelle}">
            <option value=""><xsl:value-of select="$tous"/></option>
            <xsl:for-each select="$options">
              <option value="{tf:plat(.)}"><xsl:value-of select="."/></option>
            </xsl:for-each>
          </select>
        </xsl:when>
        <xsl:when test="$type = 'numeros'">
          <input type="search" data-col="{$col}" data-k="num" placeholder="{$placeholder}" aria-label="{$libelle}"/>
        </xsl:when>
        <xsl:otherwise>
          <input type="search" data-col="{$col}" data-k="t" placeholder="{$placeholder}" aria-label="Filtrer la colonne {$libelle}">
            <xsl:if test="exists($suggestions) and $liste != ''">
              <xsl:attribute name="list" select="$liste"/>
              <xsl:attribute name="autocomplete" select="'off'"/>
            </xsl:if>
          </input>
          <xsl:if test="exists($suggestions) and $liste != ''">
            <datalist id="{$liste}">
              <xsl:for-each select="$suggestions">
                <option value="{.}" data-n="{tf:plat(.)}"/>
              </xsl:for-each>
            </datalist>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </td>
  </xsl:template>

</xsl:stylesheet>
