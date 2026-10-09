<?xml version="1.0" encoding="UTF-8"?>
<!-- 2026-10-08 : module « tableaux », inclus par cartulaires.xsl (tableaux dans les textes
     d'introduction, ex. HDPAR-HD_front). Priorités supérieures aux modèles remplacés. -->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:dts="https://w3id.org/dts/api#"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:chr="urn:cartu-tableaux"
  exclude-result-prefixes="tei dts xs chr">

  <!-- Tableau TEI (table/row/cell) dans un front : vrai <table> HTML, classes de la « Table du
       cartulaire » (table.cartu-table-matieres, CSS existante). Les lignes role="label" en tête
       deviennent <thead> ; les lignes role="label" plus loin deviennent des séparateurs de partie.
       Les <pb> placés directement dans le tableau sortent du tbody : ils deviennent une ligne
       discrète (sans cellule vide). Le TEI n'est pas modifié. -->
  <!-- 2026-10-08 : toute table hors des actes (group/text). Une sous-partie d'introduction est servie
       seule dans un dts:wrapper, sans tei:front autour (HDPAR-HD_notice_tableaux) : le critère
       « ancestor::tei:front » ne la voyait pas. -->
  <xsl:template match="tei:table[not(ancestor::tei:text[parent::tei:group])]" priority="5" version="3.0">
    <xsl:variable name="entete" select="tei:row[@role = 'label'][not(preceding-sibling::tei:row[not(@role = 'label')])]"/>
    <xsl:variable name="ncols" select="max((1, for $r in tei:row return sum(for $c in $r/tei:cell return if ($c/@cols) then xs:integer($c/@cols) else 1)))"/>
    <table>
      <xsl:call-template name="atts">
        <xsl:with-param name="class">cartu-table-matieres cartu-table-analytique</xsl:with-param>
      </xsl:call-template>
      <xsl:apply-templates select="tei:head"/>
      <xsl:if test="$entete">
        <thead>
          <xsl:apply-templates select="$entete" mode="tableau"/>
        </thead>
      </xsl:if>
      <tbody>
        <xsl:apply-templates select="tei:*[not(self::tei:head)] except $entete" mode="tableau">
          <xsl:with-param name="ncols" select="$ncols" tunnel="yes"/>
        </xsl:apply-templates>
      </tbody>
    </table>
  </xsl:template>

  <!-- pb directement sous le tableau : une ligne discrète, pleine largeur -->
  <xsl:template match="tei:pb[parent::tei:table]" mode="tableau" priority="5" version="3.0">
    <xsl:param name="ncols" as="xs:integer" tunnel="yes" select="1"/>
    <tr class="cartu-tm-pb">
      <td colspan="{$ncols}">
        <xsl:apply-templates select="." mode="#default"/>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="tei:row" mode="tableau" priority="5" version="3.0">
    <xsl:variable name="label" select="@role = 'label'"/>
    <tr>
      <xsl:if test="$label and preceding-sibling::tei:row[not(@role = 'label')]">
        <xsl:attribute name="class">cartu-tm-partie</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates mode="tableau"/>
    </tr>
  </xsl:template>

  <xsl:template match="tei:cell" mode="tableau" priority="5" version="3.0">
    <xsl:variable name="el" select="if (ancestor::tei:row[1]/@role = 'label') then 'th' else 'td'"/>
    <xsl:element name="{$el}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:if test="$el = 'th'">
        <xsl:attribute name="scope" select="if (@cols &gt; 1) then 'colgroup' else 'col'"/>
      </xsl:if>
      <xsl:if test="@rows &gt; 1">
        <xsl:attribute name="rowspan" select="@rows"/>
      </xsl:if>
      <xsl:if test="@cols &gt; 1">
        <xsl:attribute name="colspan" select="@cols"/>
      </xsl:if>
      <xsl:call-template name="atts"/>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <!-- 2026-10-08 : TABLE CHRONOLOGIQUE (back, ex. SMPA-AB-02_back-1) : lignes « (rang) | date | analyse |
       n° de l'acte | page ». Présentée comme la Table de l'édition (table.cartu-table-matieres.cartu-edition) :
       tri au clic sur N° (n° de l'acte) et Date, par edt-tri-js (module edition). Ordre initial = ordre du TEI.
       Les pb placés entre les lignes deviennent des lignes cartu-tm-partie (masquées hors tri par N°, comme les
       intertitres de l'édition). Clé de date (data-date, AAAA-MM-JJ) : chr:date-tri. -->
  <xsl:template match="tei:table[not(ancestor::tei:text[parent::tei:group])][count(tei:row) gt 1][every $r in tei:row satisfies (count($r/tei:cell) = 5 and matches(string($r/tei:cell[1]), '^[\s\p{Zs}]*\(\d+\)[\s\p{Zs}]*$'))]" priority="6" version="3.0">
    <table>
      <xsl:call-template name="atts">
        <xsl:with-param name="class">cartu-table-matieres cartu-edition</xsl:with-param>
      </xsl:call-template>
      <xsl:apply-templates select="tei:head"/>
      <thead>
        <tr>
          <th scope="col">Rang</th>
          <th scope="col" class="cartu-tm-n cartu-tri-col" data-cle="num" title="Trier par numéro d'acte" onclick="{$edt-tri-js}">N<sup>o</sup></th>
          <th scope="col" class="cartu-tm-date cartu-tri-col" data-cle="date" title="Trier par date" onclick="{$edt-tri-js}">Date</th>
          <th scope="col">Analyse</th>
          <th scope="col" class="cartu-tm-p">Page</th>
        </tr>
      </thead>
      <tbody>
        <xsl:for-each select="tei:row | tei:pb[parent::tei:table]">
          <xsl:choose>
            <xsl:when test="self::tei:pb">
              <tr class="cartu-tm-pb cartu-tm-partie">
                <xsl:attribute name="data-ord" select="if (following-sibling::tei:row) then string(number(chr:acte(following-sibling::tei:row[1]/tei:cell[4], 0)) - 0.5) else '99999'"/>
                <td colspan="5"><xsl:apply-templates select="." mode="#default"/></td>
              </tr>
            </xsl:when>
            <xsl:otherwise>
              <tr>
                <xsl:attribute name="data-ord" select="chr:acte(tei:cell[4], count(preceding-sibling::tei:row) + 1)"/>
                <xsl:attribute name="data-num" select="chr:acte(tei:cell[4], count(preceding-sibling::tei:row) + 1)"/>
                <xsl:attribute name="data-date" select="chr:date-tri(string(tei:cell[2]))"/>
                <td class="cartu-tm-rang"><xsl:apply-templates select="tei:cell[1]/node()"/></td>
                <td class="cartu-tm-n"><xsl:apply-templates select="tei:cell[4]/node()"/></td>
                <td class="cartu-tm-date"><xsl:apply-templates select="tei:cell[2]/node()"/></td>
                <td class="cartu-tm-titre"><xsl:apply-templates select="tei:cell[3]/node()"/></td>
                <td class="cartu-tm-p"><xsl:apply-templates select="tei:cell[5]/node()"/></td>
              </tr>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </tbody>
    </table>
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

  <!-- 2026-10-08 : APPENDICE en inventaire (VNDP-AB_back : rubriques « I. Iste sunt vinee… » puis des
       articles en <p> « apud Joyacum, i. arpentum… », « item, … ») : un tableau filtrable et triable, comme
       ceux de Christofle et Bellelay. Colonnes N° | Rubrique | Lieu | Article. Le lieu est tiré de
       « apud X, » et reporté sur les « item » qui suivent. Filtre : un champ de saisie (oninput, sans
       <script>), sans casse ni accents. Ne s'applique qu'à un appendice dont les sous-divisions ne
       contiennent que des paragraphes. Servi entier (div) ou seul (dts:wrapper). -->
  <xsl:template match="(tei:div[@type = 'appendice'] | *[local-name() = 'wrapper'][not(tei:teiHeader)][matches(normalize-space(tei:head[1]), '^appendice', 'i')])
      [tei:div][every $d in tei:div satisfies empty($d/*[not(self::tei:head or self::tei:p or self::tei:pb)])]" priority="27" version="3.0">
    <xsl:variable name="articles" select="tei:div/tei:p[normalize-space()]"/>
    <section class="cartu-appendice">
      <xsl:if test="self::tei:div/@xml:id"><xsl:attribute name="id" select="@xml:id"/></xsl:if>
      <h1 class="head"><xsl:apply-templates select="tei:head[1]/node()[not(self::tei:pb)]"/></h1>
      <p class="cartu-filtre">
        <label>Filtrer <input type="search" placeholder="lieu, mot, nom…" aria-label="Filtrer les articles"
          oninput="var q=this.value.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g,'').trim(),s=this.closest('section'),n=0;s.querySelectorAll('tbody tr').forEach(function(r){{var ok=!q||r.textContent.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g,'').indexOf(q)&gt;=0;r.hidden=!ok;if(ok){{n++;}}}});s.querySelector('.cartu-filtre-nb').textContent=n;"/></label>
        <span class="cartu-filtre-compte"><span class="cartu-filtre-nb"><xsl:value-of select="count($articles)"/></span> articles</span>
      </p>
      <table class="cartu-table-matieres cartu-edition cartu-appendice-table">
        <thead>
          <tr>
            <th scope="col" class="cartu-tm-n cartu-tri-col" data-cle="num" aria-sort="ascending" title="Ordre du texte" onclick="{$edt-tri-js}">N<sup>o</sup></th>
            <th scope="col">Rubrique</th>
            <th scope="col" class="cartu-tri-col" data-cle="lieu" data-texte="" title="Trier par lieu" onclick="{$edt-tri-js}">Lieu</th>
            <th scope="col">Article</th>
          </tr>
        </thead>
        <tbody>
          <xsl:for-each select="$articles">
            <xsl:variable name="i" select="position()"/>
            <xsl:variable name="rubrique" select="normalize-space(replace(string-join(../tei:head[1]//text()[not(ancestor::tei:note)], ''), '^\s*([IVXLC]+)\..*$', '$1', 's'))"/>
            <xsl:variable name="lieu" select="cartu-app:lieu(.)" xmlns:cartu-app="urn:cartu-appendice"/>
            <tr data-ord="{$i}" data-num="{$i}" data-lieu="{$lieu}">
              <td class="cartu-tm-n"><xsl:value-of select="$i"/></td>
              <td class="cartu-app-rubrique" title="{normalize-space(string-join(../tei:head[1]//text()[not(ancestor::tei:note)], ''))}"><xsl:value-of select="$rubrique"/></td>
              <td class="cartu-app-lieu"><xsl:value-of select="$lieu"/></td>
              <td class="cartu-app-article"><xsl:apply-templates select="node()[not(self::tei:pb or self::tei:note)]"/><xsl:for-each select="tei:note"><span class="cartu-app-note"><xsl:value-of select="normalize-space(.)"/></span></xsl:for-each></td>
            </tr>
          </xsl:for-each>
        </tbody>
      </table>
    </section>
  </xsl:template>

  <!-- lieu d'un article : « apud X, » ; un article « item » reprend le lieu de l'article précédent -->
  <xsl:function name="cartu-app:lieu" as="xs:string" xmlns:cartu-app="urn:cartu-appendice" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="p" as="element()"/>
    <xsl:variable name="t" select="normalize-space(string-join($p//text()[not(ancestor::tei:note)], ''))"/>
    <xsl:sequence select="if (matches($t, '^(apud|juxta|in)\s+[^,;]+', 'i')) then replace(replace($t, '^(apud|juxta|in)\s+([^,;]+).*$', '$2', 'i'), '[\s&#160;]+$', '')
        else if (matches($t, '^item([\s,.;:]|$)', 'i') and $p/preceding-sibling::tei:p) then cartu-app:lieu($p/preceding-sibling::tei:p[1])
        else ''"/>
  </xsl:function>
  <!-- 2026-10-08 : ligne d'intitulés (row[@role='label']) de tout tableau (actes compris : NDMT-AB_0171,
       NDPA-EG-04_group-4, SMMI-AB front-4…) : cellules en <th>, comme un en-tête. -->
  <xsl:template match="tei:row[@role = 'label']/tei:cell[not(@role = 'data')] | tei:cell[@role = 'label']" priority="4">
    <th>
      <xsl:if test="@cols"><xsl:attribute name="colspan" select="@cols"/></xsl:if>
      <xsl:if test="@rows"><xsl:attribute name="rowspan" select="@rows"/></xsl:if>
      <xsl:apply-templates/>
    </th>
  </xsl:template>
  <!-- ==================================================================================================
       2026-10-08 (chantier tableaux2) : ANNEXES de SAPC-AB (back-1).
       Deux tableaux filtrables et triables, sur le modèle de l'appendice VNDP-AB (cartu-appendice) :
       - liste des abbesses (« 1 Théophanie, 1204-1214. ») : N° | Abbesse | Dates (clé AAAA) ;
       - corpus des sceaux : une ligne PAR SCEAU (intitulé « I. INNOCENTIUS III. », « X. BELVACENSIS… »,
         suivi de plusieurs <p>), colonnes N° romain (clé = valeur) | Sigillant | Date (clé AAAA) |
         Rubrique (A/B · a) à e)) | Lieu (dernier « – Lieu. » de la sous-rubrique) | Notice (le reste).
       Chaque sous-rubrique ouvre une ligne « cartu-tm-partie » (masquée hors tri par N°, comme les
       intertitres de l'édition). Le TEI n'est pas modifié. Ne s'applique qu'à un annexe contenant une
       sous-division « SCEAUX ». Filtre et tri en JavaScript inline (pas de <script>).
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

  <!-- Même chose quand l'unité est servie hors annexe (excludeFragments=true, unité « Index » hors
       editByCiteType) : ses deux divisions arrivent sans @type, sous le dts:wrapper dont le titre est
       « ANNEXES ». Le titre reste rendu par le wrapper ; chaque division prend son tableau. -->
  <xsl:template match="tei:div[not(@type)][parent::*[local-name() = 'wrapper']][not(tei:div)][tei:p[chr:liste-num(.)]]" priority="28" version="3.0">
    <xsl:call-template name="chr:annexes-liste"/>
  </xsl:template>

  <xsl:template match="tei:div[not(@type)][parent::*[local-name() = 'wrapper']][tei:div/tei:head[matches(normalize-space(.), 'SCEAUX', 'i')]]" priority="28" version="3.0">
    <xsl:call-template name="chr:annexes-sceaux"/>
  </xsl:template>

  <!-- filtre (saisie, sans casse ni accents) : une section = un tableau ; les intertitres ne restent
       visibles que sans filtre et en tri par N° -->
  <xsl:variable name="chr-filtre-js">var q=this.value.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g,'').trim(),s=this.closest('section'),h=s.querySelector('th[data-cle=num]'),o=!h||h.getAttribute('aria-sort')==='ascending',n=0;s.querySelectorAll('tbody tr').forEach(function(r){if(r.classList.contains('cartu-tm-partie')){r.hidden=!!q||!o;return;}var ok=!q||r.textContent.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g,'').indexOf(q)&gt;=0;r.hidden=!ok;if(ok){n++;}});s.querySelector('.cartu-filtre-nb').textContent=n;</xsl:variable>

  <xsl:template name="chr:annexes-liste">
    <section class="cartu-appendice cartu-annexes-liste">
      <h2 class="head"><xsl:apply-templates select="tei:head[1]/node()"/></h2>
      <xsl:apply-templates select="tei:p[not(chr:liste-num(.))]"/>
      <p class="cartu-filtre">
        <label>Filtrer <input type="search" placeholder="nom, date…" aria-label="Filtrer la liste" oninput="{$chr-filtre-js}"/></label>
        <span class="cartu-filtre-compte"><span class="cartu-filtre-nb"><xsl:value-of select="count(tei:p[chr:liste-num(.)])"/></span> entrées</span>
      </p>
      <table class="cartu-table-matieres cartu-edition cartu-appendice-table cartu-annexes-table">
        <thead>
          <tr>
            <th scope="col" class="cartu-tm-n cartu-tri-col" data-cle="num" aria-sort="ascending" title="Ordre du texte" onclick="{$edt-tri-js}">N<sup>o</sup></th>
            <th scope="col" class="cartu-tri-col" data-cle="nom" data-texte="" title="Trier par nom" onclick="{$edt-tri-js}">Abbesse</th>
            <th scope="col" class="cartu-tri-col cartu-tm-date" data-cle="date" title="Trier par date" onclick="{$edt-tri-js}">Dates</th>
          </tr>
        </thead>
        <tbody>
          <xsl:for-each select="tei:p[chr:liste-num(.)]">
            <xsl:variable name="t" select="normalize-space(.)"/>
            <xsl:variable name="num" select="replace($t, '^(\d+)\s.*$', '$1')"/>
            <xsl:variable name="nom" select="replace($t, '^\d+\s+(.+?),\s*\d{3,4}\s*[–-]\s*\d{3,4}\.*$', '$1')"/>
            <xsl:variable name="dates" select="replace($t, '^\d+\s+.+?,\s*(\d{3,4}\s*[–-]\s*\d{3,4})\.*$', '$1')"/>
            <tr data-ord="{position()}" data-num="{$num}" data-nom="{$nom}" data-date="{chr:date-tri($dates)}">
              <td class="cartu-tm-n"><xsl:value-of select="$num"/></td>
              <td class="cartu-app-nom"><xsl:value-of select="$nom"/></td>
              <td class="cartu-tm-date"><xsl:value-of select="$dates"/></td>
            </tr>
          </xsl:for-each>
        </tbody>
      </table>
    </section>
  </xsl:template>

  <xsl:template name="chr:annexes-sceaux">
    <section class="cartu-appendice cartu-annexes-sceaux">
      <h2 class="head"><xsl:apply-templates select="tei:head[1]/node()"/></h2>
      <xsl:apply-templates select="tei:p"/>
      <p class="cartu-filtre">
        <label>Filtrer <input type="search" placeholder="sigillant, lieu, mot…" aria-label="Filtrer les sceaux" oninput="{$chr-filtre-js}"/></label>
        <span class="cartu-filtre-compte"><span class="cartu-filtre-nb"><xsl:value-of select="count(.//tei:p[chr:entree(.)])"/></span> sceaux</span>
      </p>
      <table class="cartu-table-matieres cartu-edition cartu-appendice-table cartu-sceaux-table">
        <thead>
          <tr>
            <th scope="col" class="cartu-tm-n cartu-tri-col" data-cle="num" aria-sort="ascending" title="Ordre du texte" onclick="{$edt-tri-js}">N<sup>o</sup></th>
            <th scope="col" class="cartu-tri-col" data-cle="nom" data-texte="" title="Trier par sigillant" onclick="{$edt-tri-js}">Sigillant</th>
            <th scope="col" class="cartu-tri-col cartu-tm-date" data-cle="date" title="Trier par date" onclick="{$edt-tri-js}">Date</th>
            <th scope="col">Rubrique</th>
            <th scope="col" class="cartu-tri-col" data-cle="lieu" data-texte="" title="Trier par lieu" onclick="{$edt-tri-js}">Lieu</th>
            <th scope="col">Notice</th>
          </tr>
        </thead>
        <tbody>
          <xsl:for-each select=".//tei:div[not(tei:div)]">
            <xsl:call-template name="chr:sceaux-feuille"/>
          </xsl:for-each>
        </tbody>
      </table>
    </section>
  </xsl:template>

  <!-- une sous-rubrique (feuille) : sa ligne d'intertitre (avec les paragraphes qui précèdent le premier
       sceau), puis une ligne par sceau -->
  <xsl:template name="chr:sceaux-feuille">
    <xsl:variable name="leaf" select="."/>
    <!-- le marqueur de page du titre de la partie n'est écrit qu'avec sa première sous-rubrique -->
    <xsl:variable name="suivante" select="exists(preceding-sibling::tei:div)"/>
    <xsl:variable name="parent-head" select="normalize-space(string(../tei:head[1]))"/>
    <xsl:variable name="rubrique" select="concat(if (contains($parent-head, ' – ')) then substring-before($parent-head, ' – ') else $parent-head, ' · ', normalize-space(string(tei:head[1])))"/>
    <xsl:variable name="premier" select="(tei:p[chr:entree(.)])[1]"/>
    <xsl:variable name="avant" select="if (exists($premier)) then tei:p[. &lt;&lt; $premier] else tei:p"/>
    <tr class="cartu-tm-partie" data-ord="{count(preceding::tei:p) + 0.5}">
      <td colspan="6">
        <strong><xsl:apply-templates select="../tei:head[1]/node()[not(self::tei:pb) or not($suivante)]"/> · <xsl:apply-templates select="tei:head[1]/node()"/></strong>
        <xsl:apply-templates select="$avant"/>
      </td>
    </tr>
    <xsl:for-each-group select="tei:p" group-starting-with="tei:p[chr:entree(.)]">
      <xsl:if test="chr:entree(current-group()[1])">
        <xsl:call-template name="chr:sceaux-entree">
          <xsl:with-param name="groupe" select="current-group()"/>
          <xsl:with-param name="feuille" select="$leaf"/>
          <xsl:with-param name="rubrique" select="$rubrique"/>
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
    <xsl:variable name="tete" select="$groupe[1]"/>
    <xsl:variable name="texte" select="normalize-space(string($tete))"/>
    <xsl:variable name="roman" select="replace($texte, '^([IVXLC]+)\..*$', '$1')"/>
    <xsl:variable name="nom" select="replace($texte, '^[IVXLC]+\.\s*', '')"/>
    <xsl:variable name="datep" select="($groupe[position() gt 1][chr:datep(.)])[1]"/>
    <xsl:variable name="date" select="if (exists($datep)) then replace(normalize-space(string($datep)), '^[–-]\s*', '') else ''"/>
    <xsl:variable name="lieu" select="replace(replace(normalize-space(string(($feuille//tei:p[. &lt;&lt; $tete][chr:lieu(.)])[last()])), '^[–-]\s*', ''), '[\s.,]+$', '')"/>
    <tr data-ord="{count($tete/preceding::tei:p) + 1}" data-num="{chr:roman($roman)}" data-nom="{$nom}" data-date="{chr:date-tri($date)}" data-lieu="{$lieu}">
      <td class="cartu-tm-n"><xsl:apply-templates select="$tete/tei:pb"/><xsl:value-of select="$roman"/></td>
      <td class="cartu-app-nom"><xsl:value-of select="$nom"/></td>
      <td class="cartu-tm-date"><xsl:apply-templates select="$datep/tei:pb"/><xsl:value-of select="$date"/></td>
      <td class="cartu-app-rubrique" title="{$rubrique}"><xsl:value-of select="$rubrique"/></td>
      <td class="cartu-app-lieu"><xsl:value-of select="$lieu"/></td>
      <td class="cartu-app-article"><xsl:apply-templates select="$groupe[position() gt 1][not(. is $datep)]"/></td>
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

  <!-- 2026-10-08 (chantier tableaux2) : titre (group ou dts:wrapper) portant une note. La note est hors de
       tout tei:text (ou le rendu du titre est fait par un modèle qui ne la collecte pas : Édition, wrapper
       sans texte) : la collecte des notes de hteiml ne la voit pas et l'appel reste sans texte (SMCP-PR
       group-3-2-6, NDPA-EG-01 group-2-9, NDPA-EG-03 group-3-2). Le bloc de notes du titre est ajouté après
       le rendu, seulement si ce rendu n'en contient pas déjà un (même garde que le wrapper de hteiml). -->
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
