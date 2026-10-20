<?xml version="1.0" encoding="UTF-8"?>
<!-- 2026-10-08 : module « edition », inclus par cartulaires.xsl.
     PAGE ÉDITION (unité group servie entière : « part » dans editByCiteType) : la liste des actes
     prend la forme de la « Table du cartulaire » de SSCO-AB (r7987684, modèle validé par Maxime) :
     mêmes classes (table.cartu-table-matieres), mêmes colonnes N° | Pièce | Date | Folio | Page,
     2026-10-19 : tableau triable et filtrable du module commun (constructeur cartu-tf du module
     tableaux, classes tf-*, comportement dans le JS générique de l'ÉLEC) ; la partie (sous-groupe),
     autrefois en ligne d'intertitre, est une colonne filtrable (décision de Maxime).
     Folio : premier pb portant @ed (témoin manuscrit) ; Page : page de l'édition où l'acte
     commence. Une colonne vide pour tous les actes n'est pas affichée.
     Version précédente (filtre, 50 premiers actes) : scratchpad\chantier\edition\*.avant_ssco. -->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:dts="https://w3id.org/dts/api#"
  xmlns:edt="urn:cartu-edition"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="tei dts edt xs">


  <xsl:template match="tei:group[parent::*[local-name() = 'wrapper']][.//tei:text]" priority="30">
    <div class="group">
      <xsl:if test="@xml:id"><xsl:attribute name="id" select="@xml:id"/></xsl:if>
      <xsl:if test="tei:head"><h1 class="head"><xsl:apply-templates select="tei:head/node()"/></h1></xsl:if>
      <xsl:apply-templates select="tei:argument"/>
      <!-- 2026-10-08 : SSCO-AB a sa propre « Table du cartulaire » (back, div[@type='table'], avec les
           folios du manuscrit) : c'est elle qui sert de tableau à la page Édition (Maxime : « réutiliser
           la table du cartulaire au niveau édition, supprimer le doublon »). Le fragment du groupe ne
           contient pas le back : on lit le TEI complet posé dans compagnons/ (pas l'API). -->
      <!-- 2026-10-20 : plus de tableau sur les pages de groupe (l'équipe ne veut pas de tableau filtrable à la place
           du sommaire) : la liste des actes est le sommaire de dots-vue. edt-tableau et edt:table-propre restent
           définis mais ne sont plus appelés. -->
    </div>
  </xsl:template>

  <!-- 2026-10-19 : la table du livre ne vaut que pour la page Édition entière (groupe de premier niveau) ;
       les sous-groupes (censier, parties) gardent la liste de leurs actes. -->
  <xsl:function name="edt:table-propre" as="element()*">
    <xsl:param name="g" as="element()?"/>
    <!-- le fragment servi n'a pas d'ancêtres : on regarde la place du groupe dans le TEI complet -->
    <xsl:variable name="place" select="if (exists($g/@xml:id)) then (edt:compagnon()//tei:group[@xml:id = $g/@xml:id])[1] else ()"/>
    <xsl:sequence select="if ($resource = 'SSCO-AB' and exists($place) and empty($place/ancestor::tei:group)) then edt:compagnon()//tei:back//tei:div[@type = 'table']//tei:list[@type = 'gloss'] else ()"/>
  </xsl:function>

  <!-- 2026-10-08 : TEI COMPLET du cartulaire servi. Localement, compagnons/ est une jonction vers
       cartulaires-todo\data (sous-dossiers MAUB-AB, NDPA-EG, SCCO-AB, SMPA-AB) ; dans le dépôt publié,
       ../data/. Pas d'appel à l'API (interblocage de BaseX). -->
  <xsl:function name="edt:compagnon" as="document-node()?">
    <xsl:variable name="base" select="replace($resource, '-\d+$', '')"/>
    <xsl:variable name="cands" select="for $u in (concat('compagnons/', $resource, '.xml'), concat('compagnons/', $base, '/', $resource, '.xml'),
        concat('../data/', $resource, '.xml'), concat('../data/', $base, '/', $resource, '.xml')) return resolve-uri($u, static-base-uri())"/>
    <xsl:sequence select="if ($resource = '') then () else (for $u in $cands[doc-available(.)][1] return document($u))"/>
  </xsl:function>
  <xsl:function name="edt:titre" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="e" as="element()?"/>
    <xsl:sequence select="normalize-space(string-join($e/tei:head[1]//text()[not(ancestor::tei:note)], ''))"/>
  </xsl:function>
  <!-- clé de comparaison d'un titre : sans casse, accents, espaces ni ponctuation (le disque peut avoir
       des titres recassés pas encore réingérés : « LIBER NONUS.LITTERÆ » = « Liber nonus. Litteræ ») -->
  <xsl:function name="edt:cle" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="e" as="element()?"/>
    <xsl:sequence select="replace(replace(lower-case(normalize-unicode(edt:titre($e), 'NFD')), '\p{M}', ''), '[^\p{L}\p{N}]', '')"/>
  </xsl:function>

  <!-- 2026-10-08 : page Édition servie SANS ses actes (excludeFragments=true : « part » n'est plus dans
       editByCiteType, pour que chaque acte garde sa page). Le groupe est retrouvé dans le TEI complet par
       son titre ; le tableau est fait à partir de lui. Toute autre page sans acte (chapitre d'introduction)
       n'a pas de groupe de ce titre : next-match, rendu inchangé. -->
  <xsl:template match="*[local-name() = 'wrapper'][not(.//tei:text)][tei:head]" priority="26">
    <xsl:variable name="h" select="edt:cle(.)"/>
    <xsl:variable name="g" select="(edt:compagnon()//tei:group[tei:head][.//tei:text[@xml:id]][edt:cle(.) = $h])[1]"/>
    <xsl:choose>
      <xsl:when test="exists($g)">
        <div class="group">
          <xsl:if test="$g/@xml:id"><xsl:attribute name="id" select="$g/@xml:id"/></xsl:if>
          <h1 class="head"><xsl:apply-templates select="tei:head[1]/node()"/></h1>
          <xsl:apply-templates select="$g/tei:argument"/>
          <!-- 2026-10-20 : pas de tableau, sommaire de dots-vue (voir plus haut) -->
        </div>
      </xsl:when>
      <xsl:otherwise><xsl:next-match/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- 2026-10-19 : même page, forme de DoTS dev (0fb0c43) : servie sans ses actes, elle GARDE son élément
       group (wrapper > group, titre dans le group). Le groupe est retrouvé dans le TEI complet (compagnon)
       par son identifiant. -->
  <xsl:template match="tei:group[parent::*[local-name() = 'wrapper']][not(.//tei:text)]" priority="30">
    <xsl:variable name="id" select="string(@xml:id)"/>
    <xsl:variable name="g" select="if ($id = '') then () else (edt:compagnon()//tei:group[@xml:id = $id][.//tei:text[@xml:id]])[1]"/>
    <xsl:choose>
      <xsl:when test="exists($g)">
        <div class="group">
          <xsl:attribute name="id" select="$id"/>
          <xsl:if test="tei:head"><h1 class="head"><xsl:apply-templates select="tei:head[1]/node()"/></h1></xsl:if>
          <xsl:apply-templates select="$g/tei:argument"/>
          <!-- 2026-10-20 : pas de tableau, sommaire de dots-vue (voir plus haut) -->
        </div>
      </xsl:when>
      <xsl:otherwise><xsl:next-match/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="edt-tableau">
      <xsl:variable name="groupe" select="."/>
      <xsl:variable name="actes" select=".//tei:text[@xml:id]"/>
      <xsl:variable name="avec-folio" select="exists($actes[edt:folio(.) != ''])"/>
      <xsl:variable name="avec-page" select="exists($actes[edt:page(.) != ''])"/>
      <xsl:variable name="avec-partie" select="exists(.//tei:group[tei:head][tei:text[@xml:id]] except .)"/>
      <xsl:call-template name="cartu-tf">
        <xsl:with-param name="classe" select="'cartu-table-matieres cartu-edition'"/>
        <xsl:with-param name="nom" select="concat('cartulaires-', $resource, '-actes')"/>
        <xsl:with-param name="unite" select="'actes'"/>
        <xsl:with-param name="colonnes" select="(
          map { 'libelle': 'N°', 'num': true(), 'filtre': 'numeros', 'classe': 'cartu-tm-n' },
          map { 'libelle': 'Pièce', 'num': false(), 'filtre': 'texte', 'classe': 'cartu-tm-titre' },
          map { 'libelle': 'Date', 'num': false(), 'filtre': 'texte', 'classe': 'cartu-tm-date' },
          if ($avec-partie) then map { 'libelle': 'Partie', 'num': false(), 'filtre': 'liste', 'classe': 'cartu-tm-partie-col' } else (),
          if ($avec-folio) then map { 'libelle': 'Folio', 'num': false(), 'filtre': '', 'classe': 'cartu-tm-fol' } else (),
          if ($avec-page) then map { 'libelle': 'Page', 'num': true(), 'filtre': 'numeros', 'classe': 'cartu-tm-p' } else ())"/>
        <xsl:with-param name="lignes" as="element()*">
          <xsl:for-each select="$actes">
            <xsl:variable name="href" select="concat($document-base, $resource, '?refId=', @xml:id)"/>
            <xsl:variable name="piece" select="edt:piece(.)"/>
            <xsl:variable name="partie" select="(ancestor::tei:group[tei:head] except $groupe/ancestor-or-self::tei:group)[last()]"/>
            <tr>
              <td data-sort="{edt:num(.)}" data-f="{edt:num(.)}"><xsl:value-of select="@n"/></td>
              <td><a href="{$href}"><xsl:if test="string-length($piece) gt 120"><xsl:attribute name="title" select="$piece"/></xsl:if><xsl:value-of select="edt:piece-courte($piece)"/></a></td>
              <td data-sort="{edt:date-tri(.)}"><xsl:value-of select="edt:date(.)"/></td>
              <xsl:if test="$avec-partie"><td><xsl:value-of select="edt:titre($partie)"/></td></xsl:if>
              <xsl:if test="$avec-folio"><td><xsl:value-of select="edt:folio(.)"/></td></xsl:if>
              <xsl:if test="$avec-page">
                <xsl:variable name="tp" select="edt:tome-page(edt:page(.))"/>
                <td data-sort="{if ($tp[2] castable as xs:integer) then xs:integer(($tp[1][. castable as xs:integer], '0')[1]) * 100000 + xs:integer($tp[2]) else 0}" data-f="{$tp[2][. castable as xs:integer] ! xs:integer(.)}"><xsl:if test="edt:page(.) != ''"><a href="{$href}"><xsl:value-of select="edt:page-libelle($tp)"/></a></xsl:if></td>
              </xsl:if>
            </tr>
          </xsl:for-each>
        </xsl:with-param>
      </xsl:call-template>
  </xsl:template>

  <!-- texte visible d'un élément, sans les notes -->
  <xsl:function name="edt:txt" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="e" as="node()*"/>
    <!-- un <lb/> sépare deux mots (« DOYEN<lb/>DE ») : compté comme une espace -->
    <xsl:sequence select="normalize-space(string-join($e//(text() | tei:lb)[not(ancestor::tei:note)] ! (if (self::tei:lb) then ' ' else string(.)), ''))"/>
  </xsl:function>
  <!-- Pièce : titre de l'acte, sinon son analyse, sinon le début du texte -->
  <xsl:function name="edt:piece" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="t" as="element()"/>
    <!-- un titre qui n'est que le numéro de l'acte (« III. », VNDP-AB) n'est pas un titre de pièce -->
    <xsl:variable name="cands" select="(edt:txt(($t/tei:front/tei:head, $t/tei:body/tei:head)[1]), edt:txt($t/tei:front/tei:argument[1]), edt:txt($t/tei:front/tei:div[@type = 'analyse'][1]))[. != ''][not(matches(., '^[\s\[\(]*(N[°o]\s*)?[IVXLCDM0-9]+[a-z]?(\s*bis|\s*ter)?[\s.\]\)]*$', 'i'))]"/>
    <xsl:variable name="p" select="if (exists($cands)) then $cands[1] else edt:txt($t/tei:body)"/>
    <xsl:sequence select="$p"/>
  </xsl:function>
  <!-- Pièce affichée : coupée vers 110 caractères, sur une fin de mot, avec « … » (les analyses de
       SMPA-AB-03 font plusieurs lignes) ; le texte complet reste dans l'attribut title du lien. -->
  <xsl:function name="edt:piece-courte" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="p" as="xs:string"/>
    <xsl:sequence select="if (string-length($p) le 120) then $p else concat(replace(substring($p, 1, 110), '[\s,;:.(«“-]+[^\s]*$', ''), ' …')"/>
  </xsl:function>
  <xsl:function name="edt:date" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="t" as="element()"/>
    <!-- la date seule (comme la table de SSCO) : docDate contient souvent aussi le lieu (« Compiègne ») -->
    <xsl:variable name="d" select="($t/tei:front/tei:docDate[1]//tei:date[edt:txt(.) != ''])[1]"/>
    <xsl:sequence select="replace(if ($d) then edt:txt($d) else edt:txt($t/tei:front/tei:docDate[1]), '[\s.,;]+$', '')"/>
  </xsl:function>
  <xsl:function name="edt:date-tri" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="t" as="element()"/>
    <xsl:variable name="d" select="($t/tei:front/tei:docDate//tei:date/(@when, @notBefore, @from)[matches(., '^\d{3,4}')])[1]"/>
    <xsl:sequence select="if ($d) then format-number(number(substring-before(concat($d, '-'), '-')), '0000') || substring($d, string-length(substring-before(concat($d, '-'), '-')) + 1) else ''"/>
  </xsl:function>
  <xsl:function name="edt:num" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="t" as="element()"/>
    <xsl:variable name="d" select="replace(string($t/@xml:id), '^.*_0*(\d+)[^_]*$', '$1')"/>
    <xsl:sequence select="if (matches($d, '^\d+$')) then $d else string(count($t/preceding::tei:text) + 1)"/>
  </xsl:function>
  <xsl:function name="edt:folio" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="t" as="element()"/>
    <xsl:sequence select="normalize-space(($t//tei:pb[@ed][normalize-space(@n)])[1]/@n)"/>
  </xsl:function>
  <!-- page de l'édition où l'acte commence : dernier pb (sans @ed) avant l'acte, sinon le premier dedans -->
  <xsl:function name="edt:page" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="t" as="element()"/>
    <xsl:sequence select="normalize-space(($t/preceding::tei:pb[not(@ed)][normalize-space(@n)][1], ($t//tei:pb[not(@ed)][normalize-space(@n)])[1])[1]/@n)"/>
  </xsl:function>
  <!-- 2026-10-19 : page de l'édition, sous ses différentes notations (« 67 », « page 67 », « t1_p067 » NDCH,
       « 1_0003 » NDVC et SMCP, « I. 9 » NDPA-EG-01 et SGDP) → (tome en chiffres arabes ou '', page). -->
  <xsl:function name="edt:tome-page" as="xs:string*" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="n" as="xs:string"/>
    <xsl:variable name="romains" select="('I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X')"/>
    <xsl:analyze-string select="normalize-space($n)" regex="^(?:t?(\d+)_p?|([IVX]+)\.\s*|page\s+)?0*(\d+)$">
      <xsl:matching-substring>
        <xsl:sequence select="(if (regex-group(1) != '') then string(number(regex-group(1))) else if (regex-group(2) != '') then string(index-of($romains, regex-group(2))[1]) else '', regex-group(3))"/>
      </xsl:matching-substring>
      <xsl:non-matching-substring><xsl:sequence select="('', .)"/></xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:function>
  <xsl:function name="edt:page-libelle" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="tp" as="xs:string*"/>
    <xsl:variable name="romains" select="('I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X')"/>
    <xsl:sequence select="if ($tp[1] != '' and $tp[2] castable as xs:integer) then concat('t. ', $romains[xs:integer($tp[1])], ', p. ', $tp[2]) else if ($tp[2] castable as xs:integer) then concat('p. ', $tp[2]) else string($tp[2])"/>
  </xsl:function>
</xsl:stylesheet>
