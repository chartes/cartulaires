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
  <xsl:variable name="th-label-editeurs">Édité par </xsl:variable>
  <xsl:variable name="th-sd" select="empty($th-ts/tei:author) and exists($th-ts/tei:respStmt[contains(tei:resp, 'modélisation') or contains(tei:resp, 'publication')])"/>
  <xsl:variable name="th-editeurs" select="if ($th-sd) then $th-ts/tei:principal else $th-ts/tei:author"/>
  <xsl:variable name="th-edition-electronique" select="if ($th-sd) then $th-ts/tei:respStmt[contains(tei:resp, 'modélisation') or contains(tei:resp, 'publication')]/tei:name else $th-ts/tei:principal"/>

  <!-- Date : l'année de publicationStmt/date. -->
  <xsl:variable name="th-date" select="replace(normalize-space((//tei:fileDesc/tei:publicationStmt/tei:date)[1]), '^\D*(\d{4}).*$', '$1')"/>

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
      <xsl:call-template name="th-ligne">
        <xsl:with-param name="label">Édition électronique par </xsl:with-param>
        <xsl:with-param name="noms" select="$th-edition-electronique"/>
      </xsl:call-template>
      <xsl:if test="$th-date != ''">
        <span class="date"><xsl:value-of select="$th-date"/></span>
      </xsl:if>
    </div>
  </xsl:template>

  <xsl:template name="th-ligne">
    <xsl:param name="label"/>
    <xsl:param name="noms"/>
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
      </p>
    </xsl:if>
  </xsl:template>

</xsl:transform>
