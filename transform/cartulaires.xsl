<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.1" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tei"
>
  <xsl:import href="../hteiml/xsl/tei2html.xsl"/>
  <!-- Diple relativement à ici pour CSS et js par défaut 
  <xsl:param name="dipleHref">
    <xsl:value-of select="$xslBase"/>
    <xsl:text>../../diple/</xsl:text>
  </xsl:param>
  -->
  <!-- Passer à travers les unclear (pour la démo) -->
  <xsl:template match="tei:unclear">
    <xsl:apply-templates/>
  </xsl:template>
  <!-- ne pas sortir le back qui ne doit contenir que des index -->
  <xsl:template match="/tei:TEI/tei:text/tei:back"/>
  <!-- ne pas sortir les pages -->
  <xsl:template match="tei:pb"/>
  <!-- lien vers un dictionnaire -->
  <xsl:template match="@xml:lang[.='fro']">
    <!-- à corriger
    <xsl:attribute name="ondblclick">if (window.Win) Win.dmf()</xsl:attribute>
    -->
  </xsl:template>
  <!-- Nom d'un acte -->
  <xsl:template match="tei:group/tei:text" mode="a">
    <a>
      <xsl:attribute name="href">
        <xsl:apply-templates select="." mode="href"/>
      </xsl:attribute>
      <xsl:attribute name="title">
        <xsl:value-of select="normalize-space(tei:front/tei:docDate)"/>
      </xsl:attribute>
      <xsl:if test="@n">
      <b>
        <xsl:value-of select="@n"/>
      </b>
      </xsl:if>
      <xsl:variable name="date">
        <xsl:apply-templates select="tei:front/tei:docDate/tei:date[1]" mode="label"/>
      </xsl:variable>
      <xsl:if test="$date != ''">
        <xsl:text> (</xsl:text>
        <xsl:value-of select="$date"/>
        <xsl:text>) </xsl:text>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="tei:front/tei:head">
          <xsl:apply-templates select="tei:front/tei:head" mode="title"/>
        </xsl:when>
        <xsl:when test="tei:front/tei:argument/tei:head">
          <xsl:apply-templates select="tei:front/tei:argument/tei:head" mode="title"/>
        </xsl:when>
      </xsl:choose>
    </a>
  </xsl:template>
  <!-- Pas de table des matières à l'intérieur d'un acte -->
  <xsl:template match="tei:group/tei:text" mode="ul" priority="2"/>

  <xsl:template match="//tei:front/tei:div[@type='dissertation']">
    <section class="div dissertation level2">
      <h3>Dissertation critique</h3><xsl:apply-templates/>
    </section>
  </xsl:template>

 <xsl:template match="tei:ref[@target]">
   <xsl:choose>
     <xsl:when test="@type = 'see'">
       <xsl:variable name="target" select="./@target"/>
       <xsl:variable name="idDoc"  select="translate(substring-before($target, '_'), '#', '')"/>
       <xsl:variable name="refId" select="translate(./@corresp, '#', '')"/>
       <xsl:variable name="url" select="concat('https://dev.chartes.psl.eu/elec/cartulaires/document/', $idDoc, '?refId=', $refId, $target)"/>
      
       <a href="{$url}">
        <xsl:apply-templates/>
    </a>
   </xsl:when>
     <xsl:otherwise>
       <xsl:variable name="idActe" select="substring-after(@target, '#')"/>
    <xsl:variable name="idDoc"  select="substring-before($idActe, '_')"/>
    <xsl:variable name="url" select="concat('https://dev.chartes.psl.eu/elec/cartulaires/document/', $idDoc, '?refId=', $idActe)"/>
    <a href="{$url}">
        <xsl:apply-templates/>
    </a>
     </xsl:otherwise>
   </xsl:choose>
</xsl:template>

   </xsl:transform>
