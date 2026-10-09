<?xml version="1.0" encoding="UTF-8"?>
<!--
  Modèle commun des pages « Bibliographie » (2026-10-08).
  Module inclus (xsl:include) par les feuilles des corpus, après leur xsl:import de l'HTEIML.

  Usage : une feuille déclare QUELLE division est sa bibliographie (son propre xsl:template
  match, en priorité 45), puis appelle le modèle commun :

    <xsl:template match="tei:div[@xml:id = 'ma_biblio']" priority="45">
      <xsl:call-template name="biblio-page">
        <xsl:with-param name="div" select="."/>
        (facultatif : regroupement des fonds par dépôt, Delescluze)
        <xsl:with-param name="depots" select="('id1', 'id2')"/>
        <xsl:with-param name="noms" select="('Nom 1', 'Nom 2')"/>
        (facultatif : base des liens des notices portant @corresp)
        <xsl:with-param name="lien-base" select="concat($resourceId, '?refId=', $chronique_refs)"/>
      </xsl:call-template>
    </xsl:template>

  Structure produite :
    section.biblio
      h1.biblio-titre                          (head[1] de la division)
      div.biblio-groupe                         (un par listBibl)
        h2.biblio-rubrique                      (head[1] du listBibl)
        [si depots]  div.biblio-fonds > h4.biblio-depot + p.biblio-notice (cote en span.biblio-cote)
                     h3.biblio-sous-titre (titre-fonds / titre-imprimees)
        p.biblio-notice                         (un par bibl ; retrait suspendu)
          span.author > span.surname / span.forename
          span.biblio-titre-article             (title[@level='a'] : romain entre « »)
          cite.title                            (monographie, revue : italique)

  Les autres éléments de la division (p, etc.) sont rendus par les modèles de la feuille.
  Les classes TEI usuelles (author, surname, forename, title) sont gardées pour le CSS existant.
-->
<xsl:transform version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="tei xs">

  <!-- ==================================================================
       Page : titre, puis un groupe par listBibl
       ================================================================== -->
  <xsl:template name="biblio-page">
    <xsl:param name="div" as="element()" select="."/>
    <xsl:param name="depots" as="xs:string*" select="()"/>
    <xsl:param name="noms" as="xs:string*" select="()"/>
    <xsl:param name="lien-base" as="xs:string" select="''"/>
    <xsl:param name="titre-fonds" as="xs:string" select="'Sources manuscrites'"/>
    <xsl:param name="titre-imprimees" as="xs:string" select="'Sources imprimées'"/>
    <section class="biblio">
      <h1 class="biblio-titre"><xsl:apply-templates select="$div/tei:head[1]/node()"/></h1>
      <xsl:call-template name="biblio-contenu">
        <xsl:with-param name="noeuds" select="$div/node() except $div/tei:head[1]"/>
        <xsl:with-param name="depots" select="$depots"/>
        <xsl:with-param name="noms" select="$noms"/>
        <xsl:with-param name="lien-base" select="$lien-base"/>
        <xsl:with-param name="titre-fonds" select="$titre-fonds"/>
        <xsl:with-param name="titre-imprimees" select="$titre-imprimees"/>
      </xsl:call-template>
    </section>
  </xsl:template>

  <!-- 2026-10-08 : contenu d'une bibliographie, récursif : une sous-division (div) devient une rubrique
       (son head en intertitre h2.biblio-rubrique), traitée de la même façon (cartulaires SAPC-AB : listBibl
       rangées dans des div). Delescluze et chroniques (listBibl directes) : rendu inchangé. -->
  <xsl:template name="biblio-contenu">
    <xsl:param name="noeuds" as="node()*"/>
    <xsl:param name="depots" as="xs:string*" select="()"/>
    <xsl:param name="noms" as="xs:string*" select="()"/>
    <xsl:param name="lien-base" as="xs:string" select="''"/>
    <xsl:param name="titre-fonds" as="xs:string" select="'Sources manuscrites'"/>
    <xsl:param name="titre-imprimees" as="xs:string" select="'Sources imprimées'"/>
      <xsl:for-each select="$noeuds">
        <xsl:choose>
          <xsl:when test="self::tei:div">
            <div class="biblio-groupe">
              <xsl:if test="@xml:id"><xsl:attribute name="id" select="@xml:id"/></xsl:if>
              <xsl:if test="tei:head"><h2 class="biblio-rubrique"><xsl:apply-templates select="tei:head[1]/node()"/></h2></xsl:if>
              <xsl:call-template name="biblio-contenu">
                <xsl:with-param name="noeuds" select="node() except tei:head[1]"/>
                <xsl:with-param name="depots" select="$depots"/>
                <xsl:with-param name="noms" select="$noms"/>
                <xsl:with-param name="lien-base" select="$lien-base"/>
                <xsl:with-param name="titre-fonds" select="$titre-fonds"/>
                <xsl:with-param name="titre-imprimees" select="$titre-imprimees"/>
              </xsl:call-template>
            </div>
          </xsl:when>
          <xsl:when test="self::tei:listBibl">
            <xsl:call-template name="biblio-groupe">
              <xsl:with-param name="liste" select="."/>
              <xsl:with-param name="depots" select="$depots"/>
              <xsl:with-param name="noms" select="$noms"/>
              <xsl:with-param name="lien-base" select="$lien-base"/>
              <xsl:with-param name="titre-fonds" select="$titre-fonds"/>
              <xsl:with-param name="titre-imprimees" select="$titre-imprimees"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="self::comment() or self::processing-instruction() or (self::text() and normalize-space(.) = '')"/>
          <xsl:otherwise>
            <xsl:apply-templates select="."/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
  </xsl:template>

  <!-- ==================================================================
       Un listBibl = une rubrique (intertitre) et ses notices
       ================================================================== -->
  <xsl:template name="biblio-groupe">
    <xsl:param name="liste" as="element()"/>
    <xsl:param name="depots" as="xs:string*" select="()"/>
    <xsl:param name="noms" as="xs:string*" select="()"/>
    <xsl:param name="lien-base" as="xs:string" select="''"/>
    <xsl:param name="titre-fonds" as="xs:string" select="'Sources manuscrites'"/>
    <xsl:param name="titre-imprimees" as="xs:string" select="'Sources imprimées'"/>
    <!-- Fonds d'archives : identifiant de la notice = dépôt suivi d'un numéro -->
    <xsl:variable name="fonds" select="$liste/tei:bibl[replace(@xml:id, '\d+$', '') = $depots]"/>
    <div class="biblio-groupe">
      <xsl:if test="$liste/tei:head">
        <h2 class="biblio-rubrique"><xsl:apply-templates select="$liste/tei:head[1]/node()"/></h2>
      </xsl:if>
      <xsl:if test="$fonds">
        <h3 class="biblio-sous-titre"><xsl:value-of select="$titre-fonds"/></h3>
        <xsl:for-each-group select="$fonds" group-by="replace(@xml:id, '\d+$', '')">
          <div class="biblio-fonds">
            <h4 class="biblio-depot"><xsl:value-of select="$noms[index-of($depots, current-grouping-key())[1]]"/></h4>
            <xsl:for-each select="current-group()">
              <xsl:call-template name="biblio-notice">
                <xsl:with-param name="cote" select="true()"/>
              </xsl:call-template>
            </xsl:for-each>
          </div>
        </xsl:for-each-group>
      </xsl:if>
      <xsl:if test="$liste/tei:bibl except $fonds">
        <xsl:if test="$fonds">
          <h3 class="biblio-sous-titre"><xsl:value-of select="$titre-imprimees"/></h3>
        </xsl:if>
        <xsl:for-each select="$liste/tei:bibl except $fonds">
          <xsl:call-template name="biblio-notice">
            <xsl:with-param name="lien-base" select="$lien-base"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:if>
      <xsl:apply-templates select="$liste/*[not(self::tei:head or self::tei:bibl)]"/>
    </div>
  </xsl:template>

  <!-- ==================================================================
       Une notice (contexte : tei:bibl)
       ================================================================== -->
  <xsl:template name="biblio-notice">
    <xsl:param name="cote" as="xs:boolean" select="false()"/>
    <xsl:param name="lien-base" as="xs:string" select="''"/>
    <xsl:variable name="t" select="normalize-space(.)"/>
    <p class="biblio-notice">
      <xsl:if test="@xml:id">
        <xsl:attribute name="id" select="@xml:id"/>
      </xsl:if>
      <xsl:choose>
        <!-- fonds : « cote : description » ; la cote part en gras -->
        <xsl:when test="$cote and matches($t, '^.+?[\s&#160;]:[\s&#160;]')">
          <span class="biblio-cote"><xsl:value-of select="replace($t, '^(.+?)[\s&#160;]+:[\s&#160;].*$', '$1', 's')"/></span>
          <xsl:text>&#160;: </xsl:text>
          <xsl:value-of select="replace($t, '^.+?[\s&#160;]+:[\s&#160;]+(.*)$', '$1', 's')"/>
        </xsl:when>
        <!-- notice liée à une entrée de la page de références (@corresp = #id) -->
        <xsl:when test="@corresp and $lien-base != ''">
          <a class="biblio-lien bibl" href="{concat($lien-base, @corresp)}">
            <xsl:apply-templates select="node()" mode="biblio"/>
          </a>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="node()" mode="biblio"/>
        </xsl:otherwise>
      </xsl:choose>
    </p>
  </xsl:template>

  <!-- ==================================================================
       Contenu d'une notice (mode biblio). Le reste passe par les modèles ordinaires.
       ================================================================== -->
  <xsl:template match="tei:author | tei:editor" mode="biblio">
    <span class="{local-name()}"><xsl:apply-templates select="node()" mode="biblio"/></span>
  </xsl:template>

  <xsl:template match="tei:surname | tei:forename" mode="biblio">
    <span class="{local-name()}"><xsl:apply-templates select="node()" mode="biblio"/></span>
  </xsl:template>

  <!-- Titre d'article : romain entre guillemets français -->
  <xsl:template match="tei:title[@level = 'a']" mode="biblio">
    <span class="biblio-titre-article">«&#160;<xsl:apply-templates select="node()" mode="biblio"/>&#160;»</span>
  </xsl:template>

  <!-- Ouvrage, revue, collection : italique -->
  <xsl:template match="tei:title" mode="biblio">
    <cite class="title"><xsl:apply-templates select="node()" mode="biblio"/></cite>
  </xsl:template>

  <xsl:template match="node()" mode="biblio" priority="-1">
    <xsl:apply-templates select="."/>
  </xsl:template>

</xsl:transform>
