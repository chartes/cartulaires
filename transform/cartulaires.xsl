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

  <!--
    Convention propre aux Cartulaires : les notes dont @n est une lettre
    minuscule appartiennent a l'apparat critique ; les autres notes
    identifiees appartiennent aux notes. La generique decide quand appeler
    ce template (tei:text ou dts:wrapper), afin de ne pas doubler la sortie.
  -->
  <xsl:template name="cart-note-num">
    <xsl:choose>
      <xsl:when test="normalize-space(@n) != '' and translate(@n, 'abcdefghijklmnopqrstuvwxyz', '') = ''">
        <xsl:number level="any" format="a"
          from="*[local-name() = 'wrapper']"
          count="tei:note[normalize-space(@n) != '' and translate(@n, 'abcdefghijklmnopqrstuvwxyz', '') = '']"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:number level="any"
          from="*[local-name() = 'wrapper']"
          count="tei:note[(@n or @xml:id) and not(normalize-space(@n) != '' and translate(@n, 'abcdefghijklmnopqrstuvwxyz', '') = '')]"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="cart-note-key">
    <xsl:choose>
      <xsl:when test="@xml:id"><xsl:value-of select="@xml:id"/></xsl:when>
      <xsl:otherwise><xsl:call-template name="cart-note-num"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tei:note" priority="20">
    <xsl:choose>
      <xsl:when test="@place = 'margin'">
        <span class="marginalia"><xsl:apply-templates/></span>
      </xsl:when>
      <xsl:when test="@n or @xml:id">
        <xsl:variable name="key"><xsl:call-template name="cart-note-key"/></xsl:variable>
        <a class="noteref" id="a{$key}" href="#n{$key}"><sup><xsl:call-template name="cart-note-num"/></sup></a>
      </xsl:when>
      <xsl:when test="tei:p or tei:div"><div class="note note-inline"><xsl:apply-templates/></div></xsl:when>
      <xsl:otherwise><span class="note note-inline"><xsl:apply-templates/></span></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="noteback">
    <xsl:param name="class">noteback</xsl:param>
    <xsl:variable name="key"><xsl:call-template name="cart-note-key"/></xsl:variable>
    <a class="{$class}" href="#a{$key}">
      <xsl:call-template name="cart-note-num"/>
      <xsl:if test="$class = 'noteback'"><xsl:text>. </xsl:text></xsl:if>
    </a>
  </xsl:template>

  <xsl:template name="note">
    <xsl:variable name="key"><xsl:call-template name="cart-note-key"/></xsl:variable>
    <aside class="note" id="n{$key}">
      <xsl:call-template name="noteback"/>
      <xsl:apply-templates/>
    </aside>
  </xsl:template>

  <!-- Une note reperee a, b, c... est un apparat continu, comme un tei:app
       dans la feuille generique : pas de rubrique particuliere. -->
  <xsl:template name="cart-apparatus">
    <xsl:variable name="key"><xsl:call-template name="cart-note-key"/></xsl:variable>
    <span class="note" id="n{$key}">
      <a class="note" href="#a{$key}"><xsl:call-template name="cart-note-num"/></a>
      <xsl:text>&#160;</xsl:text>
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <xsl:template name="footnotes">
    <xsl:param name="cont" select="*"/>
    <xsl:variable name="eligible" select="$cont//tei:note[@n or @xml:id][not(@place = 'margin')][not(parent::tei:app)]"/>
    <xsl:variable name="apparatus" select="$eligible[normalize-space(@n) != '' and translate(@n, 'abcdefghijklmnopqrstuvwxyz', '') = '']"/>
    <xsl:variable name="notes" select="$eligible[not(normalize-space(@n) != '' and translate(@n, 'abcdefghijklmnopqrstuvwxyz', '') = '')]"/>
    <xsl:if test="$notes or $apparatus">
      <section class="footnotes">
        <xsl:if test="$apparatus">
          <p class="apparatus">
            <xsl:for-each select="$apparatus"><xsl:call-template name="cart-apparatus"/><xsl:text>. </xsl:text></xsl:for-each>
          </p>
        </xsl:if>
        <xsl:for-each select="$notes"><xsl:call-template name="note"/></xsl:for-each>
      </section>
    </xsl:if>
  </xsl:template>

</xsl:transform>
