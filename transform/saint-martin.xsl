<?xml version="1.0" encoding="UTF-8"?>
<!-- 2026-10-19 : chapitre « saint-martin » du Cartulaire blanc de Saint-Denis, sous-collection des cartulaires.
     DoTS prend transform/cartulaires/<ressource>.xsl avant cartulaires.xsl (routes.xqm) : le chapitre
     garde le rendu de la feuille de Saint-Denis (cartulaires-saint-denis.xsl, copie de saint-denis.xsl). -->
<xsl:transform version="1.1" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:import href="cartulaires-saint-denis.xsl"/>
</xsl:transform>
