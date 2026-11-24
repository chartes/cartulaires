<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.1"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tei">
  <!-- ==== 0. DÉCLARATIONS : imports, sortie, paramètres, variables, clés, fonctions ==== -->

  <!-- Saint-Denis : surcharge de hteiml, reconstruite le 13/10/2026 en partant du rendu
       hteiml nu.

       Les actes du Cartulaire blanc reprennent le DOM du site historique (Pleade,
       saint-denis.enc.sorbonne.fr) : h1.tei-doc-title, p.tei-docDate, div.tei-summary,
       div.tei-tradition (p.tei-docs-orig / -cop / -edi, div.indiqué-ig), div.tei-comments,
       div.tei-transcription, de sorte que la CSS de Pleade (theme/css/module-tei.css)
       s'y applique.

       Reprises telles quelles de la feuille précédente (rien n'est retiré) : appels et
       corps des notes, apparat (leçon + appel, note en marge et en pied comme dans
       dots-vue), renvois entre actes, vers l'Inventaire général, vers les pages du site,
       vers le Du Cange, corrections de renvois faux (rueil, ully), images (folios,
       illustrations), notices de l'Inventaire, index des auteurs d'actes, recherche.

       Version 1.1 gardée : plusieurs tests comparent une chaîne à un nombre (mode de
       compatibilité). -->
  <xsl:import href="../../renderers/hteiml/xsl/tei2html.xsl"/>

  <xsl:variable name="elec-base" select="'/elec'"/>

  <xsl:variable name="sd-fichiers" select="$elec-base"/>

  <!-- 2026-10-19 : les sept chapitres du Cartulaire blanc sont servis par le projet cartulaires,
       l'Inventaire général (ISD-vol1-3) et les pages du site par le projet saint-denis. Liens
       relatifs à /elec/<projet>/document/<ressource>, justes depuis l'un et l'autre projet. -->
  <xsl:variable name="sd-vers-chapitres" select="'../../cartulaires/document/'"/>
  <!-- 2026-11-24 : les pages du site (saint-denis-site) sont elles aussi passées dans les cartulaires : le projet
       saint-denis est vide. -->
  <xsl:variable name="sd-vers-sd" select="'../../cartulaires/document/'"/>
  <!-- 2026-11-24 : l'Inventaire général (ISD-vol1-3, avec son introduction, ses images et son index des auteurs)
       quitte le projet saint-denis pour la collection « Chartes médiévales de l'abbaye de Saint-Denis » des
       cartulaires, à côté du Cartulaire blanc. -->
  <xsl:variable name="sd-vers-isd" select="'../../cartulaires/document/'"/>

  <xsl:output indent="no"/>


  <xsl:variable name="sd-images" select="'../../images/saint-denis/'"/>


  <xsl:variable name="sd-chapitres" select="' beaurain dugny pierrefitte rueil saint-martin tremblay ully '"/>

  <xsl:variable name="sd-renvois-corriges" select="' rueil-acte101=rueil-acte44 rueil-acte103=rueil-acte46 rueil-acte108=rueil-acte51 rueil-acte110=rueil-acte53 rueil-acte111=rueil-acte54 rueil-acte112=rueil-acte55 rueil-acte115=rueil-acte58 rueil-acte117=rueil-acte60 rueil-acte120=rueil-acte63 rueil-acte121=rueil-acte64 rueil-acte122=rueil-acte65 rueil-acte123=rueil-acte66 rueil-acte125=rueil-acte68 rueil-acte127=rueil-acte70 rueil-acte71=rueil-acte16a rueil-acte73=rueil-acte17 rueil-acte76=rueil-acte20 rueil-acte77=rueil-acte21 rueil-acte79=rueil-acte23 rueil-acte84=rueil-acte28a rueil-acte85=rueil-acte28b rueil-acte88=rueil-acte31 rueil-acte90=rueil-acte33 rueil-acte94=rueil-acte37 rueil-acte96=rueil-acte39 rueil-acte97=rueil-acte40 rueil-acte98=rueil-acte41 ully-acte140=ully-acte40 '"/>

  <!-- ==== 1. HISTORIQUE : surcharge reprise de la feuille de l'ÉLEC (rendu du texte de l'édition) ==== -->




  <!-- ==== 2. BLOCS HTEIML GÉNÉRIQUES : enveloppe dts:wrapper, notes, apparat critique, bibliographie (listBibl) ==== -->






  <xsl:template match="*[local-name() = 'wrapper']">
    <xsl:apply-templates/>
  </xsl:template>







  <!-- ==== 3. PROPRE AU PROJET ==== -->








  <xsl:template name="id">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:choose>
      <xsl:when test="(self::tei:app or self::tei:div) and not(@xml:id) and ancestor::tei:text[@xml:id]">
        <xsl:value-of select="$prefix"/>
        <xsl:value-of select="ancestor::tei:text[@xml:id][1]/@xml:id"/>
        <xsl:choose>
          <xsl:when test="self::tei:app">
            <xsl:text>-app</xsl:text>
            <xsl:number count="tei:app" level="any" from="tei:text[@xml:id]"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>-div</xsl:text>
            <xsl:number count="tei:div" level="any" from="tei:text[@xml:id]"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="$suffix"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="." mode="id">
          <xsl:with-param name="prefix" select="$prefix"/>
          <xsl:with-param name="suffix" select="$suffix"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>




  <xsl:template match="tei:text/tei:body" priority="12">
    <div class="tei-doc-body"><xsl:apply-templates/></div>
  </xsl:template>



  <xsl:template match="tei:text">
    <xsl:param name="level" select="count(ancestor::tei:group)"/>
    <article>
      <xsl:attribute name="id">
        <xsl:call-template name="id"/>
      </xsl:attribute>
      <xsl:call-template name="atts"/>
      <xsl:apply-templates select="*">
        <xsl:with-param name="level" select="$level +1"/>
      </xsl:apply-templates>
      <xsl:if test="not(tei:group)">
        <xsl:variable name="notes-cont" select="."/>
        <xsl:for-each select="/">
          <xsl:call-template name="footnotes">
            <xsl:with-param name="cont" select="$notes-cont"/>
            <xsl:with-param name="pb" select="()"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:if>
    </article>
  </xsl:template>

  <xsl:template match="tei:div[@type='part']" priority="12">
    <section class="sd-part">
      <xsl:if test="@xml:id">
        <xsl:attribute name="id"><xsl:value-of select="@xml:id"/></xsl:attribute>
      </xsl:if>
      <h1 class="head sd-part-title"><xsl:value-of select="tei:head[1]"/></h1>
      <xsl:apply-templates select="node()[not(self::tei:head[1])]"/>
    </section>
  </xsl:template>

  <xsl:template match="tei:div[@type='subpart']" priority="12">
    <section class="sd-subpart">
      <xsl:if test="@xml:id">
        <xsl:attribute name="id"><xsl:value-of select="@xml:id"/></xsl:attribute>
      </xsl:if>
      <h2 class="head sd-subpart-title"><xsl:value-of select="tei:head[1]"/></h2>
      <xsl:apply-templates select="node()[not(self::tei:head[1])]"/>
    </section>
  </xsl:template>

  <xsl:template match="tei:div[@type='page']" priority="12">
    <article class="sd-static-page">
      <xsl:if test="@xml:id">
        <xsl:attribute name="id"><xsl:value-of select="@xml:id"/></xsl:attribute>
      </xsl:if>
      <xsl:if test="@corresp">
        <xsl:attribute name="data-legacy-source"><xsl:value-of select="@corresp"/></xsl:attribute>
      </xsl:if>
      <!-- titre de la page : déjà dans le sommaire de dots-vue, non répété ici -->
      <xsl:apply-templates select="node()[not(self::tei:head[1])]"/>
    </article>
  </xsl:template>

  <xsl:template match="tei:p[starts-with(@rend,'heading-h2')]" priority="12">
    <xsl:element name="{if (generate-id(.) = generate-id(ancestor::tei:div[@type='page'][1]//tei:p[starts-with(@rend,'heading-h2')][1])) then 'h1' else 'h2'}">
      <xsl:attribute name="class">head sd-legacy-h2</xsl:attribute>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="tei:ab[@type = 'legacy-inline']" priority="12">
    <xsl:apply-templates/>
  </xsl:template>



  <xsl:template match="tei:div[@type = 'notice']" priority="14">
    <article class="isd-notice" id="{@xml:id}" data-pdf="">
      <!-- 2026-11-16 : outils de l'ancien site (comportements : blocs 5 et 6 de elec.customJs.js) : porte-documents,
           PDF de la notice, PDF de la période et de toutes ses notices (« avec ses sous-unités ») -->
      <div class="elec-outils">
        <button type="button" class="elec-panier" data-panier-id="{@xml:id}" data-panier-titre="{normalize-space(tei:head[1])}">Ajouter au porte-documents</button>
        <button type="button" class="elec-pdf" title="Obtenir cette notice en PDF">PDF</button>
        <button type="button" class="elec-pdf" data-pdf-parent="{@xml:id}" title="Obtenir en PDF la période et toutes ses notices">PDF de la période</button>
      </div>
      <h3 class="isd-notice-head"><xsl:apply-templates select="tei:head[1]/node()"/></h3>
      <xsl:apply-templates select="node() except tei:head[1]"/>
      <xsl:call-template name="isd-pied-notes"/>
    </article>
  </xsl:template>

  <!-- 2026-11-16 : renvois de l'Inventaire d'une notice à une autre (ancien site : ead.html?c=ISD-vol1_notice139) -->
  <xsl:template match="tei:ref[contains(@target, 'ead.html?')][contains(@target, 'c=ISD-vol')]" priority="17">
    <!-- ead.html?c=ISD-vol1_notice139 (même tome) ou ead.html?id=ISD-vol1&c=ISD-vol1_notice635 (autre tome) -->
    <xsl:variable name="id" select="substring-before(concat(substring-after(@target, 'c=ISD-vol'), '&amp;'), '&amp;')"/>
    <a class="sd-internal" href="{$sd-vers-isd}ISD-vol{substring-before($id, '_')}?refId=ISD-vol{$id}"><xsl:apply-templates/></a>
  </xsl:template>

  <!-- dates des notices (TEI refait depuis l'EAD) : deux modèles hteiml de même priorité visent tei:date (XTDE0540) -->
  <xsl:template match="tei:div[@type = 'notice']//tei:date" priority="15">
    <span class="date"><xsl:apply-templates/></span>
  </xsl:template>

  <!-- 2026-11-16 : notes de l'Inventaire (TEI refait depuis l'EAD), rendues comme dans les cartulaires : appel en exposant,
       corps au bas de la notice (section.footnotes, mise en forme par les blocs communs « apparat » et « notes » de la CSS) ;
       notes de l'Inventaire manuscrit (lettres, comme sur l'ancien site) dans le bandeau p.apparatus, notes de l'éditeur
       (chiffres) en aside.note. hteiml n'écrit pas le corps des notes d'un fragment, d'où ces modèles. Identifiant d'une
       note : notice + -ms- ou -n- + rang (une même lettre peut revenir dans deux rubriques). -->
  <xsl:template match="tei:div[@type = 'notice']//tei:note[@type = ('inventaire', 'editeur')]" priority="20">
    <xsl:variable name="id"><xsl:call-template name="isd-note-id"/></xsl:variable>
    <a class="noteref{if (@type = 'inventaire') then ' app-ref' else ''}" href="#{$id}" id="{$id}_"><sup><xsl:value-of select="@n"/></sup></a>
  </xsl:template>

  <xsl:template name="isd-note-id">
    <xsl:variable name="notice" select="ancestor::tei:div[@type = 'notice'][1]"/>
    <xsl:variable name="type" select="@type"/>
    <xsl:value-of select="concat($notice/@xml:id, if ($type = 'inventaire') then '-ms-' else '-n-',
                          count(preceding::tei:note[@type = $type][ancestor::tei:div[@type = 'notice'][1] is $notice]) + 1)"/>
  </xsl:template>

  <xsl:template name="isd-pied-notes">
    <xsl:variable name="ms" select=".//tei:note[@type = 'inventaire']"/>
    <xsl:variable name="ed" select=".//tei:note[@type = 'editeur']"/>
    <xsl:if test="$ms or $ed">
      <section class="footnotes">
        <xsl:if test="$ms">
          <p class="apparatus">
            <xsl:for-each select="$ms">
              <xsl:variable name="id"><xsl:call-template name="isd-note-id"/></xsl:variable>
              <span class="note" id="{$id}"><a class="" href="#{$id}_"><xsl:value-of select="@n"/></a><xsl:text> </xsl:text><span class="gloss"><xsl:apply-templates/></span></span>
            </xsl:for-each>
          </p>
        </xsl:if>
        <xsl:for-each select="$ed">
          <xsl:variable name="id"><xsl:call-template name="isd-note-id"/></xsl:variable>
          <aside class="note" id="{$id}"><a class="noteback" href="#{$id}_"><xsl:value-of select="@n"/>. </a><xsl:apply-templates/></aside>
        </xsl:for-each>
      </section>
    </xsl:if>
  </xsl:template>

  <xsl:template match="tei:div[@type = 'section']" priority="14">
    <section class="isd-section" id="{@xml:id}">
      <!-- intitulé de la section : déjà dans le sommaire de dots-vue, non répété ici -->
      <xsl:apply-templates select="node() except tei:head[1]"/>
    </section>
  </xsl:template>

  <xsl:template match="tei:div[@type = 'notice']/tei:label[@type = 'section']" priority="14">
    <xsl:if test="normalize-space(.) != ''">
      <xsl:apply-templates select="tei:pb"/>
      <p class="isd-rubrique">
        <xsl:apply-templates select="node()[local-name() != 'pb']"/>
      </p>
    </xsl:if>
  </xsl:template>

  <xsl:template match="tei:div[@type = 'notice']" mode="a" priority="14">
    <xsl:param name="class"/>
    <a>
      <xsl:attribute name="href"><xsl:call-template name="href"/></xsl:attribute>
      <xsl:if test="$class">
        <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
      </xsl:if>
      <xsl:call-template name="isd-intitule"/>
    </a>
  </xsl:template>

  <xsl:template name="isd-intitule">
    <xsl:for-each select="tei:head[not(@type = 'sub')] | tei:label[@type = 'section'][not(following-sibling::*[1][self::tei:p[starts-with(@rend, 'note-')]])][not(normalize-space(.) = 'Références ajoutées par l’éditeur')]">
      <xsl:choose>
        <xsl:when test="self::tei:head"><xsl:apply-templates select="." mode="title"/></xsl:when>
        <xsl:otherwise><xsl:value-of select="normalize-space(.)"/></xsl:otherwise>
      </xsl:choose>
      <xsl:if test="position() != last()">
        <xsl:variable name="norm" select="normalize-space(.)"/>
        <xsl:variable name="last" select="substring($norm, string-length($norm))"/>
        <xsl:if test="translate($last, '.;:?!»', '') != ''">. </xsl:if>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="tei:list[@type = 'gloss'][ancestor::tei:div[@type = 'notice']]" priority="14">
    <dl class="isd-champs">
      <xsl:for-each select="tei:label">
        <dt><xsl:apply-templates/></dt>
        <dd>
          <xsl:choose>
            <xsl:when test="normalize-space(.) = 'URL de cette page'">
              <xsl:call-template name="isd-permalien">
                <xsl:with-param name="brut" select="normalize-space(following-sibling::tei:item[1])"/>
                <xsl:with-param name="secours" select="following-sibling::tei:item[1]/node()"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="following-sibling::tei:item[1]/node()"/>
            </xsl:otherwise>
          </xsl:choose>
        </dd>
      </xsl:for-each>
    </dl>
  </xsl:template>

  <!-- 2026-11-19 : termes d'une notice (types d'auteur d'acte, types de documents) = lien vers la recherche plein texte
       du terme, entre guillemets (expression exacte), comme les listes de l'ancien site. Lien relatif : depuis
       …/cartulaires/document/ISD-volN (2026-11-24), « ../search » mène à la page de recherche du projet (local et /elec/). -->
  <xsl:template match="tei:term[@type = ('auteur-acte', 'genreform')][normalize-space(.) != ''][ancestor::tei:div[@type = 'notice']]" priority="14">
    <a class="sd-recherche" href="../search?mode=fulltext&amp;q={encode-for-uri(concat('&quot;', normalize-space(.), '&quot;'))}"
       title="Rechercher « {normalize-space(.)} » dans les chartes de Saint-Denis">
      <dfn class="term {@type}"><xsl:apply-templates/></dfn>
    </a>
  </xsl:template>

  <!-- 2026-11-12 (Maxime) : « URL de cette page » = adresse absolue du site public, pas un chemin relatif. -->
  <xsl:variable name="isd-site" select="'https://elec.chartes.psl.eu'"/>

  <xsl:template name="isd-permalien">
    <xsl:param name="brut"/>
    <xsl:param name="secours"/>
    <xsl:variable name="chemin"
                  select="substring-before(concat(substring-after($brut, '/inventaire/'), '&gt;'), '&gt;')"/>
    <xsl:variable name="tome" select="substring-before($chemin, '/')"/>
    <xsl:variable name="unite" select="substring-after($chemin, '/')"/>
    <xsl:variable name="vol" select="concat('ISD-vol', substring-after($tome, 'tome'))"/>
    <xsl:choose>
      <xsl:when test="starts-with($tome, 'tome') and $unite != ''">
        <span class="isd-permalien">
          <xsl:text>&lt;</xsl:text>
          <xsl:value-of select="concat($isd-site, '/cartulaires/document/', $vol, '?refId=', $vol, '_', $unite)"/>
          <xsl:text>&gt;</xsl:text>
        </span>
      </xsl:when>
      <xsl:otherwise><xsl:apply-templates select="$secours"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tei:div[@type = 'section']/tei:p[@rend = 'Numéros des notices']" priority="15"/>
  <!-- 2026-11-16 : la « Note de l'éditeur » d'une période (label puis p[@rend='note-editeur']) est un paragraphe, pas un
       champ : sans cela le modèle suivant affichait « note-editeur : » devant le texte (vu dans le PDF de la période). -->
  <xsl:template match="tei:div[@type = 'section']/tei:p[@rend = ('note-editeur', 'note-inventaire')]" priority="15">
    <p class="p noindent {@rend}"><xsl:apply-templates/></p>
  </xsl:template>

  <xsl:template match="tei:div[@type = 'section']/tei:p[@rend]" priority="14">
    <p class="isd-section-info"><span class="isd-libelle"><xsl:value-of select="@rend"/><xsl:text> : </xsl:text></span>
      <xsl:choose>
        <xsl:when test="@rend = 'URL de cette page'">
          <xsl:call-template name="isd-permalien">
            <xsl:with-param name="brut" select="normalize-space(.)"/>
            <xsl:with-param name="secours" select="node()"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
      </xsl:choose>
    </p>
  </xsl:template>

  <xsl:template match="tei:graphic[starts-with(@url, 'legacy-source/assets/')]" priority="12">
    <img class="sd-graphic" loading="lazy" src="{$sd-images}assets/{substring-after(@url, 'legacy-source/assets/')}" alt="{normalize-space(@n)}"/>
  </xsl:template>

  <xsl:template match="tei:pb[@facs]" priority="20">
    <xsl:variable name="rel" select="substring-after(@facs, 'images/saint-denis/')"/>
    <xsl:variable name="fichier" select="tokenize($rel, '/')[last()]"/>
    <xsl:variable name="serie" select="substring-before($rel, concat('/', $fichier))"/>
    <xsl:variable name="tome" select="substring-after($serie, '/')"/>
    <xsl:variable name="ouvrage">
      <xsl:choose>
        <xsl:when test="starts-with($serie, 'cartulaireblanc/')">Cartulaire blanc</xsl:when>
        <xsl:when test="starts-with($serie, 'inventaire/')">Inventaire général</xsl:when>
        <xsl:otherwise/>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="cote">
      <xsl:choose>
        <xsl:when test="$serie = 'cartulaireblanc/tome1'">LL 1157</xsl:when>
        <xsl:when test="$serie = 'cartulaireblanc/tome2'">LL 1158</xsl:when>
        <xsl:when test="$serie = 'inventaire/tome1'">LL 1189</xsl:when>
        <xsl:when test="$serie = 'inventaire/tome2'">LL 1190</xsl:when>
        <xsl:when test="$serie = 'inventaire/tome3'">LL 1191</xsl:when>
        <xsl:otherwise/>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="libelle">
      <xsl:value-of select="$ouvrage"/>
      <xsl:if test="$tome != ''">
        <xsl:text>, tome </xsl:text>
        <xsl:value-of select="substring-after($tome, 'tome')"/>
      </xsl:if>
      <xsl:if test="$cote != ''">
        <xsl:text> (</xsl:text><xsl:value-of select="$cote"/><xsl:text>)</xsl:text>
      </xsl:if>
      <xsl:if test="normalize-space(@n) != ''">
        <xsl:text>, page </xsl:text>
        <xsl:value-of select="normalize-space(@n)"/>
      </xsl:if>
    </xsl:variable>
    <details class="sd-folio sd-pb">
      <summary>
        <span class="sd-folio-libelle">
          <xsl:value-of select="if (normalize-space($libelle) != '') then $libelle else $fichier"/>
        </span>
      </summary>
      <img class="sd-folio-img" loading="lazy" src="{$sd-images}{$serie}/{$fichier}"
           alt="{if (normalize-space($libelle) != '') then $libelle else $fichier}"/>
    </details>
  </xsl:template>





  <!-- 2026-11-02 : l'index des auteurs d'actes de l'Inventaire est une page à part entière (div
       index sœur de « Édition électronique »), une page par initiale (list[@type='index'] = unité
       citable `section` du refsDecl). Les initiales sont dans le sommaire de dots-vue, pas dans la
       page : la page de l'index porte son chapeau puis les listes de chaque initiale (dots-vue ne charge pas un niveau section
       imbriqué dans une section comme page à part : il le cherche dans la page parente). -->
  <xsl:template match="tei:div[@type = 'index'][starts-with(@xml:id, 'sd-index-auteurs-')]"
                priority="16">
    <section class="sd-index-auteurs" id="{@xml:id}">
      <p class="sd-index-auteurs-chapeau">
        <xsl:value-of select="count(tei:list/tei:item)"/>
        <xsl:text> termes, </xsl:text>
        <xsl:value-of select="count(tei:list/tei:item/tei:ptr)"/>
        <xsl:text> renvois. Index reconstitué depuis le texte encodé, en parité avec l’index publié par le site d’origine.</xsl:text>
      </p>
      <xsl:apply-templates select="tei:list"/>
    </section>
  </xsl:template>

  <xsl:template match="tei:list[@type = 'index'][starts-with(@xml:id, 'sd-index-auteurs-')]"
                priority="16">
    <div class="sd-index-groupe" id="{@xml:id}">
      <h2 class="head sd-index-initiale"><xsl:value-of select="tei:head[1]"/></h2>
      <ul class="sd-index-termes">
        <xsl:for-each select="tei:item">
          <li class="sd-index-terme">
            <details class="sd-index-details">
              <summary class="sd-index-sommaire">
                <span class="sd-index-libelle"><xsl:value-of select="tei:term"/></span>
                <span class="sd-index-nb"><xsl:value-of select="@n"/></span>
              </summary>
              <div class="sd-index-renvois">
                <xsl:for-each select="tei:ptr">
                  <xsl:call-template name="sd-index-renvoi"/>
                </xsl:for-each>
              </div>
            </details>
          </li>
        </xsl:for-each>
      </ul>
    </div>
  </xsl:template>

  <xsl:template match="tei:div[@type = 'index'][starts-with(@xml:id, 'sd-index-auteurs-')]"
                mode="li" priority="16"/>

  <xsl:template match="tei:div[@type = 'page']
                              [@xml:id = 'sd-les-textes--cartulaire-blanc--parcourir'
                               or @xml:id = 'sd-les-textes--inventaire--parcourir']"
                priority="16">
    <article class="sd-static-page sd-page-parcourir" id="{@xml:id}">
      <xsl:if test="@corresp">
        <xsl:attribute name="data-legacy-source"><xsl:value-of select="@corresp"/></xsl:attribute>
      </xsl:if>
      <!-- titre de la page : déjà dans le sommaire de dots-vue, non répété ici -->
      <xsl:apply-templates select="node()[not(self::tei:head[1])]"/>
    </article>
  </xsl:template>

  <!-- ==== 4. MÉCANISMES COMMUNS : tableau filtrable (tf-*), liens vers l'ancien site (D5), liens internes entre fragments ==== -->


  <xsl:template match="tei:ref[contains(@target, 'images/cartulaireblanc/') or contains(@target, 'images/inventaire/')][contains(@target, 'ns=')]" priority="13">
    <xsl:variable name="serie" select="substring-before(substring-after(@target, 'images/'), '/voir.html')"/>
    <xsl:variable name="fichier" select="normalize-space(substring-after(@target, 'ns='))"/>
    <xsl:variable name="libelle" select="if (normalize-space(.) != '') then normalize-space(.) else normalize-space(@n)"/>
    <details class="sd-folio">
      <summary>
        <span class="sd-folio-libelle">
          <xsl:apply-templates/>
          <xsl:if test="not(node())"><xsl:value-of select="$fichier"/></xsl:if>
        </span>
      </summary>
      <img class="sd-folio-img" loading="lazy" src="{$sd-images}{$serie}/{$fichier}"
           alt="{if ($libelle != '') then $libelle else $fichier}"/>
    </details>
  </xsl:template>








  <!-- 24/11 : page de l'Inventaire général (LL 1189-1191) dans la visionneuse des Archives nationales (image exacte) ;
       remplace l'image de l'ancien site (voir.html?ns=inventairejpg_N, même numérisation). Nouvel onglet. -->
  <xsl:template match="tei:ref[@type = 'archives-nationales'][starts-with(@target, 'https://')]" priority="17">
    <a class="lien-archives-nationales" href="{@target}" target="_blank" rel="noopener" title="Voir aux Archives nationales"><xsl:apply-templates/></a>
  </xsl:template>

  <!-- Visionneuse de série de l'ancien site (…/images/inventaire/tomeN/voir.html, …/images/cartulaireblanc/…/voir.html) :
       lien vers l'édition correspondante dans dots-vue (les images s'y déplient depuis les renvois). -->
  <xsl:template match="tei:ref[contains(@target, 'images/inventaire/tome')][contains(@target, '/voir.html')][not(contains(@target, 'ns='))]"
                priority="16">
    <a class="sd-internal sd-site-page"
       href="{$sd-vers-isd}ISD-vol{substring(substring-before(substring-after(@target, 'images/inventaire/tome'), '/voir.html'), 1, 1)}">
      <xsl:apply-templates/>
    </a>
  </xsl:template>

  <xsl:template match="tei:ref[contains(@target, 'enc.sorbonne.fr')][ends-with(lower-case(@target), '.zip')]"
                priority="16">
    <a class="sd-telechargement"
       href="{$sd-fichiers}/images/saint-denis/telechargements/{tokenize(@target, '/')[last()]}"
       target="_blank" rel="noopener">
      <xsl:apply-templates/>
    </a>
  </xsl:template>

  <xsl:template match="tei:ref[contains(@target, 'enc.sorbonne.fr')][contains(@target, 'recherche-avancee.html')]"
                priority="16">
    <a class="sd-recherche-locale" href="../search" title="Recherche dans la collection Saint-Denis.">
      <xsl:apply-templates/>
    </a>
  </xsl:template>

  <xsl:template
      match="tei:ref[starts-with(@target, '#')][contains(@target, '-acte')][not(@type='note')]"
      priority="12">
    <xsl:variable name="id0" select="substring-after(@target, '#')"/>
    <xsl:variable name="id">
      <xsl:choose>
        <xsl:when test="contains($sd-renvois-corriges, concat(' ', $id0, '='))">
          <xsl:value-of select="substring-before(substring-after($sd-renvois-corriges, concat(' ', $id0, '=')), ' ')"/>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="$id0"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="chap" select="substring-before($id, '-acte')"/>
    <xsl:variable name="num" select="substring-after($id, '-acte')"/>
    <xsl:choose>
      <xsl:when test="
        contains($sd-chapitres, concat(' ', $chap, ' '))
        and $num != ''
        and translate(substring($num, 1, 1), '0123456789', '') = ''
        and (
          translate($num, '0123456789', '') = ''
          or (
            string-length(translate($num, '0123456789', '')) = 1
            and translate(
              substring($num, string-length($num)),
              'abcdefghijklmnopqrstuvwxyz',
              ''
            ) = ''
          )
        )
      ">
        <a class="sd-internal" href="{$sd-vers-chapitres}{$chap}?refId={$id}">
          <xsl:apply-templates/>
        </a>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-imports/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>




  <xsl:template match="tei:ref[starts-with(@target, 'http://saint-denis.enc.sorbonne.fr/cartulaire/tome1/')]" priority="11">
    <xsl:variable name="path" select="substring-after(@target, 'http://saint-denis.enc.sorbonne.fr/cartulaire/tome1/')"/>
    <xsl:variable name="chap" select="substring-before(concat($path, '/'), '/')"/>
    <xsl:variable name="rest" select="translate(substring-after($path, '/'), '/', '')"/>
    <xsl:variable name="num" select="substring-after($rest, 'acte')"/>
    <xsl:choose>
      <xsl:when test="contains($sd-chapitres, concat(' ', $chap, ' ')) and $rest = ''">
        <a class="sd-internal" href="{$sd-vers-chapitres}{$chap}"><xsl:apply-templates/></a>
      </xsl:when>
      <xsl:when test="contains($sd-chapitres, concat(' ', $chap, ' ')) and starts-with($rest, 'acte') and $num != '' and translate(substring($num, 1, 1), '0123456789', '') = ''
                      and (translate($num, '0123456789', '') = ''
                           or (string-length(translate($num, '0123456789', '')) = 1
                               and translate(substring($num, string-length($num)), 'abcdefghijklmnopqrstuvwxyz', '') = ''))">
        <a class="sd-internal" href="{$sd-vers-chapitres}{$chap}?refId={$chap}-{$rest}"><xsl:apply-templates/></a>
      </xsl:when>
      <xsl:otherwise><xsl:apply-imports/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://saint-denis.enc.sorbonne.fr/']" priority="14">
    <a class="idno d5-local" href="../../cartulaires/"><xsl:apply-templates/></a>
  </xsl:template>









  <xsl:template match="tei:ref[not(@type = 'note')][starts-with(@target, '#sd-')][not(key('id', substring-after(@target, '#')))]" priority="14">
    <xsl:variable name="id" select="substring-after(@target, '#')"/>
    <!-- 2026-10-19 : les pages consacrées au Cartulaire blanc sont passées dans la ressource
         cartulaire-blanc du projet cartulaires (une page = une partie) : page cible = la page dont
         l'identifiant est le plus long préfixe de la cible. -->
    <!-- 2026-11-12 (plan d'Olivier Canteaut) : ces pages sont réparties en quatre ressources : cartulaire-blanc
         (introduction en tête, présentations, table des chapitres), cartulaire-blanc-actes (liste cumulative, dans
         la sous-collection cartulaire-blanc-edition avec les chapitres), cartulaire-blanc-images (une page par tome),
         cartulaire-blanc-index (recherche, choix d'indexation, index des auteurs). « Parcourir » (Édition électronique)
         n'existe plus : renvoi à la sous-collection. -->
    <xsl:variable name="cb-pages" select="('sd-les-textes--cartulaire-blanc--introduction', 'sd-les-textes--cartulaire-blanc--presentation', 'sd-les-textes--cartulaire-blanc--parcourir', 'sd-les-textes--cartulaire-blanc--parcourir--table-des-chapitres', 'sd-les-textes--cartulaire-blanc--parcourir--table-des-actes', 'sd-recherche-cartulaire', 'sd-le-projet--aspects-scientifiques--auteurs-actes-principales-entrees', 'sd-les-images--images-cb', 'sd-les-images--images-cb--tome1', 'sd-les-images--images-cb--tome2', 'sd-scientifique-cartulaire', 'sd-index-auteurs-cartulaire')"/>
    <xsl:variable name="cb-page" select="if ($id = 'sd-cartulaire-blanc') then $cb-pages[1]
        else if (starts-with($id, 'sd-index-auteurs-cartulaire')) then $cb-pages[12]
        else if (starts-with($id, 'sd-le-projet--aspects-scientifiques--cartulaire-blanc') and $id != 'sd-le-projet--aspects-scientifiques--cartulaire-blanc--etat-d-avancement') then $cb-pages[11]
        else $cb-pages[$id = . or starts-with($id, concat(., '--'))][last()]"/>  <!-- liste rangée du plus court au plus long préfixe -->
    <xsl:variable name="cb-res" select="if ($cb-page = $cb-pages[5]) then 'cartulaire-blanc-actes'
        else if (starts-with($cb-page, 'sd-les-images--images-cb')) then 'cartulaire-blanc-images'
        else if ($cb-page = $cb-pages[position() = (6, 7, 12)]) then 'cartulaire-blanc-index'
        else 'cartulaire-blanc'"/>
    <!-- 2026-11-24 : pages de l'Inventaire général, passées dans les cartulaires (sous-collection inventaire-general) :
         inventaire-introduction (introduction en tête, présentation, édition électronique), inventaire-images,
         inventaire-index (index des auteurs d'actes). Même règle que ci-dessus : page = plus long préfixe de la cible. -->
    <xsl:variable name="ig-pages" select="('sd-les-textes--inventaire--introduction', 'sd-les-textes--inventaire--presentation', 'sd-les-textes--inventaire--parcourir', 'sd-les-images--images-ig', 'sd-index-auteurs-inventaire', 'sd-scientifique-inventaire', 'sd-informatique-inventaire')"/>
    <xsl:variable name="ig-page" select="if ($id = 'sd-inventaire-general') then $ig-pages[1]
        else if (starts-with($id, 'sd-index-auteurs-inventaire')) then $ig-pages[5]
        else if (starts-with($id, 'sd-le-projet--aspects-scientifiques--inventaire')) then $ig-pages[6]
        else if (starts-with($id, 'sd-le-projet--aspects-informatiques--inventaire') and $id != 'sd-le-projet--aspects-informatiques--inventaire--encodage-des-enrichissements-editoriaux') then $ig-pages[7]
        else $ig-pages[$id = . or starts-with($id, concat(., '--'))][last()]"/>
    <xsl:variable name="ig-res" select="if ($ig-page = $ig-pages[4]) then 'inventaire-images'
        else if ($ig-page = $ig-pages[5]) then 'inventaire-index'
        else 'inventaire-introduction'"/>
    <xsl:variable name="rub">
      <xsl:choose>
        <xsl:when test="$id = 'sd-les-images--accueil'
                     or $id = 'sd-le-projet--feuille-de-route'
                     or $id = 'sd-le-projet--mentions-legales'
                     or $id = 'sd-le-projet--aspects-scientifiques--cartulaire-blanc--etat-d-avancement'
                     or $id = 'sd-le-projet--aspects-informatiques--generalites--caracteristiques-de-l-application'
                     or $id = 'sd-le-projet--aspects-informatiques--generalites--format-d-affichage-des-documents'
                     or $id = 'sd-le-projet--aspects-informatiques--cartulaire-blanc-projet-inf'
                     or $id = 'sd-le-projet--aspects-informatiques--inventaire--encodage-des-enrichissements-editoriaux'"/>
        <xsl:when test="$id = 'sd-les-textes--accueil' or starts-with($id, 'sd-les-textes--accueil--')">sd-les-textes--accueil</xsl:when>
        <xsl:when test="$id = 'sd-actes-haut-moyen-age' or starts-with($id, 'sd-les-textes--actes-du-haut-moyen-age')">sd-actes-haut-moyen-age</xsl:when>
        <xsl:when test="$id = 'sd-cartulaire-blanc'
                     or starts-with($id, 'sd-les-textes--cartulaire-blanc')
                     or starts-with($id, 'sd-recherche-cartulaire')
                     or starts-with($id, 'sd-les-images--images-cb')
                     or starts-with($id, 'sd-le-projet--aspects-scientifiques--auteurs-actes-principales-entrees')">sd-cartulaire-blanc</xsl:when>
        <xsl:when test="$id = 'sd-inventaire-general'
                     or starts-with($id, 'sd-les-textes--inventaire')
                     or starts-with($id, 'sd-les-images--images-ig')">sd-inventaire-general</xsl:when>
        <xsl:when test="$id = 'sd-le-projet'
                     or starts-with($id, 'sd-le-projet--')
                     or $id = 'sd-aspects-scientifiques' or $id = 'sd-scientifique-cartulaire' or $id = 'sd-scientifique-inventaire'
                     or $id = 'sd-aspects-informatiques' or $id = 'sd-informatique-generalites' or $id = 'sd-informatique-inventaire'">sd-le-projet</xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$cb-page = $cb-pages[3]">
        <a class="sd-internal sd-site-page" href="../../cartulaire-blanc-edition">
          <xsl:apply-templates/>
        </a>
      </xsl:when>
      <xsl:when test="exists($cb-page)">
        <a class="sd-internal sd-site-page" href="{$sd-vers-chapitres}{$cb-res}?refId={$cb-page}{if ($id != $cb-page) then concat('#', $id) else ''}">
          <xsl:apply-templates/>
        </a>
      </xsl:when>
      <xsl:when test="exists($ig-page)">
        <a class="sd-internal sd-site-page" href="{$sd-vers-chapitres}{$ig-res}?refId={$ig-page}{if ($id != $ig-page) then concat('#', $id) else ''}">
          <xsl:apply-templates/>
        </a>
      </xsl:when>
      <xsl:when test="$rub != '' and $rub != $id">
        <a class="sd-internal sd-site-page" href="{$sd-vers-sd}saint-denis-site?refId={$rub}#{$id}">
          <xsl:apply-templates/>
        </a>
      </xsl:when>
      <xsl:when test="$rub != ''">
        <a class="sd-internal sd-site-page" href="{$sd-vers-sd}saint-denis-site?refId={$rub}">
          <xsl:apply-templates/>
        </a>
      </xsl:when>
      <xsl:otherwise><xsl:apply-imports/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tei:ref[contains(@target, 'saint-denis.enc.sorbonne.fr/inventaire/tome')]" priority="14">
    <xsl:variable name="apres" select="substring-after(@target, '/inventaire/tome')"/>
    <xsl:variable name="tome" select="substring-before($apres, '/')"/>
    <xsl:variable name="notice" select="substring-after($apres, '/')"/>
    <xsl:choose>
      <xsl:when test="$tome != '' and starts-with($notice, 'notice')">
        <a class="sd-inventaire sd-inventaire-url" href="{$sd-vers-isd}ISD-vol{$tome}?refId=ISD-vol{$tome}_{$notice}"><xsl:apply-templates/></a>
      </xsl:when>
      <xsl:when test="$tome != '' and normalize-space($notice) = ''">
        <a class="sd-inventaire sd-inventaire-tome" href="{$sd-vers-isd}ISD-vol{$tome}"><xsl:apply-templates/></a>
      </xsl:when>
      <xsl:otherwise>
        <a class="sd-legacy-inventaire" href="{@target}" target="_blank" rel="noopener"><xsl:apply-templates/></a>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="sd-index-renvoi">
    <xsl:variable name="file" select="substring-before(@target, '.xml')"/>
    <xsl:variable name="frag" select="substring-after(@target, '#')"/>
    <xsl:choose>
      <xsl:when test="starts-with($file, 'ISD-vol')">
        <a class="sd-inventaire sd-index-renvoi"
           href="{$sd-vers-isd}{$file}?refId={$file}_{$frag}">
          <xsl:value-of select="@n"/>
        </a>
      </xsl:when>
      <xsl:otherwise>
        <a class="sd-internal sd-index-renvoi"
           href="{$sd-vers-chapitres}{$file}?refId={$frag}">
          <xsl:value-of select="@n"/>
        </a>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tei:ref[contains(@target, 'enc.sorbonne.fr')]
                              [contains(@target, 'navindex.html')]"
                priority="18">
    <xsl:variable name="cle">
      <xsl:choose>
        <xsl:when test="contains(@target, 'base=ead')">inventaire</xsl:when>
        <xsl:otherwise>cartulaire</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <a class="sd-internal sd-index-ancre"
       href="{if ($cle = 'inventaire') then concat($sd-vers-chapitres, 'inventaire-index?refId=sd-index-auteurs-inventaire') else concat('#sd-index-auteurs-', $cle)}"
       title="Index reconstitué depuis le texte encodé.">
      <xsl:apply-templates/>
    </a>
  </xsl:template>
</xsl:transform>
