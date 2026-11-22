<?xml version="1.0" encoding="UTF-8"?>
<!-- Page de titre des cartulaires, servie par /api/dts/cover?id=<ressource> (cover.xqm appelle
     transform/<corpus>/teiHeader2html.xsl). Feuille autonome (2026-10-20 : le modèle commun
     page-de-titre.xsl n'est plus importé, ses règles sont ici).
     Écart (décision de Maxime, 19/10/2026) : « Édité par » = les éditeurs du livre imprimé
     (titleStmt/author) ; « Édition électronique par » = le principal. Chapitres du Cartulaire blanc
     de Saint-Denis (sans author) : règle de la page de titre de Saint-Denis.
     Structure produite :
       div.titlestmt
         h1.head                                   ($th-titre)
         p.subtitle                                ($th-sous-titre, s'il existe)
         p.editors > span.editors-label + span.editor…   (« Édité par », $th-editeurs)
         p.editors « Édition électronique par »    ($th-edition-electronique)
         span.date                                 ($th-date) -->
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:th="urn:page-de-titre"
  exclude-result-prefixes="tei xs th">

  <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="yes"/>

  <xsl:variable name="th-ts" select="(//tei:fileDesc/tei:titleStmt)[1]"/>

  <!-- Titre : le premier sans @type, sinon le premier. -->
  <xsl:variable name="th-titre" select="normalize-space(($th-ts/tei:title[not(@type)], $th-ts/tei:title)[1])"/>
  <xsl:variable name="th-sous-titre" select="normalize-space($th-ts/tei:title[@type = 'sub'][1])"/>

  <!-- Éditeurs : les auteurs du livre imprimé ; pour les chapitres du Cartulaire blanc (sans author), le
       principal, et l'édition électronique par les respStmt de modélisation ou de publication. -->
  <!-- 2026-11-22 (Olivier Canteaut) : un texte d'auteur sans principal ni respStmt (introduction du Cartulaire blanc) = « Par ». -->
  <xsl:variable name="th-label-editeurs" select="if (exists($th-ts/tei:author) and empty($th-ts/tei:principal) and empty($th-ts/tei:respStmt)) then 'Par ' else 'Édité par '"/>
  <xsl:variable name="th-sd" select="empty($th-ts/tei:author) and exists($th-ts/tei:respStmt[contains(tei:resp, 'modélisation') or contains(tei:resp, 'publication')])"/>
  <xsl:variable name="th-editeurs" select="if ($th-sd) then $th-ts/tei:principal else $th-ts/tei:author"/>
  <xsl:variable name="th-edition-electronique" select="if ($th-sd) then $th-ts/tei:respStmt[contains(tei:resp, 'modélisation') or contains(tei:resp, 'publication')]/tei:name else $th-ts/tei:principal"/>

  <!-- Date : l'année de publicationStmt/date. -->
  <xsl:variable name="th-date" select="replace(normalize-space((//tei:fileDesc/tei:publicationStmt/tei:date)[1]), '^\D*(\d{4}).*$', '$1')"/>
  <!-- 2026-11-12 (Maxime, La Roche) : date de la première édition électronique (editionStmt) : « 2006-2009 ». -->
  <xsl:variable name="th-date-premiere" select="replace(normalize-space((//tei:fileDesc/tei:editionStmt//tei:date)[1]), '^\D*(\d{4}).*$', '$1')"/>
  <!-- 2026-11-13 (Maxime) : période « première publication - dernière intervention ». Début : editionStmt (première
       publication en ligne, dates d'Olivier Canteaut du 13/11), à défaut la plus ancienne année des respStmt et de
       publicationStmt ; fin : la plus récente de ces années (« Indexation (2008) », « Suivi technique (2007–…) »). -->
  <xsl:variable name="th-annees" as="xs:integer*" select="(for $r in $th-ts/tei:respStmt/tei:resp, $a in tokenize(replace(string($r), '\D+', ' '), ' ')[matches(., '^(1[89]|20)\d\d$')] return xs:integer($a), for $d in $th-date[matches(., '^\d{4}$')] return xs:integer($d))"/>
  <xsl:variable name="th-debut" as="xs:integer?" select="if (matches($th-date-premiere, '^\d{4}$')) then xs:integer($th-date-premiere) else min($th-annees)"/>
  <xsl:variable name="th-fin" as="xs:integer?" select="max($th-annees)"/>

  <!-- Nom affiché : prénom et nom quand ils sont balisés (persName avec rôle, affiliation…),
       sinon le texte. Accepte aussi des chaînes. -->
  <xsl:function name="th:nom" as="xs:string">
    <xsl:param name="n"/>
    <xsl:sequence select="
      if ($n instance of element() and ($n//tei:forename or $n//tei:surname))
      then normalize-space(concat($n//tei:forename[1], ' ', $n//tei:surname[1]))
      else normalize-space(string($n))"/>
  </xsl:function>

  <xsl:template match="/">
    <html xmlns="http://www.w3.org/1999/xhtml" lang="fr">
      <div id="aside">to delete</div>
      <div id="center">
        <div id="main">
          <div id="article"><xsl:apply-templates select="$th-ts"/></div>
        </div>
      </div>
    </html>
  </xsl:template>

  <xsl:template match="tei:titleStmt">
    <div class="titlestmt">
      <h1 class="head"><xsl:value-of select="$th-titre"/></h1>
      <xsl:if test="$th-sous-titre != ''">
        <p class="subtitle"><xsl:value-of select="$th-sous-titre"/></p>
      </xsl:if>
      <xsl:call-template name="th-ligne">
        <xsl:with-param name="label" select="$th-label-editeurs"/>
        <xsl:with-param name="noms" select="$th-editeurs"/>
      </xsl:call-template>
      <!-- 2026-11-22 (Olivier Canteaut, « direction scientifique ») : le principal = « sous la direction de » ; plus de
           « et al. » (les collaborateurs sont dans la notice). Chapitres de Saint-Denis : « Édition électronique par ». -->
      <xsl:variable name="premier" select="if (exists($th-edition-electronique)) then th:nom($th-edition-electronique[1]) else ''"/>
      <xsl:call-template name="th-ligne">
        <xsl:with-param name="label" select="if ($th-sd) then 'Édition électronique par '
          else if (matches($premier, '^[AEIOUYHÉÈÂÎaeiouyh]')) then 'Édition électronique sous la direction d’'
          else 'Édition électronique sous la direction de '"/>
        <xsl:with-param name="noms" select="$th-edition-electronique"/>
      </xsl:call-template>
      <xsl:if test="exists($th-debut)">
        <xsl:variable name="periode" select="if (exists($th-fin) and $th-fin gt $th-debut) then concat($th-debut, '-', $th-fin) else string($th-debut)"/>
        <!-- 2026-11-22 (Olivier Canteaut, Saint-Antoine) : date de l'édition imprimée (sourceDesc/bibl/date) à côté de
             celle de l'édition électronique. -->
        <xsl:variable name="imprime" select="normalize-space((//tei:fileDesc/tei:sourceDesc//tei:bibl//tei:date)[1])"/>
        <span class="date"><xsl:value-of select="if ($imprime != '') then concat('Édition imprimée : ', $imprime, ' — édition électronique : ', $periode) else $periode"/></span>
      </xsl:if>
    </div>
  </xsl:template>

  <xsl:template name="th-ligne">
    <xsl:param name="label"/>
    <xsl:param name="noms"/>
    <xsl:param name="etal" select="false()"/>
    <xsl:variable name="liste" select="for $n in $noms return th:nom($n)"/>
    <xsl:if test="exists($liste[. != ''])">
      <p class="editors">
        <span class="editors-label"><xsl:value-of select="$label"/></span>
        <xsl:for-each select="$liste[. != '']">
          <span class="editor"><xsl:value-of select="."/></span>
          <xsl:choose>
            <xsl:when test="position() = last() - 1"> et </xsl:when>
            <xsl:when test="position() &lt; last()">, </xsl:when>
          </xsl:choose>
        </xsl:for-each>
        <xsl:if test="$etal"><xsl:text> et al.</xsl:text></xsl:if>
      </p>
    </xsl:if>
  </xsl:template>

</xsl:transform>
