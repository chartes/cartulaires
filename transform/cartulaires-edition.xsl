<?xml version="1.0" encoding="UTF-8"?>
<!-- 2026-10-08 : module « edition », inclus par cartulaires.xsl.
     PAGE ÉDITION (unité group) : titre et présentation du groupe ; la liste des actes est le sommaire
     de dots-vue (2026-10-20 : plus de tableau sur les pages de groupe, l'équipe n'en veut pas à la
     place du sommaire). Les fonctions edt: restantes servent aussi aux tableaux et aux pages. -->
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
    </div>
  </xsl:template>


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
        </div>
      </xsl:when>
      <xsl:otherwise><xsl:next-match/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- texte visible d'un élément, sans les notes -->
  <xsl:function name="edt:txt" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="e" as="node()*"/>
    <!-- un <lb/> sépare deux mots (« DOYEN<lb/>DE ») : compté comme une espace -->
    <xsl:sequence select="normalize-space(string-join($e//(text() | tei:lb)[not(ancestor::tei:note)] ! (if (self::tei:lb) then ' ' else string(.)), ''))"/>
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
