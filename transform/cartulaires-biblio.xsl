<?xml version="1.0" encoding="UTF-8"?>
<!-- 2026-10-08 : module « biblio », inclus par cartulaires.xsl. Les bibliographies des cartulaires
     (« Orientation bibliographique », SAPC-AB « II – Bibliographie », SMPA-AB-03 « Liste des ouvrages le
     plus souvent cités », SMMI-AB « Bibliographie ») passent par le modèle COMMUN à tous les projets
     (../commun/bibliographie.xsl, modèle biblio-page), comme Delescluze et les chroniques latines.
     Deux formes : la division dans le document, ou la page servie seule (dts:wrapper sans teiHeader,
     reconnue à son titre). -->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:dts="https://w3id.org/dts/api#"
  exclude-result-prefixes="tei dts">
  <xsl:template match="tei:div[ends-with(@xml:id, '_biblio') or @xml:id = 'SMMI-AB_front-2']
      | *[local-name() = 'wrapper'][not(tei:teiHeader)][tei:head]
          [matches(normalize-space(tei:head[1]), '^(orientation bibliographique|(II\s*.\s*)?bibliographie|liste des ouvrages le plus souvent cit)', 'i')]"
      priority="45">
    <xsl:call-template name="biblio-page">
      <xsl:with-param name="div" select="."/>
    </xsl:call-template>
  </xsl:template>
</xsl:stylesheet>
