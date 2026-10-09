<?xml version="1.0" encoding="UTF-8"?>
<!-- 2026-10-08 : module « ordinaux », inclus par cartulaires.xsl (xsl:include : même préséance que la
     feuille principale). Copie autonome de transform\commun\ordinaux.xsl (chantier ordinaux) : le module
     commun n'est pas accessible depuis dots-transform-local. Met en exposant le suffixe des ordinaux
     (XIIIe → XIII<sup>e</sup>) dans les textes français ; hors transcriptions, apparat, lat/fro, sup existant.
     Modèle text() de priorité 40 + xsl:next-match : le traitement de cartulaires.xsl est conservé. -->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:ord="urn:ordinaux"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="tei ord xs">

  <!-- Chiffres romains valides (non vides : le contrôle de longueur est dans ord:split) -->
  <xsl:variable name="ord:roman" select="'M{0,3}(?:CM|CD|D?C{0,3})(?:XC|XL|L?X{0,3})(?:IX|IV|V?I{0,3})'"/>
  <!-- Suffixes d'ordinal (ordre sans importance : la regex est ancrée) -->
  <xsl:variable name="ord:suff" select="'(?:èmes|ème|emes|eme|ères|ère|eres|ere|ers|er|res|re|ndes|nde|nd|es|e)'"/>
  <!-- Mot : suite de lettres/chiffres, avec éventuels points internes (132.8e reste un seul mot) -->
  <xsl:variable name="ord:tok" select="'[\p{L}\p{N}]+(?:\.[\p{L}\p{N}]+)*'"/>

  <!-- Renvoie (nombre, suffixe) si le mot entier est un ordinal, sinon la séquence vide. -->
  <xsl:function name="ord:split" as="xs:string*">
    <xsl:param name="tok" as="xs:string"/>
    <xsl:variable name="rom" select="concat('^(', $ord:roman, ')(', $ord:suff, ')$')"/>
    <xsl:variable name="ara" select="'^(\d+)(?:èmes|ème|emes|eme|ères|ère|eres|ere|ers|er|res|re|ndes|nde|nd|es|e)$'"/>
    <xsl:choose>
      <xsl:when test="matches($tok, $rom)">
        <xsl:variable name="num" select="replace($tok, $rom, '$1')"/>
        <xsl:variable name="suf" select="replace($tok, $rom, '$2')"/>
        <!-- « I » seul ne prend que « er » (Ier) : évite Ce, Le, De, Me, Ie… -->
        <xsl:if test="string-length($num) ge 2 or ($num = 'I' and $suf = ('er', 'ers'))">
          <xsl:sequence select="($num, $suf)"/>
        </xsl:if>
      </xsl:when>
      <xsl:when test="matches($tok, $ara)">
        <xsl:sequence select="(replace($tok, $ara, '$1'), replace($tok, '^\d+', ''))"/>
      </xsl:when>
    </xsl:choose>
  </xsl:function>

  <!-- Éligibilité d'un nœud texte : français moderne, hors apparat, hors exposant déjà fait. -->
  <xsl:function name="ord:eligible" as="xs:boolean">
    <xsl:param name="n" as="text()"/>
    <xsl:sequence select="
      matches($n, '[IVXLCDM0-9]') and
      not($n/ancestor::tei:div[@type = 'transcription']) and
      (empty($n/ancestor::*[@xml:lang][1]/@xml:lang) or starts-with($n/ancestor::*[@xml:lang][1]/@xml:lang, 'fr')) and
      not($n/ancestor::tei:app or $n/ancestor::tei:listApp or $n/ancestor::tei:rdg or
          $n/ancestor::tei:lem or $n/ancestor::tei:rdgGrp or $n/ancestor::tei:witDetail) and
      not($n/ancestor::*[local-name() = 'sup' or (local-name() = 'hi' and @rend = 'sup')])"/>
  </xsl:function>

  <!-- Traitement normal du corpus (next-match), puis exposant des ordinaux sur le résultat. -->
  <xsl:template match="text()[ord:eligible(.)]" priority="40">
    <xsl:variable name="r"><xsl:next-match/></xsl:variable>
    <xsl:apply-templates select="$r" mode="ord:post"/>
  </xsl:template>

  <xsl:template match="*" mode="ord:post">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="ord:post"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="comment() | processing-instruction()" mode="ord:post">
    <xsl:copy/>
  </xsl:template>

  <!-- Fonction réutilisable : une chaîne -> nœuds (texte + <sup>). À appeler dans les endroits où le texte
       est produit par xsl:value-of ou un attribut (hors modèles text()) : <xsl:sequence select="ord:html(string(.))"/> -->
  <xsl:function name="ord:html" as="node()*">
    <xsl:param name="s" as="xs:string?"/>
    <xsl:variable name="frag">
      <xsl:analyze-string select="string($s)" regex="{$ord:tok}">
        <xsl:matching-substring>
          <xsl:variable name="p" select="ord:split(.)"/>
          <xsl:choose>
            <xsl:when test="exists($p)">
              <xsl:value-of select="$p[1]"/><sup><xsl:value-of select="$p[2]"/></sup>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
          </xsl:choose>
        </xsl:matching-substring>
        <xsl:non-matching-substring>
          <xsl:value-of select="."/>
        </xsl:non-matching-substring>
      </xsl:analyze-string>
    </xsl:variable>
    <xsl:sequence select="$frag/node()"/>
  </xsl:function>

  <xsl:template match="text()" mode="ord:post">
    <xsl:choose>
      <xsl:when test="ancestor::*[local-name() = 'sup'] or ancestor::*[local-name() = 'hi'][@rend = 'sup']">
        <xsl:value-of select="."/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="ord:html(string(.))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
