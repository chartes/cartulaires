<?xml version="1.0" encoding="UTF-8"?>
<!-- Module « tableaux » des cartulaires, inclus par cartulaires.xsl (2026-10-19 : refait sur le
     module commun tableau-filtrable.xsl, classes tf-*, comportement dans le JS générique de l'ÉLEC ;
     plus aucun onclick / oninput dans le HTML, que dots-vue retire).

     Décision de Maxime (19/10) : les lignes d'intertitre (parties, siècles, rubriques) deviennent une
     COLONNE filtrable ; le tri porte alors sur tout le tableau.

     Tableaux rendus :
       - Table de l'édition (page « Édition ») ............ cartulaires-edition.xsl, via cartu-tf
       - Table chronologique (back, SMPA-AB-02) ........... N° | Rang | Date | Analyse | Page
       - Appendice en inventaire (VNDP-AB) ................ N° | Rubrique | Lieu | Article
       - Annexes de SAPC-AB : abbesses ...................... N° | Abbesse | Dates
                              sceaux ........................ N° | Sigillant | Date | Rubrique | Lieu | Notice
       - Tableaux des introductions (répartition chronologique…) : lignes de titre en en-tête, lignes
         d'intertitre en colonne « Section » ; un intertitre qui porte un total (« XIIe siècle | 7 »)
         reste une ligne « Total », pour ne rien perdre. Un tableau à cellules fusionnées dans le corps
         (HDPAR-HD) ne peut pas être trié : il reste un tableau simple. -->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:dts="https://w3id.org/dts/api#"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:tf="urn:elec:tableau-filtrable"
  xmlns:chr="urn:cartu-tableaux"
  xmlns:cartu-app="urn:cartu-appendice"
  xmlns:h="http://www.w3.org/1999/xhtml"
  xmlns:edt="urn:cartu-edition"
  exclude-result-prefixes="tei dts xs tf chr cartu-app h edt">

  <!-- ==================================================================================================
       Constructeur commun : un tableau triable et filtrable (module tableau-filtrable.xsl).
       $colonnes : maps { 'libelle', 'num' (tri numérique), 'filtre' ('texte' | 'liste' | 'numeros' | ''),
                          'classe' (classe des cellules) }
       $lignes   : éléments h:tr, chacun avec ses h:td ; chaque td porte @data-sort (clé de tri) et son
                   contenu ; @data-f (valeur de filtre) est calculé ici depuis le texte de la cellule s'il
                   manque. Les options d'un filtre en liste sont les valeurs distinctes de la colonne.
       ================================================================================================== -->
  <xsl:template name="cartu-tf">
    <xsl:param name="classe" as="xs:string" select="''"/>
    <xsl:param name="nom" as="xs:string"/>
    <xsl:param name="unite" as="xs:string"/>
    <xsl:param name="colonnes" as="map(*)*"/>
    <xsl:param name="lignes" as="element()*"/>
    <xsl:param name="titre" as="node()*" select="()"/>
    <div class="tf-cadre cartu-tf">
      <xsl:call-template name="tf-barre">
        <xsl:with-param name="total" select="count($lignes)"/>
        <xsl:with-param name="unite" select="$unite"/>
      </xsl:call-template>
      <table class="{normalize-space(concat('tf-tableau cartu-tableau ', $classe))}" data-csv-nom="{$nom}"
             data-csv-entetes="{string-join($colonnes ! ?libelle, '|')}">
        <xsl:if test="exists($titre)"><caption><xsl:copy-of select="$titre"/></caption></xsl:if>
        <thead>
          <tr>
            <xsl:for-each select="$colonnes">
              <xsl:call-template name="tf-th">
                <xsl:with-param name="classe" select="string(?classe)"/>
                <xsl:with-param name="libelle" select="?libelle"/>
                <xsl:with-param name="numerique" select="?num = true()"/>
              </xsl:call-template>
            </xsl:for-each>
          </tr>
          <tr class="tf-filtres">
            <xsl:for-each select="$colonnes">
              <xsl:variable name="i" select="position()"/>
              <xsl:choose>
                <xsl:when test="?filtre = 'liste'">
                  <xsl:call-template name="tf-filtre">
                    <xsl:with-param name="col" select="$i - 1"/>
                    <xsl:with-param name="libelle" select="?libelle"/>
                    <xsl:with-param name="type" select="'liste'"/>
                    <xsl:with-param name="options" select="distinct-values($lignes ! normalize-space(h:td[$i]))[. != '']"/>
                  </xsl:call-template>
                </xsl:when>
                <xsl:when test="?filtre = ('texte', 'numeros')">
                  <xsl:call-template name="tf-filtre">
                    <xsl:with-param name="col" select="$i - 1"/>
                    <xsl:with-param name="libelle" select="?libelle"/>
                    <xsl:with-param name="type" select="string(?filtre)"/>
                  </xsl:call-template>
                </xsl:when>
                <xsl:otherwise><td/></xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
          </tr>
        </thead>
        <tbody>
          <xsl:for-each select="$lignes">
            <tr data-o="{position()}">
              <xsl:copy-of select="@*"/>
              <xsl:for-each select="h:td">
                <xsl:variable name="i" select="position()"/>
                <td>
                  <xsl:if test="string($colonnes[$i]?classe) != ''"><xsl:attribute name="class" select="$colonnes[$i]?classe"/></xsl:if>
                  <xsl:copy-of select="@*"/>
                  <xsl:if test="not(@data-sort)"><xsl:attribute name="data-sort" select="normalize-space(.)"/></xsl:if>
                  <xsl:if test="not(@data-f)"><xsl:attribute name="data-f" select="tf:plat(normalize-space(.))"/></xsl:if>
                  <xsl:choose>
                    <xsl:when test="normalize-space(.) = '' and not(*)"><span class="tf-vide">—</span></xsl:when>
                    <xsl:otherwise><xsl:copy-of select="node()"/></xsl:otherwise>
                  </xsl:choose>
                </td>
              </xsl:for-each>
            </tr>
          </xsl:for-each>
        </tbody>
      </table>
    </div>
  </xsl:template>

  <!-- ==================================================================================================
       Tableaux des introductions (hors des actes).
       ================================================================================================== -->
  <xsl:template match="tei:table[not(ancestor::tei:text[parent::tei:group])]" priority="5" version="3.0">
    <xsl:variable name="lignes" select="tei:row"/>
    <!-- ligne d'en-tête : ligne de titre en tête de tableau, sans cellule purement numérique (une ligne
         « XIIe siècle | 7 » est un intertitre qui porte un total, pas un en-tête) -->
    <xsl:variable name="tete" select="$lignes[@role = 'label'][not(preceding-sibling::tei:row[not(@role = 'label')])][not(tei:cell[matches(normalize-space(.), '^\d+$')])]"/>
    <xsl:variable name="corps" select="$lignes except $tete"/>
    <xsl:variable name="ncols" select="max((1, for $r in $corps[not(@role = 'label')] return count($r/tei:cell)))"/>
    <xsl:variable name="repartition" select="matches(normalize-space(tei:head[1]), 'répartition chronologique', 'i') and $ncols = 2"/>
    <xsl:choose>
      <!-- Tableau simple (non triable) : pas d'en-tête (tableaux de comptes dans les actes, NDMT-AB 171),
           cellules fusionnées dans le corps ou plusieurs lignes de titre (HDPAR-HD « Cartulaire A ») :
           un tri casserait la structure. -->
      <xsl:when test="not($tete or $repartition) or $corps/tei:cell[@cols or @rows] or count($tete) gt 1 or $corps[not(@role = 'label')][count(tei:cell) != $ncols]">
        <table class="cartu-tableau cartu-tableau-simple">
          <xsl:apply-templates select="tei:head"/>
          <xsl:if test="$tete">
            <thead><xsl:apply-templates select="$tete" mode="tableau-simple"/></thead>
          </xsl:if>
          <tbody>
            <xsl:apply-templates select="$corps | tei:pb" mode="tableau-simple">
              <xsl:with-param name="ncols" select="max((1, for $r in tei:row return sum(for $c in $r/tei:cell return if ($c/@cols) then xs:integer($c/@cols) else 1)))" tunnel="yes"/>
            </xsl:apply-templates>
          </tbody>
        </table>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="intertitres" select="$corps[@role = 'label']"/>
        <xsl:variable name="libelles" select="if ($tete) then (for $c in $tete/tei:cell return normalize-space($c)) else ('Période', 'Actes')"/>
        <xsl:variable name="numeriques" select="for $i in 1 to $ncols return (every $c in $corps/tei:cell[$i][normalize-space()] satisfies matches(normalize-space($c), '^\d+$'))"/>
        <xsl:variable name="colonnes" as="map(*)*">
          <xsl:if test="$intertitres">
            <xsl:sequence select="map { 'libelle': 'Section', 'num': false(), 'filtre': 'liste', 'classe': 'cartu-tf-section' }"/>
          </xsl:if>
          <xsl:for-each select="1 to $ncols">
            <xsl:variable name="i" select="."/>
            <xsl:sequence select="map { 'libelle': ($libelles[$i][. != ''], concat('Colonne ', $i))[1], 'num': $numeriques[$i], 'filtre': if ($numeriques[$i]) then '' else 'texte', 'classe': '' }"/>
          </xsl:for-each>
        </xsl:variable>
        <!-- un saut de page logé dans une cellule d'en-tête (SMMI-AB front-5) : les en-têtes du module
             sont des boutons de tri, en texte seul ; le repère de page est rendu juste avant le tableau -->
        <xsl:apply-templates select="$tete//tei:pb"/>
        <xsl:call-template name="cartu-tf">
          <xsl:with-param name="classe" select="'cartu-table-matieres cartu-table-analytique'"/>
          <xsl:with-param name="nom" select="string-join(('cartulaires', $resource[. != ''], 'tableau'), '-')"/>
          <xsl:with-param name="unite" select="'lignes'"/>
          <xsl:with-param name="titre" as="node()*"><xsl:apply-templates select="tei:head/node()"/></xsl:with-param>
          <xsl:with-param name="colonnes" select="$colonnes"/>
          <xsl:with-param name="lignes" as="element()*">
            <xsl:for-each select="$corps">
              <xsl:variable name="r" select="."/>
              <tr>
                <xsl:if test="@role = 'label'"><xsl:attribute name="class">cartu-tf-total</xsl:attribute></xsl:if>
                <xsl:if test="$intertitres">
                  <xsl:variable name="intertitre" select="if (@role = 'label') then . else preceding-sibling::tei:row[@role = 'label'][. intersect $intertitres][1]"/>
                  <td data-sort="{count($intertitre/preceding-sibling::tei:row)}"><xsl:apply-templates select="$intertitre/tei:cell[1]/node()"/></td>
                </xsl:if>
                <xsl:for-each select="1 to $ncols">
                  <xsl:variable name="i" select="."/>
                  <xsl:variable name="c" select="$r/tei:cell[$i]"/>
                  <td>
                    <xsl:if test="$numeriques[$i]"><xsl:attribute name="data-sort" select="normalize-space($c)"/></xsl:if>
                    <xsl:choose>
                      <!-- une ligne d'intertitre devient une ligne « Total » de sa section -->
                      <xsl:when test="$r/@role = 'label' and $i = 1">Total</xsl:when>
                      <xsl:otherwise><xsl:apply-templates select="$c/node()"/></xsl:otherwise>
                    </xsl:choose>
                  </td>
                </xsl:for-each>
              </tr>
            </xsl:for-each>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Tableau simple (non triable) : lignes et cellules, fusions comprises ; lignes de titre en th. -->
  <!-- 2026-10-19 : HDPAR-HD, « Tableaux analytiques » (Cartulaire A) : deux lignes de titre (« Cartulaires »
       sur A, B, C), lignes de cahier (« Cah. 1, fol. 1-2 ») et de catégorie (« Rois. ») sur toute la largeur.
       Comme les autres tableaux : un tableau filtrable, les lignes intercalaires devenues colonnes
       (Catégorie, Cahier), les sauts de page dans la première cellule de la ligne qui suit. -->
  <xsl:template match="tei:table[$resource = 'HDPAR-HD'][tei:row[1]/tei:cell[normalize-space(.) = 'Suscripteurs']]" priority="40">
    <xsl:variable name="donnees" select="tei:row[not(@role = 'label')][count(tei:cell) = 6]"/>
    <xsl:call-template name="cartu-tf">
      <xsl:with-param name="classe" select="'cartu-table-matieres cartu-table-analytique'"/>
      <xsl:with-param name="nom" select="'cartulaires-HDPAR-HD-tableaux-analytiques'"/>
      <xsl:with-param name="unite" select="'actes'"/>
      <xsl:with-param name="titre" as="node()*"><xsl:apply-templates select="tei:head/node()"/></xsl:with-param>
      <xsl:with-param name="colonnes" select="(
        map { 'libelle': 'Catégorie', 'num': false(), 'filtre': 'liste', 'classe': 'cartu-tf-section' },
        map { 'libelle': 'Cahier', 'num': false(), 'filtre': 'liste', 'classe': 'cartu-tf-section' },
        map { 'libelle': 'A', 'num': false(), 'filtre': 'texte', 'classe': 'cartu-tm-n' },
        map { 'libelle': 'B', 'num': false(), 'filtre': 'texte', 'classe': 'cartu-tm-n' },
        map { 'libelle': 'C', 'num': false(), 'filtre': 'texte', 'classe': 'cartu-tm-n' },
        map { 'libelle': 'Suscripteurs', 'num': false(), 'filtre': 'texte', 'classe': '' },
        map { 'libelle': 'Dates', 'num': false(), 'filtre': 'texte', 'classe': 'cartu-tm-date' },
        map { 'libelle': 'Cotes des Archives', 'num': false(), 'filtre': 'texte', 'classe': '' })"/>
      <xsl:with-param name="lignes" as="element()*">
        <xsl:for-each select="$donnees">
          <xsl:variable name="r" select="."/>
          <xsl:variable name="prec" select="preceding-sibling::tei:row[not(@role = 'label')][count(tei:cell) = 6][1]"/>
          <xsl:variable name="cat" select="preceding-sibling::tei:row[count(tei:cell) = 1][not(starts-with(normalize-space(.), 'Cah.'))][1]"/>
          <xsl:variable name="cah" select="preceding-sibling::tei:row[count(tei:cell) = 1][starts-with(normalize-space(.), 'Cah.')][1]"/>
          <xsl:variable name="pb" select="preceding-sibling::tei:pb[empty($prec) or . &gt;&gt; $prec]"/>
          <tr>
            <td data-sort="{normalize-space($cat)}"><xsl:apply-templates select="$cat/tei:cell/node()"/></td>
            <td data-sort="{normalize-space($cah)}"><xsl:apply-templates select="$cah/tei:cell/node()"/></td>
            <xsl:for-each select="tei:cell">
              <td data-sort="{if (position() = 5) then chr:date-tri(string(.)) else normalize-space(.)}">
                <xsl:if test="position() = 1"><xsl:apply-templates select="$pb"/></xsl:if>
                <xsl:apply-templates/>
              </td>
            </xsl:for-each>
          </tr>
        </xsl:for-each>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <!-- 2026-10-19 : SMPA-AB-03, page « Édition » de l'introduction : table des matières sans ligne de titre (sujet |
       pages), avec des lignes de partie sur toute la largeur. En tableau filtrable : Partie, Sujet, Pages. -->
  <xsl:template match="tei:table[$resource = 'SMPA-AB-03'][ancestor-or-self::*[@xml:id = 'SMPA-AB-03_edition']]
      [every $r in tei:row satisfies count($r/tei:cell) le 2][tei:row[count(tei:cell) = 1]]" priority="40">
    <xsl:call-template name="cartu-tf">
      <xsl:with-param name="classe" select="'cartu-table-matieres'"/>
      <xsl:with-param name="nom" select="'cartulaires-SMPA-AB-03-edition'"/>
      <xsl:with-param name="unite" select="'entrées'"/>
      <xsl:with-param name="colonnes" select="(
        map { 'libelle': 'Partie', 'num': false(), 'filtre': 'liste', 'classe': 'cartu-tf-section' },
        map { 'libelle': 'Sujet', 'num': false(), 'filtre': 'texte', 'classe': '' },
        map { 'libelle': 'Pages', 'num': false(), 'filtre': '', 'classe': 'cartu-tm-p' })"/>
      <xsl:with-param name="lignes" as="element()*">
        <xsl:for-each select="tei:row[count(tei:cell) = 2]">
          <xsl:variable name="partie" select="preceding-sibling::tei:row[count(tei:cell) = 1][1]"/>
          <tr>
            <td data-sort="{count($partie/preceding-sibling::tei:row)}"><xsl:apply-templates select="$partie/tei:cell/node()"/></td>
            <td data-sort="{normalize-space(tei:cell[1])}"><xsl:apply-templates select="tei:cell[1]/node()"/></td>
            <td data-sort="{position()}"><xsl:apply-templates select="tei:cell[2]/node()"/></td>
          </tr>
        </xsl:for-each>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <!-- 2026-10-19 : SCOR-EG, « Table des matières » (fin du volume) : après la concordance (tableau), la table proprement
       dite est une liste de 388 entrées « N° — date. lieu. — analyse ». En tableau filtrable : N° (lien vers l'acte),
       Date (celle de l'acte, lue dans le TEI complet, triable), Analyse (balisage gardé, préfixe « N° — date — » retiré
       quand il est dans le premier texte). -->
  <xsl:template match="tei:list[$resource = 'SCOR-EG'][parent::*[@xml:id = 'SCOR-EG_back-2']][tei:item]" priority="40">
    <xsl:variable name="tei" select="edt:compagnon()"/>
    <xsl:call-template name="cartu-tf">
      <xsl:with-param name="classe" select="'cartu-table-matieres cartu-edition'"/>
      <xsl:with-param name="nom" select="'cartulaires-SCOR-EG-table-des-matieres'"/>
      <xsl:with-param name="unite" select="'actes'"/>
      <xsl:with-param name="colonnes" select="(
        map { 'libelle': 'N°', 'num': true(), 'filtre': 'numeros', 'classe': 'cartu-tm-n' },
        map { 'libelle': 'Date', 'num': false(), 'filtre': 'texte', 'classe': 'cartu-tm-date' },
        map { 'libelle': 'Analyse', 'num': false(), 'filtre': 'texte', 'classe': 'cartu-tm-titre' })"/>
      <xsl:with-param name="lignes" as="element()*">
        <xsl:for-each select="tei:item[matches(string(node()[1][self::text()]), '^\s*[IVXLCDM]+\.?\s*—')]">  <!-- les actes ; pas le titre « Table des matières. » encodé en entrée -->
          <xsl:variable name="t0" select="node()[1][self::text()]"/>
          <xsl:variable name="num" select="if (matches(string($t0), '^\s*[IVXLCDM]+\.?\s*—')) then replace(string($t0), '^\s*([IVXLCDM]+).*$', '$1', 's') else ''"/>
          <xsl:variable name="acte" select="if ($num != '') then ($tei//tei:text[@n = $num][@xml:id])[1] else ()"/>
          <xsl:variable name="complet" select="matches(string($t0), '^\s*[IVXLCDM]+\.?\s*—\s*.+?\s—\s', 's')"/>
          <tr>
            <td data-sort="{if ($acte) then edt:num($acte) else 0}" data-f="{if ($acte) then edt:num($acte) else ''}">
              <xsl:choose>
                <xsl:when test="$acte"><a href="{concat($document-base, $resource, '?refId=', $acte/@xml:id)}"><xsl:value-of select="$num"/></a></xsl:when>
                <xsl:otherwise><xsl:value-of select="$num"/></xsl:otherwise>
              </xsl:choose>
            </td>
            <td data-sort="{if ($acte) then edt:date-tri($acte) else ''}"><xsl:value-of select="if ($acte) then edt:date($acte) else ''"/></td>
            <td>
              <xsl:value-of select="if ($complet) then replace(string($t0), '^\s*[IVXLCDM]+\.?\s*—\s*.+?\s—\s*', '', 's') else replace(string($t0), '^\s*[IVXLCDM]+\.?\s*—\s*', '', 's')"/>
              <xsl:apply-templates select="node() except $t0"/>
            </td>
          </tr>
        </xsl:for-each>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="tei:row" mode="tableau-simple">
    <tr>
      <xsl:if test="@role = 'label' and preceding-sibling::tei:row[not(@role = 'label')]">
        <xsl:attribute name="class">cartu-tm-partie</xsl:attribute>
      </xsl:if>
      <xsl:for-each select="tei:cell">
        <xsl:element name="{if (../@role = 'label' or @role = 'label') then 'th' else 'td'}" namespace="http://www.w3.org/1999/xhtml">
          <xsl:if test="@rows &gt; 1"><xsl:attribute name="rowspan" select="@rows"/></xsl:if>
          <xsl:if test="@cols &gt; 1"><xsl:attribute name="colspan" select="@cols"/></xsl:if>
          <xsl:apply-templates/>
        </xsl:element>
      </xsl:for-each>
    </tr>
  </xsl:template>
  <!-- saut de page posé entre deux lignes : une ligne discrète, pleine largeur (vignette, repère) -->
  <xsl:template match="tei:pb" mode="tableau-simple">
    <xsl:param name="ncols" as="xs:integer" tunnel="yes" select="1"/>
    <tr class="cartu-tm-pb">
      <td colspan="{$ncols}"><xsl:apply-templates select="." mode="#default"/></td>
    </tr>
  </xsl:template>

  <!-- ==================================================================================================
       Table chronologique (back, ex. SMPA-AB-02_back-1) : lignes « (rang) | date | analyse | n° | page ».
       ================================================================================================== -->
  <xsl:template match="tei:table[not(ancestor::tei:text[parent::tei:group])][count(tei:row) gt 1][every $r in tei:row satisfies (count($r/tei:cell) = 5 and matches(string($r/tei:cell[1]), '^[\s\p{Zs}]*\(\d+\)[\s\p{Zs}]*$'))]" priority="6" version="3.0">
    <xsl:call-template name="cartu-tf">
      <xsl:with-param name="classe" select="'cartu-table-matieres cartu-edition'"/>
      <xsl:with-param name="nom" select="concat('cartulaires-', $resource, '-table-chronologique')"/>
      <xsl:with-param name="unite" select="'actes'"/>
      <xsl:with-param name="titre" as="node()*"><xsl:apply-templates select="tei:head/node()"/></xsl:with-param>
      <xsl:with-param name="colonnes" select="(
        map { 'libelle': 'N°', 'num': true(), 'filtre': 'numeros', 'classe': 'cartu-tm-n' },
        map { 'libelle': 'Rang', 'num': true(), 'filtre': '', 'classe': 'cartu-tm-rang' },
        map { 'libelle': 'Date', 'num': false(), 'filtre': 'texte', 'classe': 'cartu-tm-date' },
        map { 'libelle': 'Analyse', 'num': false(), 'filtre': 'texte', 'classe': 'cartu-tm-titre' },
        map { 'libelle': 'Page', 'num': true(), 'filtre': 'numeros', 'classe': 'cartu-tm-p' })"/>
      <xsl:with-param name="lignes" as="element()*">
        <xsl:for-each select="tei:row">
          <xsl:variable name="n" select="chr:acte(tei:cell[4], count(preceding-sibling::tei:row) + 1)"/>
          <xsl:variable name="ligne" select="."/>
          <!-- saut de page posé entre la ligne précédente et celle-ci -->
          <xsl:variable name="pb" select="preceding-sibling::tei:pb[following-sibling::tei:row[1] is $ligne]"/>
          <tr>
            <td data-sort="{$n}" data-f="{$n}"><xsl:apply-templates select="$pb"/><xsl:apply-templates select="tei:cell[4]/node()"/></td>
            <td data-sort="{replace(string(tei:cell[1]), '\D', '')}"><xsl:apply-templates select="tei:cell[1]/node()"/></td>
            <td data-sort="{chr:date-tri(string(tei:cell[2]))}"><xsl:apply-templates select="tei:cell[2]/node()"/></td>
            <td><xsl:apply-templates select="tei:cell[3]/node()"/></td>
            <td data-sort="{replace(string(tei:cell[5]), '\D', '')}" data-f="{replace(string(tei:cell[5]), '\D', '')}"><xsl:apply-templates select="tei:cell[5]/node()"/></td>
          </tr>
        </xsl:for-each>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <!-- n° de l'acte (cellule 4) ; à défaut, le rang -->
  <xsl:function name="chr:acte" as="xs:string">
    <xsl:param name="c" as="element()?"/>
    <xsl:param name="rang" as="xs:integer"/>
    <xsl:variable name="t" select="if (exists($c)) then replace(string($c), '[\s\p{Zs}]+', '') else ''"/>
    <xsl:sequence select="if (matches($t, '^\d+$')) then $t else string($rang)"/>
  </xsl:function>

  <!-- date de tri AAAA-MM-JJ : année (premier nombre de 3 ou 4 chiffres) ; mois et jour seulement s'ils suivent
       immédiatement « année, [jour] mois » ; date incomplète = 1er janvier ou 1er du mois de l'année ;
       « xive s. » = 1301-01-01 ; aucune année = '' (fin du tri). « (n. st.) » ignoré. -->
  <xsl:function name="chr:date-tri" as="xs:string">
    <xsl:param name="c" as="xs:string"/>
    <xsl:variable name="s" select="replace(replace(lower-case(replace($c, '[\s\p{Zs}]+', ' ')), '\(\s*[nv]\.\s*st\.?\s*\)', ''), '\s*:\s*$', '')"/>
    <xsl:variable name="reste" select="replace($s, '^[^0-9]*(\d{1,2}[^0-9]+)*\d{3,4}\s*,?\s*', '')"/>
    <xsl:variable name="stems" select="('janv', 'f[ée]vr', 'mars', 'avr', 'mai', 'juin', 'juil', 'ao[uû]t', 'sept', 'oct', 'nov', 'd[ée]c')"/>
    <xsl:variable name="mo" select="(for $i in 1 to 12 return if (matches($reste, concat('^(\d{1,2}(er)?\s+)?', $stems[$i]))) then $i else ())[1]"/>
    <xsl:variable name="jour" select="if (exists($mo) and matches($reste, '^\d{1,2}(er)?\s')) then replace($reste, '^(\d{1,2})(er)?\s.*$', '$1') else ''"/>
    <xsl:sequence select="
      if (contains($s, 'xive')) then '1301-01-01'
      else if (not(matches($s, '[0-9]{3,4}'))) then ''
      else concat(
        format-number(xs:integer(replace($s, '^[^0-9]*(\d{1,2}[^0-9]+)*(\d{3,4}).*$', '$2')), '0000'), '-',
        format-number(if (exists($mo)) then $mo else 1, '00'), '-',
        format-number(if ($jour != '') then xs:integer($jour) else 1, '00'))"/>
  </xsl:function>

  <!-- ==================================================================================================
       Appendice en inventaire (VNDP-AB_back : rubriques « I. Iste sunt vinee… », articles « apud
       Joyacum, i. arpentum… », « item, … ») : N° | Rubrique | Lieu | Article. Le lieu vient de « apud X, »
       et passe aux « item » qui suivent. Servi entier (div) ou seul (dts:wrapper).
       ================================================================================================== -->
  <xsl:template match="(tei:div[@type = 'appendice'] | *[local-name() = 'wrapper'][not(tei:teiHeader)][matches(normalize-space(tei:head[1]), '^appendice', 'i')])
      [tei:div][every $d in tei:div satisfies empty($d/*[not(self::tei:head or self::tei:p or self::tei:pb)])]" priority="27" version="3.0">
    <xsl:variable name="articles" select="tei:div/tei:p[normalize-space()]"/>
    <section class="cartu-appendice">
      <xsl:if test="self::tei:div/@xml:id"><xsl:attribute name="id" select="@xml:id"/></xsl:if>
      <h1 class="head"><xsl:apply-templates select="tei:head[1]/node()[not(self::tei:pb)]"/></h1>
      <xsl:call-template name="cartu-tf">
        <xsl:with-param name="classe" select="'cartu-table-matieres cartu-edition cartu-appendice-table'"/>
        <xsl:with-param name="nom" select="concat('cartulaires-', $resource, '-appendice')"/>
        <xsl:with-param name="unite" select="'articles'"/>
        <xsl:with-param name="colonnes" select="(
          map { 'libelle': 'N°', 'num': true(), 'filtre': 'numeros', 'classe': 'cartu-tm-n' },
          map { 'libelle': 'Rubrique', 'num': false(), 'filtre': 'liste', 'classe': 'cartu-app-rubrique' },
          map { 'libelle': 'Lieu', 'num': false(), 'filtre': 'liste', 'classe': 'cartu-app-lieu' },
          map { 'libelle': 'Article', 'num': false(), 'filtre': 'texte', 'classe': 'cartu-app-article' })"/>
        <xsl:with-param name="lignes" as="element()*">
          <xsl:for-each select="$articles">
            <xsl:variable name="i" select="position()"/>
            <xsl:variable name="rubrique" select="normalize-space(replace(string-join(../tei:head[1]//text()[not(ancestor::tei:note)], ''), '^\s*([IVXLC]+)\..*$', '$1', 's'))"/>
            <tr>
              <td data-sort="{$i}" data-f="{$i}"><xsl:value-of select="$i"/></td>
              <td data-sort="{chr:roman(replace($rubrique, '[^IVXLC]', ''))}" title="{normalize-space(string-join(../tei:head[1]//text()[not(ancestor::tei:note)], ''))}"><xsl:value-of select="$rubrique"/></td>
              <td><xsl:value-of select="cartu-app:lieu(.)"/></td>
              <td><xsl:apply-templates select="node()[not(self::tei:pb or self::tei:note)]"/><xsl:for-each select="tei:note"><span class="cartu-app-note"><xsl:value-of select="normalize-space(.)"/></span></xsl:for-each></td>
            </tr>
          </xsl:for-each>
        </xsl:with-param>
      </xsl:call-template>
    </section>
  </xsl:template>

  <!-- lieu d'un article : « apud X, » ; un article « item » reprend le lieu de l'article précédent -->
  <xsl:function name="cartu-app:lieu" as="xs:string">
    <xsl:param name="p" as="element()"/>
    <xsl:variable name="t" select="normalize-space(string-join($p//text()[not(ancestor::tei:note)], ''))"/>
    <xsl:sequence select="if (matches($t, '^(apud|juxta|in)\s+[^,;]+', 'i')) then replace(replace($t, '^(apud|juxta|in)\s+([^,;]+).*$', '$2', 'i'), '[\s&#160;]+$', '')
        else if (matches($t, '^item([\s,.;:]|$)', 'i') and $p/preceding-sibling::tei:p) then cartu-app:lieu($p/preceding-sibling::tei:p[1])
        else ''"/>
  </xsl:function>

  <!-- ligne d'intitulés (row[@role='label']) de tout tableau des actes (NDMT-AB_0171, NDPA-EG-04…) :
       cellules en <th>, comme un en-tête. -->
  <xsl:template match="tei:row[@role = 'label']/tei:cell[not(@role = 'data')] | tei:cell[@role = 'label']" priority="4">
    <th>
      <xsl:if test="@cols"><xsl:attribute name="colspan" select="@cols"/></xsl:if>
      <xsl:if test="@rows"><xsl:attribute name="rowspan" select="@rows"/></xsl:if>
      <xsl:apply-templates/>
    </th>
  </xsl:template>

  <!-- ==================================================================================================
       ANNEXES de SAPC-AB (back-1) : liste des abbesses et corpus des sceaux. La sous-rubrique d'un sceau
       (« A. Sceaux… · b) Archevêchés », avec ses mentions qui précèdent le premier sceau, sauf le lieu,
       qui a sa colonne) passe dans la colonne Rubrique. Le TEI n'est pas modifié.
       ================================================================================================== -->
  <xsl:template match="tei:div[@type = 'annexes'][.//tei:div/tei:head[matches(normalize-space(.), 'SCEAUX', 'i')]]" priority="28" version="3.0">
    <section class="cartu-annexes">
      <xsl:if test="@xml:id"><xsl:attribute name="id" select="@xml:id"/></xsl:if>
      <h1 class="head"><xsl:apply-templates select="tei:head[1]/node()"/></h1>
      <xsl:for-each select="tei:div">
        <xsl:choose>
          <xsl:when test="not(tei:div) and tei:p[chr:liste-num(.)]">
            <xsl:call-template name="chr:annexes-liste"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="chr:annexes-sceaux"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </section>
  </xsl:template>

  <!-- Même chose quand l'unité est servie seule (excludeFragments=true) : ses deux divisions arrivent sans
       @type, sous le dts:wrapper dont le titre est « ANNEXES ». -->
  <xsl:template match="tei:div[not(@type)][parent::*[local-name() = 'wrapper']][not(tei:div)][tei:p[chr:liste-num(.)]]" priority="28" version="3.0">
    <xsl:call-template name="chr:annexes-liste"/>
  </xsl:template>

  <xsl:template match="tei:div[not(@type)][parent::*[local-name() = 'wrapper']][tei:div/tei:head[matches(normalize-space(.), 'SCEAUX', 'i')]]" priority="28" version="3.0">
    <xsl:call-template name="chr:annexes-sceaux"/>
  </xsl:template>

  <xsl:template name="chr:annexes-liste">
    <section class="cartu-appendice cartu-annexes-liste">
      <h2 class="head"><xsl:apply-templates select="tei:head[1]/node()"/></h2>
      <xsl:apply-templates select="tei:p[not(chr:liste-num(.))]"/>
      <xsl:call-template name="cartu-tf">
        <xsl:with-param name="classe" select="'cartu-table-matieres cartu-edition cartu-appendice-table cartu-annexes-table'"/>
        <xsl:with-param name="nom" select="concat('cartulaires-', $resource, '-abbesses')"/>
        <xsl:with-param name="unite" select="'entrées'"/>
        <xsl:with-param name="colonnes" select="(
          map { 'libelle': 'N°', 'num': true(), 'filtre': '', 'classe': 'cartu-tm-n' },
          map { 'libelle': 'Abbesse', 'num': false(), 'filtre': 'texte', 'classe': 'cartu-app-nom' },
          map { 'libelle': 'Dates', 'num': false(), 'filtre': 'texte', 'classe': 'cartu-tm-date' })"/>
        <xsl:with-param name="lignes" as="element()*">
          <xsl:for-each select="tei:p[chr:liste-num(.)]">
            <xsl:variable name="t" select="normalize-space(.)"/>
            <xsl:variable name="dates" select="replace($t, '^\d+\s+.+?,\s*(\d{3,4}\s*[–-]\s*\d{3,4})\.*$', '$1')"/>
            <tr>
              <td data-sort="{replace($t, '^(\d+)\s.*$', '$1')}"><xsl:value-of select="replace($t, '^(\d+)\s.*$', '$1')"/></td>
              <td><xsl:value-of select="replace($t, '^\d+\s+(.+?),\s*\d{3,4}\s*[–-]\s*\d{3,4}\.*$', '$1')"/></td>
              <td data-sort="{chr:date-tri($dates)}"><xsl:value-of select="$dates"/></td>
            </tr>
          </xsl:for-each>
        </xsl:with-param>
      </xsl:call-template>
    </section>
  </xsl:template>

  <xsl:template name="chr:annexes-sceaux">
    <section class="cartu-appendice cartu-annexes-sceaux">
      <h2 class="head"><xsl:apply-templates select="tei:head[1]/node()"/></h2>
      <xsl:apply-templates select="tei:p"/>
      <xsl:call-template name="cartu-tf">
        <xsl:with-param name="classe" select="'cartu-table-matieres cartu-edition cartu-appendice-table cartu-sceaux-table'"/>
        <xsl:with-param name="nom" select="concat('cartulaires-', $resource, '-sceaux')"/>
        <xsl:with-param name="unite" select="'sceaux'"/>
        <xsl:with-param name="colonnes" select="(
          map { 'libelle': 'N°', 'num': true(), 'filtre': '', 'classe': 'cartu-tm-n' },
          map { 'libelle': 'Sigillant', 'num': false(), 'filtre': 'texte', 'classe': 'cartu-app-nom' },
          map { 'libelle': 'Date', 'num': false(), 'filtre': 'texte', 'classe': 'cartu-tm-date' },
          map { 'libelle': 'Rubrique', 'num': false(), 'filtre': 'liste', 'classe': 'cartu-app-rubrique' },
          map { 'libelle': 'Lieu', 'num': false(), 'filtre': 'liste', 'classe': 'cartu-app-lieu' },
          map { 'libelle': 'Notice', 'num': false(), 'filtre': 'texte', 'classe': 'cartu-app-article' })"/>
        <xsl:with-param name="lignes" as="element()*">
          <xsl:for-each select=".//tei:div[not(tei:div)]">
            <xsl:call-template name="chr:sceaux-feuille"/>
          </xsl:for-each>
        </xsl:with-param>
      </xsl:call-template>
    </section>
  </xsl:template>

  <!-- une sous-rubrique : une ligne par sceau ; sa rubrique (partie · sous-rubrique, plus les mentions qui
       précèdent le premier sceau, hors lieu) passe dans la colonne Rubrique -->
  <xsl:template name="chr:sceaux-feuille">
    <xsl:variable name="leaf" select="."/>
    <xsl:variable name="parent-head" select="normalize-space(string(../tei:head[1]))"/>
    <xsl:variable name="premier" select="(tei:p[chr:entree(.)])[1]"/>
    <xsl:variable name="avant" select="if (exists($premier)) then tei:p[. &lt;&lt; $premier] else tei:p"/>
    <xsl:variable name="mentions" select="for $p in $avant[not(chr:lieu(.))] return normalize-space($p)"/>
    <xsl:variable name="rubrique" select="string-join(($parent-head, normalize-space(string(tei:head[1])), $mentions)[. != ''], ' · ')"/>
    <!-- repères de page des intitulés (celui de la partie avec sa première sous-rubrique seulement) et
         des mentions qui précèdent le premier sceau : portés par le premier sceau de la sous-rubrique -->
    <xsl:variable name="pb-rubrique" select="(if (preceding-sibling::tei:div) then () else ../tei:head[1]//tei:pb), tei:head[1]//tei:pb, $avant//tei:pb"/>
    <xsl:for-each-group select="tei:p" group-starting-with="tei:p[chr:entree(.)]">
      <xsl:if test="chr:entree(current-group()[1])">
        <xsl:call-template name="chr:sceaux-entree">
          <xsl:with-param name="groupe" select="current-group()"/>
          <xsl:with-param name="feuille" select="$leaf"/>
          <xsl:with-param name="rubrique" select="$rubrique"/>
          <xsl:with-param name="pb-avant" select="if (current-group()[1] is $premier) then $pb-rubrique else ()"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:for-each-group>
  </xsl:template>

  <!-- un sceau : intitulé (premier paragraphe), date (premier paragraphe qui commence par une année),
       notice (les autres paragraphes, sans la ligne de date déjà en colonne) -->
  <xsl:template name="chr:sceaux-entree">
    <xsl:param name="groupe" as="element()+"/>
    <xsl:param name="feuille" as="element()"/>
    <xsl:param name="rubrique" as="xs:string"/>
    <xsl:param name="pb-avant" as="element()*" select="()"/>
    <xsl:variable name="tete" select="$groupe[1]"/>
    <xsl:variable name="texte" select="normalize-space(string($tete))"/>
    <xsl:variable name="roman" select="replace($texte, '^([IVXLC]+)\..*$', '$1')"/>
    <xsl:variable name="datep" select="($groupe[position() gt 1][chr:datep(.)])[1]"/>
    <xsl:variable name="date" select="if (exists($datep)) then replace(normalize-space(string($datep)), '^[–-]\s*', '') else ''"/>
    <xsl:variable name="lieu" select="replace(replace(normalize-space(string(($feuille//tei:p[. &lt;&lt; $tete][chr:lieu(.)])[last()])), '^[–-]\s*', ''), '[\s.,]+$', '')"/>
    <tr>
      <td data-sort="{chr:roman($roman)}"><xsl:apply-templates select="$pb-avant, $tete/tei:pb"/><xsl:value-of select="$roman"/></td>
      <td><xsl:value-of select="replace($texte, '^[IVXLC]+\.\s*', '')"/></td>
      <td data-sort="{chr:date-tri($date)}"><xsl:apply-templates select="$datep/tei:pb"/><xsl:value-of select="$date"/></td>
      <td><xsl:value-of select="$rubrique"/></td>
      <td><xsl:value-of select="$lieu"/></td>
      <td><xsl:apply-templates select="$groupe[position() gt 1][not(. is $datep)]"/></td>
    </tr>
  </xsl:template>

  <xsl:function name="chr:entree" as="xs:boolean">
    <xsl:param name="p" as="element()"/>
    <xsl:sequence select="matches(normalize-space(string($p)), '^[IVXLC]+\.\s+\p{Lu}')"/>
  </xsl:function>

  <!-- ligne de date d'un sceau : « 1216, avril… », « 1 – 1217, juin… », « – 1218 (n. st.)… » -->
  <xsl:function name="chr:datep" as="xs:boolean">
    <xsl:param name="p" as="element()"/>
    <xsl:sequence select="matches(normalize-space(string($p)), '^(\d\s*[–-]\s*|[–-]\s*)?\d{4}([^0-9]|$)')"/>
  </xsl:function>

  <!-- lieu : « – Embrun. », « – Beaumont-en-Gâtinais, » (tiret puis majuscule, ni une date) -->
  <xsl:function name="chr:lieu" as="xs:boolean">
    <xsl:param name="p" as="element()"/>
    <xsl:sequence select="matches(normalize-space(string($p)), '^[–-]\s*\p{Lu}')"/>
  </xsl:function>

  <!-- abbesse : « 6 Jeanne 1ère, 1253-1254.. » -->
  <xsl:function name="chr:liste-num" as="xs:boolean">
    <xsl:param name="p" as="element()"/>
    <xsl:sequence select="matches(normalize-space(string($p)), '^\d+\s+.+,\s*\d{3,4}\s*[–-]\s*\d{3,4}\.*$')"/>
  </xsl:function>

  <!-- numéro romain -> entier (IV = 4 ; une coquille du TEI, XCXIX, est lue telle quelle = 109) -->
  <xsl:function name="chr:roman" as="xs:integer">
    <xsl:param name="r" as="xs:string"/>
    <xsl:variable name="n" select="string-length($r)"/>
    <xsl:variable name="v" select="for $i in 1 to $n return (1, 5, 10, 50, 100, 500, 1000)[index-of(('I', 'V', 'X', 'L', 'C', 'D', 'M'), substring($r, $i, 1))]"/>
    <xsl:sequence select="xs:integer(sum(for $i in 1 to $n return if ($i lt $n and $v[$i] lt $v[$i + 1]) then -$v[$i] else $v[$i]))"/>
  </xsl:function>

  <!-- Titre (group ou dts:wrapper) portant une note hors de tout tei:text : la collecte des notes de
       hteiml ne la voit pas ; le bloc de notes du titre est ajouté après le rendu, s'il n'y est pas déjà
       (SMCP-PR group-3-2-6, NDPA-EG-01 group-2-9, NDPA-EG-03 group-3-2). -->
  <xsl:template match="(tei:group[parent::*[local-name() = 'wrapper']] | *[local-name() = 'wrapper'])[tei:head//tei:note]" priority="31" version="3.0">
    <xsl:variable name="rendu">
      <xsl:next-match/>
    </xsl:variable>
    <xsl:copy-of select="$rendu"/>
    <xsl:if test="not($rendu//*[@class = 'footnotes'])">
      <section class="footnotes">
        <xsl:for-each select="tei:head//tei:note">
          <xsl:call-template name="note"/>
        </xsl:for-each>
      </section>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
