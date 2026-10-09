<?xml version="1.0" encoding="UTF-8"?>
<!-- 2026-10-08 : PAGE DE GARDE GENERIQUE (modele Montferrand, dev : montferrand-comptes).
     Module commun, inclus par la feuille de chaque corpus (xsl:include href="../commun/garde.xsl",
     meme preseance que la feuille principale : la priorite de ce modele doit dominer les modeles
     qu'il remplace).

     S'applique UNIQUEMENT au document entier, c'est-a-dire a un TEI qui porte son teiHeader (racine
     en excludeFragments=false) ou a un dts:wrapper qui porte un teiHeader. Une page de fragment
     (un acte, une partie) est servie dans un dts:wrapper SANS teiHeader : elle n'est pas touchee.

     Le modele REMPLACE le contenu de la racine (teiHeader brut, corps entier) par la seule
     presentation : titre, « Édité par », date. Rien d'autre : la table des matieres est celle de
     DoTS-vue (sommaire), pas celle de la page.

     Regles :
       - titre        : titleStmt/title sans @type (sinon le premier title)
       - « Édité par » : titleStmt/editor, sinon titleStmt/author
       - date         : date de la source imprimee (sourceDesc, premier bibl), sinon publicationStmt/date
     Les classes (titlestmt, editors, editor, date) sont stylees par la CSS du corpus, section GARDE. -->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:dts="https://w3id.org/dts/api#"
  exclude-result-prefixes="tei dts">

  <xsl:template match="tei:TEI[tei:teiHeader] | *[local-name() = 'wrapper'][tei:teiHeader]" priority="30" version="3.0">
    <xsl:variable name="fd" select="tei:teiHeader/tei:fileDesc"/>
    <xsl:variable name="titre" select="normalize-space(string-join(($fd/tei:titleStmt/tei:title[not(@type)], $fd/tei:titleStmt/tei:title)[1]//text()[not(ancestor::tei:note)], ''))"/>
    <!-- « Édité par », dans l'ordre (2026-10-08) : editor ; sinon les noms du respStmt « Édition critique… »
         (Delescluze) ; sinon author (l'éditeur du livre : cartulaires, Poitou) ; sinon principal (Chroniques : P. Bourgain ; Christofle : K. Fianu). -->
    <xsl:variable name="ts" select="$fd/tei:titleStmt"/>
    <xsl:variable name="critique" select="$ts/tei:respStmt[matches(normalize-space(tei:resp[1]), '^[ÉE]dition critique', 'i')]"/>
    <xsl:variable name="editeurs" select="if ($ts/tei:editor) then $ts/tei:editor
        else if ($critique) then (if ($critique//(tei:persName | tei:name)) then $critique//(tei:persName | tei:name) else $critique/tei:resp[1]/following-sibling::node()[normalize-space()][1])
        else if ($ts/tei:author) then $ts/tei:author
        else $ts/tei:principal"/>
    <div class="titlestmt">
      <h1 class="head"><xsl:value-of select="$titre"/></h1>
      <xsl:if test="exists($editeurs)">
        <p class="editors">
          <span class="editors-label">Édité par </span>
          <xsl:for-each select="$editeurs">
            <xsl:if test="position() &gt; 1"><xsl:text>, </xsl:text></xsl:if>
            <!-- le nom seul : persName/name s'il y en a (principal porte aussi rôle et affiliation) -->
            <xsl:variable name="nom" select="(.//(tei:persName | tei:name)[1], .)[1]"/>
            <span class="editor"><xsl:value-of select="replace(normalize-space(string-join($nom//text()[not(ancestor::tei:note or ancestor::tei:roleName or ancestor::tei:affiliation or ancestor::tei:orgName)], ' ')), '\s*\([^)]*\)?', '')"/></span>
          </xsl:for-each>
        </p>
      </xsl:if>
      <xsl:variable name="date" select="normalize-space(($fd/tei:sourceDesc//tei:bibl[1]//tei:date, $fd/tei:publicationStmt/tei:date)[normalize-space()][1])"/>
      <!-- l'année ou l'intervalle d'années seulement (« mai 2015-.... » donne « 2015 ») -->
      <xsl:variable name="annees" select="replace($date, '^.*?(\d{4}(\s*[-–]\s*\d{4})?).*$', '$1')"/>
      <xsl:if test="$date"><span class="date"><xsl:value-of select="if (matches($date, '\d{4}')) then $annees else $date"/></span></xsl:if>
    </div>
  </xsl:template>

</xsl:stylesheet>
