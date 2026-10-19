<?xml version="1.0" encoding="UTF-8"?>
<!-- Page de titre des cartulaires (route /api/dts/cover) : modèle commun page-de-titre.xsl.
     Écart (décision de Maxime, 19/10/2026) : « Édité par » = les éditeurs du livre imprimé
     (titleStmt/author) ; « Édition électronique par » = le principal. -->
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tei">

  <xsl:import href="page-de-titre.xsl"/>

  <!-- Chapitres du Cartulaire blanc de Saint-Denis (sans author) : règle de la page de titre de Saint-Denis. -->
  <xsl:variable name="th-sd" select="empty($th-ts/tei:author) and exists($th-ts/tei:respStmt[contains(tei:resp, 'modélisation') or contains(tei:resp, 'publication')])"/>
  <xsl:variable name="th-editeurs" select="if ($th-sd) then $th-ts/tei:principal else $th-ts/tei:author"/>
  <xsl:variable name="th-edition-electronique" select="if ($th-sd) then $th-ts/tei:respStmt[contains(tei:resp, 'modélisation') or contains(tei:resp, 'publication')]/tei:name else $th-ts/tei:principal"/>
</xsl:transform>
