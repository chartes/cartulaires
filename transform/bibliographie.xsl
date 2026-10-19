<?xml version="1.0" encoding="UTF-8"?>
<!--
  Module générique (2026-10-15) des bibliographies, allure de la page « Références »
  des chroniques latines : une rubrique repliable par listBibl titré (« Titre (N) »),
  une ligne par référence, entière, l'année en gris à droite.
  Import APRÈS hteiml : les règles du corpus gardent la priorité. Le mode « biblio-texte »
  rend le contenu d'une référence ; un corpus le surcharge (sigle de Montferrand, liens des
  chroniques).
-->
<xsl:transform version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:bib="urn:elec:bibliographie"
  exclude-result-prefixes="tei xs bib">


  <xsl:template match="tei:listBibl">
    <xsl:choose>
      <xsl:when test="tei:head">
        <details class="biblio" open="open">
          <xsl:if test="@xml:id"><xsl:attribute name="id" select="@xml:id"/></xsl:if>
          <summary>
            <!-- Titre de rubrique en vrai intertitre (h2, h3 pour une liste dans une liste) :
                 tailles et espacements de hteiml, comme les intertitres des autres pages. -->
            <xsl:element name="h{min((6, count(ancestor::tei:listBibl) + 2))}">
              <xsl:attribute name="class">head biblio-rubrique</xsl:attribute>
              <xsl:apply-templates select="tei:head[1]/node()"/>
              <xsl:text> </xsl:text>
              <span class="biblio-compte">(<xsl:value-of select="count(.//tei:bibl)"/>)</span>
            </xsl:element>
          </summary>
          <xsl:call-template name="biblio-liste"/>
        </details>
      </xsl:when>
      <xsl:otherwise>
        <div class="biblio">
          <xsl:if test="@xml:id"><xsl:attribute name="id" select="@xml:id"/></xsl:if>
          <xsl:call-template name="biblio-liste"/>
        </div>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="biblio-liste">
    <!-- Références en lignes ; une liste imbriquée (« Sources » > « Sources manuscrites »)
         devient une rubrique dans la rubrique, à sa place ; le reste (p, note…) par hteiml. -->
    <xsl:for-each-group select="* except tei:head[1]" group-adjacent="boolean(self::tei:bibl)">
      <xsl:choose>
        <xsl:when test="current-grouping-key()">
          <ul class="listBibl biblio-liste">
            <xsl:for-each select="current-group()">
              <li class="bibl">
                <xsl:if test="@xml:id"><xsl:attribute name="id" select="@xml:id"/></xsl:if>
                <span class="bibl-texte"><xsl:apply-templates select="." mode="biblio-texte"/></span>
                <xsl:variable name="annee" select="bib:annee(.)"/>
                <xsl:if test="$annee">
                  <span class="bibl-annee"><xsl:value-of select="$annee"/></span>
                </xsl:if>
              </li>
            </xsl:for-each>
          </ul>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="current-group()"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>

  <xsl:template match="tei:bibl" mode="biblio-texte">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- Année : la dernière année (ou intervalle) du texte hors titres, hors cotes et hors parenthèses ;
       à défaut, la dernière entre parenthèses (« t. 87 (2001) »). -->
  <xsl:function name="bib:annee" as="xs:string?">
    <xsl:param name="b" as="element()"/>
    <xsl:variable name="texte" select="string-join($b//text()[not(ancestor::tei:title | ancestor::tei:idno | ancestor::tei:msIdentifier)][not(ancestor::tei:hi[@rend = ('i', 'italic')])], '')"/>
    <xsl:variable name="motif" select="'(^|[^0-9])((1[0-9]{3}|20[0-9]{2})(\s*[-–]\s*(1[0-9]{3}|20[0-9]{2}))?)($|[^0-9])'"/>
    <xsl:variable name="hors" select="replace($texte, '\([^()]*\)', ' ')"/>
    <xsl:variable name="a" select="(analyze-string($hors, $motif)//*:group[@nr = 2])[last()]"/>
    <xsl:variable name="b2" select="(analyze-string($texte, $motif)//*:group[@nr = 2])[last()]"/>
    <xsl:sequence select="(normalize-space(replace(string(($a, $b2)[1]), '\s*[-–]\s*', '-'))[. != ''])"/>
  </xsl:function>

</xsl:transform>
