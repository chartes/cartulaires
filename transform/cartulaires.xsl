<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.1" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:dts="https://w3id.org/dts/api#"
  exclude-result-prefixes="tei dts"
>
  <xsl:import href="../hteiml/xsl/tei2html.xsl"/>
  <!-- 2026-09-21 : identifiant de la ressource servie. dots/webapp/restxq/routes.xqm l. 273 le
       passe deja a la feuille : xslt:transform($result, doc($style),
       map {"static_path": $G:static_path, "resource": $resource}). Sans declaration, XSLT
       l'ignore silencieusement. Il sert a fabriquer les liens du tableau des actes vers la page
       de chaque acte (voir cartulaires-acte-href). -->
  <xsl:param name="resource" select="''"/>
  <xsl:output indent="no"/><!-- autopilote 2026-09-11 : sinon DoTS-vue colle les mots (condense) -->
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
  <!-- 2026-09-11 (autopilote, B8b 8) : fragment sans tei:text (index, parties) servi dans un dts:wrapper : hteiml traverse
       le wrapper sans appeler « footnotes » (seul son modèle tei:text le fait) → appels #noteN sans note (ex. NDPA-EG-04
       r427440 : 21 appels ; les renvois « Vide … » de l'index y sont). Bloc de notes de hteiml rétabli, sans le
       classement par page (tei:pb masqués ici : leurs repères « p. N » seraient des ancres mortes).
       Sauvegarde *.bak_b8b8_20260911. -->
  <!-- Pas de second bloc si le rendu en contient déjà un (ex. NDCH-EG r109063). Dans ce bloc, hteiml donne à la note l'id
       de l'appel (note1 ↔ appel href="#note1" id="note1_") mais un retour vers un autre id (#p3229_fn1) : le retour est
       réécrit en #<id de la note>_ (id de l'appel chez hteiml). -->
  <xsl:template match="*[local-name() = 'wrapper'][not(.//tei:text)]" priority="20">
    <xsl:variable name="rendu">
      <xsl:apply-imports/>
    </xsl:variable>
    <xsl:copy-of select="$rendu"/>
    <xsl:if test="not($rendu//*[@class = 'footnotes'])">
      <xsl:variable name="notes-cont" select="."/>
      <xsl:variable name="notes">
        <xsl:for-each select="/">
          <xsl:call-template name="footnotes">
            <xsl:with-param name="cont" select="$notes-cont"/>
            <xsl:with-param name="pb" select="/.."/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:variable>
      <xsl:apply-templates select="$notes/node()" mode="cartu-notes"/>
    </xsl:if>
  </xsl:template>
  <xsl:template match="*" mode="cartu-notes">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="cartu-notes"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="*[local-name() = 'a'][@class = 'noteback'][ancestor::*[@id][contains(@class, 'note')]]" mode="cartu-notes">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="href" select="concat('#', ancestor::*[@id][contains(@class, 'note')][1]/@id, '_')"/>
      <xsl:apply-templates mode="cartu-notes"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="text() | comment()" mode="cartu-notes">
    <xsl:copy/>
  </xsl:template>
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

 <!-- 2026-09-24 : le side-car cartulaires-refs.xml est RETIRÉ (variable $cartulaires-refs, clé
      cartulaires-ref et les deux branches qui les consommaient). Motifs, relevés sur data/ au
      commit 103b46b :
      — sur ses 1 521 entrées, 1 061 pointaient vers des identifiants BaseX volatils (refId=rXXXXXX)
        qui n'existent plus : elles fabriquaient 1 521 liens morts ;
      — 435 entrées (anciens noms « hotelpontoise_… », zéros « _0434 » → « _434 ») étaient devenues
        sans objet : plus aucun <ref> de data/ ne porte ces @target, les sources ayant été corrigées ;
      — placées avant le gabarit @type='see', ces branches masquaient 1 525 renvois qui portent
        désormais un @corresp correct dans les sources ;
      — ses 26 entrées à href vide ne servaient qu'à rendre 100 renvois en texte brut. Ces renvois
        redeviennent des liens morts : c'est assumé, ce sont des défauts qui doivent rester visibles. -->

 <xsl:template match="tei:ref[@target]">
   <xsl:choose>
     <!-- 2026-09-21 : URL ABSOLUE. Sans cette branche, un <ref target="http(s)://..."> tombait
          dans le <xsl:otherwise> ci-dessous, ou substring-after(@target,'#') rend une chaine
          vide : la feuille fabriquait le lien interne mort « /cartulaires/document/?refId= ».
          Releve du 2026-09-21 sur data/ : 566 <ref> a URL absolue (459 http, 107 https), AUCUN
          ne porte @type, et AUCUN n'a d'entree dans cartulaires-refs.xml — le side-car ne les
          rattrapait donc pas. Parmi eux, les liens « Carte de situation » vers la couche
          Cassini de cartes.gouv.fr, ajoutes dans 13 cartulaires.
          Depuis le retrait du side-car (2026-09-24) cette branche est la premiere du choose ;
          elle reste AVANT @type='see' (aucun ref a URL absolue n'est de ce type : cas intact). -->
     <xsl:when test="starts-with(@target, 'http://') or starts-with(@target, 'https://')">
       <a href="{@target}" target="_blank" rel="noopener noreferrer">
         <xsl:apply-templates/>
       </a>
     </xsl:when>
     <xsl:when test="@type = 'see'">
       <xsl:variable name="target" select="./@target"/>
       <xsl:variable name="idDoc"  select="translate(substring-before($target, '_'), '#', '')"/>
       <xsl:variable name="refId" select="translate(./@corresp, '#', '')"/>
       <xsl:variable name="url" select="concat('/cartulaires/document/', $idDoc, '?refId=', $refId, $target)"/>
      
       <a href="{$url}">
        <xsl:apply-templates/>
    </a>
   </xsl:when>
     <xsl:otherwise>
       <xsl:variable name="idActe" select="substring-after(@target, '#')"/>
    <xsl:variable name="idDoc"  select="substring-before($idActe, '_')"/>
    <xsl:variable name="url" select="concat('/cartulaires/document/', $idDoc, '?refId=', $idActe)"/>
    <a href="{$url}">
        <xsl:apply-templates/>
    </a>
     </xsl:otherwise>
   </xsl:choose>
</xsl:template>


  <!--
    Cas propre aux Cartulaires : une note dont @n contient exactement
    une lettre minuscule (a, b, c...) est traitee comme un element
    d'apparat critique. On reutilise les templates generiques afin de
    ne pas surcharger le rendu des autres notes.
  -->
  <xsl:template
    match="tei:note[string-length(normalize-space(@n)) = 1 and contains('abcdefghijklmnopqrstuvwxyz', normalize-space(@n))]"
    priority="20">
    <xsl:call-template name="noteref"/>
  </xsl:template>

  <xsl:template
    match="tei:note[string-length(normalize-space(@n)) = 1 and contains('abcdefghijklmnopqrstuvwxyz', normalize-space(@n))]"
    mode="fn"
    priority="20">
    <xsl:call-template name="note-inline"/>
  </xsl:template>

  <!-- D5-DEBUT (autopilote 2026-09-12) : liens vers les anciens sites ELEC -->
  <!-- hteiml fait un lien de tout tei:idno commencant par « http » (tei2html.xsl l. 1805),
       du tei:title voisin d'un idno[@type='URI'] (l. 1796) et de tei:ref/@target (l. 1456).
       Les anciens sites ELEC ferment : le TEXTE affiche est conserve mot pour mot (c'est
       l'identifiant de la publication d'origine), seule la cible devient la route locale.
       Table et bloc produits par dots-autopilot/scripts/d5_legacy_links_fix.py. -->
  <!-- portail ELEC -->
  <xsl:template match="tei:title[../tei:idno[@type = 'URI'][normalize-space(.) = 'http://elec.enc.sorbonne.fr' or normalize-space(.) = 'http://elec.enc.sorbonne.fr/']]" priority="14">
    <a class="title d5-local" href="/"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/Maintenon/']" priority="14">
    <a class="idno d5-local" href="/cartulaires/document/NDMA-AB"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/Morienval/']" priority="14">
    <a class="idno d5-local" href="/cartulaires/document/NDMV-AB"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/NDPA-EG-01']" priority="14">
    <a class="idno d5-local" href="/cartulaires/document/NDPA-EG-01"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/NDPA-EG-02']" priority="14">
    <a class="idno d5-local" href="/cartulaires/document/NDPA-EG-02"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/NDPA-EG-03']" priority="14">
    <a class="idno d5-local" href="/cartulaires/document/NDPA-EG-03"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/NDPA-EG-04']" priority="14">
    <a class="idno d5-local" href="/cartulaires/document/NDPA-EG-04"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/Orleans-S-Croix/']" priority="14">
    <a class="idno d5-local" href="/cartulaires/document/SCOR-EG"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/Paris-S-Merri/']" priority="14">
    <a class="idno d5-local" href="/cartulaires/document/SMPA-EG"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/SAPC-AB']" priority="14">
    <a class="idno d5-local" href="/cartulaires/document/SAPC-AB"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/SGDP/']" priority="14">
    <a class="idno d5-local" href="/cartulaires/document/SGDP-AB"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/SMMI-AB']" priority="14">
    <a class="idno d5-local" href="/cartulaires/document/SMMI-AB"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/SMPA-AB-02']" priority="14">
    <a class="idno d5-local" href="/cartulaires/document/SMPA-AB-02"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/SMPA-AB-03']" priority="14">
    <a class="idno d5-local" href="/cartulaires/document/SMPA-AB-03"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/VNDP-AB']" priority="14">
    <a class="idno d5-local" href="/cartulaires/document/VNDP-AB"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/hotelpontoise/']" priority="14">
    <a class="idno d5-local" href="/cartulaires/document/HDPO-HD"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/laroche/']" priority="14">
    <a class="idno d5-local" href="/cartulaires/document/NDRC-AB"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/mtmartre/']" priority="14">
    <a class="idno d5-local" href="/cartulaires/document/NDMT-AB"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/pontoise/']" priority="14">
    <a class="idno d5-local" href="/cartulaires/document/SMPO-AB"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/porrois/']" priority="14">
    <a class="idno d5-local" href="/cartulaires/document/NDPR-AB"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/sgelaye/']" priority="14">
    <a class="idno d5-local" href="/cartulaires/document/SGLY-PR"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/smchamps/']" priority="14">
    <a class="idno d5-local" href="/cartulaires/document/SMCP-PR"><xsl:apply-templates/></a>
  </xsl:template>
  <!-- adresse commune a 4 TEI (SCHA-PR, SGGO-PR, SLES-PR, STEP-AB) -->
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/smerry/']" priority="14">
    <a class="idno d5-local" href="/cartulaires"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/sspire/']" priority="14">
    <a class="idno d5-local" href="/cartulaires/document/SSCO-AB"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/vauxcernay/']" priority="14">
    <a class="idno d5-local" href="/cartulaires/document/NDVC-AB"><xsl:apply-templates/></a>
  </xsl:template>
  <!-- D5-FIN -->

  <!-- ==== C2-TEMOINS-DEBUT (2026-09-12) : images des témoins et des folios (NDCH) ====
       Repris de la version complète de l'utilisateur (630 lignes, 2026-09-01 :
       `Downloads\chroniques_latines\elec-historical-comparison\poitou-mine\hteiml\Nouveau dossier\
        _backup_avant_revert_20260824_113337\BaseX__transform__cartulaires__cartulaires.xsl`).
       Cette feuille-ci appartient à une autre lignée : elle porte les blocs D5 (liens des anciens
       sites) et le traitement des notes de B8b, que la version longue n'a pas — d'où un PORTAGE
       des seuls templates de témoins, et non un remplacement de fichier.
       Ce que cela rétablit : le contrat HTML attendu par le front (branche `maquette2` de
       dots-vue) — `a.pb.facs` avec `data-source` (image Nakala) et `data-manifest` (manifeste
       IIIF), lus par `use-mirador.js` et `PageBreak.vue` pour ouvrir Mirador sur le bon folio,
       et par `DocumentPage.vue` pour le bandeau « ce folio édite l'acte N ».
       Données déjà en place : 144 `<witness>` avec `@facs` Nakala et `@corresp` = manifeste,
       870 `@facs` Gallica sur les `pb`, 141 manifestes locaux.
       NB : la règle `<xsl:template match="tei:pb"/>` plus haut (« ne pas sortir les pages »)
       devient inatteignable, les deux templates ci-dessous étant en priorité 10 et couvrant
       les deux cas (`pb` avec et sans `@facs`). Elle est laissée en place, intacte.
       Sauvegarde avant portage : cartulaires.xsl.bak_c2temoins_20260912. -->

  <xsl:template name="cartulaires-pb-label">
    <xsl:variable name="norm" select="normalize-space(@n)"/>
    <xsl:choose>
      <xsl:when test="starts-with(@ed, 'frantext')"/>
      <xsl:when test="$norm = ''"/>
      <xsl:when test="contains('[({', substring($norm, 1,1))">
        <xsl:value-of select="$norm"/>
      </xsl:when>
      <xsl:when test="@ana">[<xsl:value-of select="@ana"/>]</xsl:when>
      <xsl:when test="@ed">[<xsl:value-of select="@n"/>]</xsl:when>
      <xsl:when test="@n != '' and contains('0123456789IVXDCM', substring(@n,1,1))">{p.&#160;<xsl:value-of select="@n"/>}</xsl:when>
      <xsl:otherwise>[<xsl:value-of select="@n"/>]</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="cartulaires-image-source">
    <xsl:param name="source"/>
    <xsl:param name="image"/>
    <xsl:variable name="afterIiif" select="substring-after($image, '/iiif/')"/>
    <xsl:variable name="afterDoi" select="substring-after($afterIiif, '/')"/>
    <xsl:variable name="afterNakalaId" select="substring-after($afterDoi, '/')"/>
    <xsl:variable name="imageHash" select="substring-before($afterNakalaId, '/')"/>
    <xsl:choose>
      <xsl:when test="$source != '' and contains($source, '#')"><xsl:value-of select="$source"/></xsl:when>
      <xsl:when test="$source != '' and (starts-with($source, 'http://api.nakala.fr/iiif/') or starts-with($source, 'https://api.nakala.fr/iiif/'))"><xsl:value-of select="$source"/></xsl:when>
      <xsl:when test="$source != '' and $imageHash != ''"><xsl:value-of select="$source"/>#<xsl:value-of select="$imageHash"/></xsl:when>
      <xsl:when test="$source != ''"><xsl:value-of select="$source"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$image"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="cartulaires-manifest-url">
    <xsl:param name="witness" select="."/>
    <xsl:choose>
      <xsl:when test="$witness/@corresp"><xsl:value-of select="$witness/@corresp"/></xsl:when>
      <xsl:when test="contains($witness/@source, '/manifests/')"><xsl:value-of select="$witness/@source"/></xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tei:pb[@facs]" priority="10">
    <xsl:variable name="id">
      <xsl:call-template name="id"/>
    </xsl:variable>
    <xsl:variable name="witnessManifest">
      <xsl:call-template name="cartulaires-manifest-url">
        <xsl:with-param name="witness" select="ancestor::tei:text[1]/tei:front//tei:witness[@corresp or contains(@source, '/manifests/')][1]"/>
      </xsl:call-template>
    </xsl:variable>
    <a class="pb facs">
      <xsl:if test="$id != ''">
        <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
      </xsl:if>
      <xsl:attribute name="href"><xsl:value-of select="@facs"/></xsl:attribute>
      <xsl:if test="@source or @facs">
        <xsl:attribute name="data-source">
          <xsl:call-template name="cartulaires-image-source">
            <xsl:with-param name="source" select="@source"/>
            <xsl:with-param name="image" select="@facs"/>
          </xsl:call-template>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@corresp or contains(@source, '/manifests/') or $witnessManifest != ''">
        <xsl:attribute name="data-manifest">
          <xsl:choose>
            <xsl:when test="@corresp"><xsl:value-of select="@corresp"/></xsl:when>
            <xsl:when test="contains(@source, '/manifests/')"><xsl:value-of select="@source"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="$witnessManifest"/></xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </xsl:if>
      <xsl:call-template name="cartulaires-pb-label"/>
    </a>
  </xsl:template>

  <xsl:template match="tei:pb[not(@facs)]" priority="10">
    <xsl:variable name="firstPbId" select="generate-id(ancestor::tei:text[1]//tei:pb[1])"/>
    <xsl:variable name="graphicUrl" select="ancestor::tei:text[1]/tei:body//tei:graphic[@url][1]/@url"/>
    <xsl:variable name="graphicSource" select="ancestor::tei:text[1]/tei:body//tei:graphic[@source][1]/@source"/>
    <xsl:variable name="witnessFacs" select="ancestor::tei:text[1]/tei:front//tei:witness[@facs][1]/@facs"/>
    <xsl:variable name="witnessSource" select="ancestor::tei:text[1]/tei:front//tei:witness[@source][1]/@source"/>
    <xsl:variable name="witnessManifest">
      <xsl:call-template name="cartulaires-manifest-url">
        <xsl:with-param name="witness" select="ancestor::tei:text[1]/tei:front//tei:witness[@corresp or contains(@source, '/manifests/')][1]"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="firstWitnessFacs" select="substring-before(concat(normalize-space($witnessFacs), ' '), ' ')"/>
    <xsl:variable name="image">
      <xsl:choose>
        <xsl:when test="$graphicUrl != ''"><xsl:value-of select="$graphicUrl"/></xsl:when>
        <xsl:when test="starts-with($firstWitnessFacs, 'http')"><xsl:value-of select="$firstWitnessFacs"/></xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="source">
      <xsl:choose>
        <xsl:when test="$graphicSource != ''"><xsl:value-of select="$graphicSource"/></xsl:when>
        <xsl:otherwise><xsl:value-of select="$witnessSource"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="generate-id(.) = $firstPbId and $image != ''">
        <xsl:variable name="id">
          <xsl:call-template name="id"/>
        </xsl:variable>
        <xsl:variable name="mixed" select="../text()[normalize-space(.) != '']"/>
        <xsl:if test="$mixed != ''">
          <xsl:text> </xsl:text>
        </xsl:if>
        <a class="pb facs">
          <xsl:if test="$id != ''">
            <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
          </xsl:if>
          <xsl:attribute name="href"><xsl:value-of select="$image"/></xsl:attribute>
          <xsl:attribute name="data-source">
            <xsl:call-template name="cartulaires-image-source">
              <xsl:with-param name="source" select="$source"/>
              <xsl:with-param name="image" select="$image"/>
            </xsl:call-template>
          </xsl:attribute>
          <xsl:if test="$witnessManifest != ''">
            <xsl:attribute name="data-manifest"><xsl:value-of select="$witnessManifest"/></xsl:attribute>
          </xsl:if>
          <xsl:call-template name="cartulaires-pb-label"/>
        </a>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <!-- Masque le marqueur {p. N} quand le pb est le tout premier élément d'un acte :
               on évite l'enchaînement « n° d'acte » puis « n° de page » en tête. -->
          <xsl:when test="parent::tei:text[@xml:id] and not(preceding-sibling::*)"/>
          <xsl:otherwise>
            <xsl:call-template name="pb"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tei:div[@type='transcription']/tei:figure[count(*) = 1 and tei:graphic[@source and @url and (contains(@source, 'nakala.fr') or contains(@url, 'nakala.fr'))]]" priority="20">
    <xsl:variable name="previousGraphic" select="preceding-sibling::tei:figure[tei:graphic[@source and @url and (contains(@source, 'nakala.fr') or contains(@url, 'nakala.fr'))]]"/>
    <xsl:if test="not($previousGraphic) and not(ancestor::tei:text[1]//tei:pb)">
      <a class="pb facs" id="pbmanuscrit">
        <xsl:attribute name="href"><xsl:value-of select="tei:graphic[1]/@url"/></xsl:attribute>
        <xsl:attribute name="data-source">
          <xsl:call-template name="cartulaires-image-source">
            <xsl:with-param name="source" select="tei:graphic[1]/@source"/>
            <xsl:with-param name="image" select="tei:graphic[1]/@url"/>
          </xsl:call-template>
        </xsl:attribute>
      </a>
    </xsl:if>
  </xsl:template>

  <!-- Image du manuscrit témoin : même contrat HTML que les <pb facs>. -->
  <xsl:template match="tei:witness[@facs]" priority="10">
    <xsl:variable name="firstFacs" select="substring-before(concat(normalize-space(@facs), ' '), ' ')"/>
    <xsl:variable name="manifestUrl">
      <xsl:call-template name="cartulaires-manifest-url"/>
    </xsl:variable>
    <li>
      <xsl:call-template name="atts"/>
      <xsl:if test="@n">
        <small class="n">
          <xsl:call-template name="cartulaires-siglum"/>
        </small>
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:apply-templates/>
      <xsl:text> </xsl:text>
      <a class="pb facs witness-facs-link" title="Voir le cartulaire" aria-label="Voir le cartulaire">
        <xsl:attribute name="href"><xsl:value-of select="$firstFacs"/></xsl:attribute>
        <xsl:if test="@source or $firstFacs != ''">
          <xsl:attribute name="data-source">
            <xsl:call-template name="cartulaires-image-source">
              <xsl:with-param name="source" select="@source"/>
              <xsl:with-param name="image" select="$firstFacs"/>
            </xsl:call-template>
          </xsl:attribute>
        </xsl:if>
        <xsl:if test="$manifestUrl != ''">
          <xsl:attribute name="data-manifest"><xsl:value-of select="$manifestUrl"/></xsl:attribute>
        </xsl:if>
        <span class="sr-only">Voir le cartulaire</span>
      </a>
    </li>
  </xsl:template>

  <!-- ==== C2-TEMOINS-FIN ==== -->

  <!-- 2026-09-14 — DU TEXTE DISPARAISSAIT DANS LES NOMS.
       La feuille commune `hteiml/xsl/teiHeader2html.xsl` l. 463 déclare
       `<xsl:template match="*[tei:surname]">` : un modèle écrit pour le teiHeader, mais SANS
       mode, donc actif aussi dans le corps du texte, où il l'emporte sur le modèle de nom de
       `tei2html.xsl`. Il boucle sur `select="*"` : il ne garde que les ÉLÉMENTS enfants et
       jette tous les nœuds de texte propres à l'élément.
       Mesuré sur ce corpus le 2026-09-14 (`scripts/d38_persname_texte_perdu.py`) :
       **7 éléments, 10 mots perdus** — des parenthèses de références bibliographiques,
       « Berman (Constance H.) » sortant « Berman Constance H. ». C'est peu, mais c'est du
       texte d'édition qui s'efface sans que rien ne le signale.
       Décision de l'utilisateur : corriger corpus par corpus plutôt que dans la feuille
       commune, que 23 corpus importent et dont deux copies servent. -->
  <xsl:template priority="8"
      match="tei:persName[tei:surname] | tei:name[tei:surname]
           | tei:placeName[tei:surname] | tei:orgName[tei:surname]">
    <span class="{local-name()}"><xsl:apply-templates/></span>
  </xsl:template>

  <!-- ==== V5-PRESENTATION (2026-09-18) : demandes d'Olivier Canteaut sur la presentation
       des actes et la tradition. Sauvegarde : cartulaires.xsl.bak_v5presentation_20260918.

       1. « il faudrait remettre le numero de l'acte sur la 1re ligne, centre ; la date est a
          centrer juste en-dessous ». Le numero est porte par <text @n> (ex. SMPA-EG_0001 n="I"),
          mais le cartouche d'entete de hteiml (tei2html.xsl l. 376) ne le sortait pas : le code
          qui l'aurait fait y est en commentaire. On redonne ici le meme cartouche, precede d'un
          <div class="docNum">. Le centrage et les blancs sont dans cartulaires.customCss.css.

       2. « les noms des temoins (A, B, a...) sont a faire suivre d'un point dans le tableau de
          la tradition ; il manque aussi parfois un espace entre la lettre et la reference ».
          hteiml (l. 1685) sort <small class="n">B</small> puis une espace. On ajoute le point
          (sauf si @n se termine deja par un point) et on garde l'espace, ici et dans le modele
          tei:witness[@facs] du bloc C2-TEMOINS ci-dessus.
  -->

  <!-- Sigle d'un temoin, suivi d'un point (« B. », « a. »). -->
  <xsl:template name="cartulaires-siglum">
    <xsl:variable name="n" select="normalize-space(@n)"/>
    <xsl:value-of select="$n"/>
    <xsl:if test="substring($n, string-length($n)) != '.'">
      <xsl:text>.</xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- Cartouche d'entete d'acte : numero d'acte en 1re ligne, puis le reste comme chez hteiml. -->
  <xsl:template match="tei:group/tei:text/tei:front | dts:wrapper/tei:text/tei:front" priority="12">
    <xsl:variable name="el">
      <xsl:choose>
        <xsl:when test="$format = 'html5'">header</xsl:when>
        <xsl:otherwise>div</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$el}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:call-template name="atts"/>
      <xsl:if test="normalize-space(../@n) != ''">
        <div class="docNum">
          <xsl:value-of select="normalize-space(../@n)"/>
        </div>
      </xsl:if>
      <xsl:apply-templates/>
      <!-- mention « D'apres <temoin edite> », comme chez hteiml -->
      <xsl:apply-templates select=".//tei:witness[@ana='edited']" mode="according"/>
    </xsl:element>
  </xsl:template>

  <!-- Temoins sans image : meme sortie que hteiml, sigle suivi d'un point. -->
  <xsl:template match="tei:listWit/tei:witness[not(@facs)]" priority="11">
    <li>
      <xsl:call-template name="atts"/>
      <xsl:if test="@n">
        <small class="n">
          <xsl:call-template name="cartulaires-siglum"/>
        </small>
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="@xml:id and not(tei:label)">
        <i>
          <xsl:call-template name="witid"/>
        </i>
        <xsl:text> </xsl:text>
      </xsl:if>
      <!-- 2026-09-18 — LE MANUSCRIT NUMÉRISÉ DU TÉMOIN.
           Demande d'Olivier Canteaut : « Quant au manuscrit, il faudrait l'appeler quand on
           cite le témoin B. (cartulaire avec la cote lat. 10996). » L'identifiant est posé en
           `@source` sur 100 `<witness>` de La Roche — emplacement prévu par le schéma du
           corpus et déjà employé par Notre-Dame de Chartres — mais aucune feuille ne le
           lisait : le texte s'affichait, l'identifiant restait lettre morte.
           Le lien est posé ICI et non dans un modèle à part : ce modèle-ci est en priorité 11
           et l'emporterait de toute façon. On écarte les `@source` de manifeste IIIF, que le
           bloc C2-TEMOINS exploite autrement. `hteiml`, que 27 corpus importent, n'est pas
           touché. -->
      <xsl:choose>
        <xsl:when test="@source and not(contains(@source, '/manifests/'))">
          <a class="witness-source-link" target="_blank" rel="noopener"
             title="Voir le document numérisé">
            <xsl:attribute name="href"><xsl:value-of select="normalize-space(@source)"/></xsl:attribute>
            <xsl:apply-templates/>
          </a>
        </xsl:when>
        <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
      </xsl:choose>
    </li>
  </xsl:template>
  <!-- Titres de parties (demande d'Olivier Canteaut)
       « pour l'heure, on a des titres disparates. Pour Saint-Merry, on a "cartulaire", je
       preciserais "Cartulaire de Saint-Merry de Paris". Pour la Roche, [...] "Pieces
       justificatives", que je remplacerais par un long titre. »

       ATTENTION : le libelle affiche dans le SOMMAIRE ne vient pas d'ici mais du registre de
       fragments de BaseX (cartulaires > dots/fragments_register.xml, element dct:title), rempli
       a l'ingestion depuis le <head> du TEI. Les deux regles ci-dessous ne corrigent donc que le
       titre affiche DANS LA PAGE. La correction definitive, qui aligne page et sommaire, est de
       changer le <head> du TEI puis de reconstruire le registre ; ces deux regles deviendront
       alors sans effet d'elles-memes (elles ne filtrent plus).

       Le mot « Cartulaire » seul sert de tete de partie dans 12 cartulaires : on discrimine
       Saint-Merry par la tete du groupe parent. « Pieces Justificatives » n'existe que dans
       NDRC-AB (groupe r670999). -->
  <xsl:template priority="15"
      match="tei:group/tei:head[normalize-space(.) = 'Cartulaire'][../../tei:head[normalize-space(.) = 'Saint-Merry de Paris']]/text()">
    <xsl:text>Cartulaire de Saint-Merry de Paris</xsl:text>
  </xsl:template>
  <xsl:template priority="15"
      match="tei:group[@xml:id = 'r670999']/tei:head/text()">
    <xsl:text>Pièces justificatives à l'histoire de l'abbaye de la Roche et de la famille de Lévis</xsl:text>
  </xsl:template>

  <!-- ==== V5-PRESENTATION-FIN ==== -->


  <!-- ==== W1-TABLEAU-DEBUT (2026-09-21) : LISTE DES ACTES EN TABLEAU TRIABLE ==========

       Demande d'Olivier Canteaut : « la presentation de la liste des actes, avec numero (en
       romain) et dates est un peu indigeste. Peut-on tenter soit de remplacer les parentheses
       par une virgule [...] ou mieux, peut-on essayer de faire 2 colonnes, une avec le n°,
       l'autre avec la date ? On pourrait meme imaginer de trier, ce qui serait super ! »

       CE QUI EST FAIT ICI : un tableau a deux colonnes (n° | date) place en tete de chaque
       <group> d'actes, TRIABLE par numero et par date, dans les deux sens, SANS <script>.

       CE QUI N'EST PAS FAIT, ET POURQUOI : l'etiquette « I (13 avril-31 juillet 1175) » du
       sommaire de gauche ne vient PAS d'ici. Elle est stockee dans le registre de fragments de
       BaseX (dots:fragment/dct:title), rempli a l'ingestion. Remplacer sa parenthese par une
       virgule demande une reingestion : ce n'est pas du ressort d'une feuille XSL.

       MECANISME DU TRI, SANS SCRIPT (repris de l'index du manuscrit de Bellelay,
       bellelay.xsl l. 349 et suivantes + bellelay.customCss.css l. 905 et suivantes) :
       DoTS-vue compile le fragment comme un gabarit Vue et n'execute aucun <script>, mais il
       laisse passer intacts les <input type="radio">, les <label> et les attributs. Bellelay
       s'en sert pour paginer ; on s'en sert ici pour TRIER :
         1. quatre boutons radio (n° croissant / decroissant, date croissante / decroissante),
            caches, chacun enferme dans son <label> — cliquer le label coche la radio, sans
            script et sans avoir a apparier des id ;
         2. chaque ligne porte DEUX rangs precalcules par cette feuille, en proprietes
            personnalisees CSS (donc prefixees de deux tirets) : ord-n (rang dans l'ordre des
            numeros) et ord-d (rang dans
            l'ordre des dates) ;
         3. le <tbody> est une boite flex en colonne, et la feuille de style choisit, selon la
            radio cochee, `order: var(ord-n)` ou `order: calc(0 - var(ord-d))`, etc.
            Mesure du 2026-09-21 dans le navigateur de ce poste (Chrome 153) :
            `order: var(x)` et `order: calc(0 - var(x))` fonctionnent, `:has()` aussi.
       Quatre regles CSS suffisent donc pour n'importe quel nombre d'actes — contrairement a la
       pagination de Bellelay, qui demande une regle par page.

       OU CE TABLEAU APPARAIT, ET POURQUOI PAS AILLEURS (mesure du 2026-09-21) :
       DoTS-vue demande les pages de PARTIE avec `excludeFragments=true`
       (dots-vue/src/components/Document.vue l. 279-283, parce que le citeType « part » des
       groupes n'est pas dans editByCiteType de cartulaires.conf.json). Le module
       repo/resolver/utils.xqm (fonction utils:excludeFragments, l. 603) retire alors du XML
       TOUS les enfants qui sont eux-memes des fragments enregistres — c'est-a-dire tous les
       <text> d'actes — AVANT d'appeler cette feuille, et il ne sert meme pas l'element <group>
       (seulement ses enfants restants). Sur la page d'une partie, la feuille ne recoit donc
       qu'un <head> : ni acte, ni date, ni identifiant de groupe. Le tableau ne peut pas y etre
       engendre. Il l'est sur la PAGE DE LA RESSOURCE (ex. /cartulaires/document/NDRC-AB), la
       seule ou DoTS-vue demande le document entier (Document.vue l. 264-266) et ou la feuille
       voit donc les <group> avec leurs <text>.

       CLE DE TRI DES DATES : @when, sinon @notBefore, sinon @notAfter, dans cet ordre de
       preference (et non par ordre d'apparition des attributs). Releve du 2026-09-21 sur les
       39 ressources servies : @when dans la majorite des cas, @notBefore/@notAfter pour les
       dates approchees (177 des 194 actes de Montmartre), aucun attribut pour 119 des 176
       textes de Saint-Merry. Les actes sans aucune date machine sont rejetes en fin de tri
       chronologique (premiere cle de tri), au lieu d'etre melanges aux plus anciens.
       Tout est en XSLT 1.0 : cette feuille est declaree version="1.1".
  -->

  <!-- Libelle affiche dans la colonne « Date » : le contenu du premier <date> du <docDate>,
       notes de bas de page exclues (elles y sont frequentes : SMPA-EG_0001, NDRC-AB_0001...). -->
  <xsl:template name="cartulaires-date-libelle">
    <xsl:variable name="lib">
      <xsl:choose>
        <xsl:when test="tei:front/tei:docDate/tei:date[1]">
          <xsl:for-each select="tei:front/tei:docDate/tei:date[1]/node()[not(self::tei:note)]">
            <xsl:value-of select="."/>
          </xsl:for-each>
        </xsl:when>
        <xsl:when test="tei:front/tei:docDate">
          <xsl:for-each select="tei:front/tei:docDate/node()[not(self::tei:note)]">
            <xsl:value-of select="."/>
          </xsl:for-each>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="normalize-space($lib) != ''">
        <xsl:value-of select="normalize-space($lib)"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- jamais d'element vide : la sortie est serialisee en HTML, un <td/> serait lu comme
             une balise ouvrante (meme piege que les <span/> de Bellelay). -->
        <xsl:text>[sans date]</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Lien d'une ligne du tableau vers l'acte. Sur la page du groupe (ou les actes ne sont pas
       rendus, voir plus bas) une ancre « #id » ne menerait nulle part : on sort donc la route de
       l'acte des que $resource est connu, et on retombe sur l'ancre interne sinon. -->
  <xsl:template name="cartulaires-acte-href">
    <!-- 2026-09-21 : quand le texte des actes est rendu sur la meme page que le
         tableau, la ligne doit y conduire par une ancre et non ouvrir la page de
         l'acte : sinon on quitte la partie qu'on est en train de lire. -->
    <xsl:param name="meme-page" select="false()"/>
    <xsl:choose>
      <xsl:when test="$meme-page and @xml:id">
        <xsl:value-of select="concat('#', @xml:id)"/>
      </xsl:when>
      <xsl:when test="normalize-space($resource) != ''">
        <xsl:value-of select="concat('/cartulaires/document/', $resource, '?refId=', @xml:id)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('#', @xml:id)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Le tableau lui-meme. Appele avec le <group> pour noeud courant. -->
  <xsl:template name="cartulaires-table-actes">
    <xsl:param name="meme-page" select="false()"/>
    <xsl:variable name="gid" select="generate-id()"/>
    <section class="cartu-actes" id="cartu-actes-{$gid}">
      <h2 class="cartu-actes-titre">
        <xsl:text>Liste des actes </xsl:text>
        <span class="cartu-actes-nb">
          <xsl:text>(</xsl:text><xsl:value-of select="count(tei:text)"/><xsl:text>)</xsl:text>
        </span>
      </h2>
      <table class="cartu-actes-table">
        <thead>
          <tr class="cartu-actes-entete">
            <th class="cartu-c-num" scope="col">
              <span class="cartu-th-nom">N<sup>o</sup></span>
              <span class="cartu-tri">
                <label class="cartu-tri-b cartu-tri-asc" title="Trier par numero, du premier au dernier">
                  <input type="radio" class="cartu-tri-radio" name="cartu-tri-{$gid}" value="num-asc" checked="checked"/>
                  <span class="cartu-fleche">&#x25B2;</span>
                </label>
                <label class="cartu-tri-b cartu-tri-desc" title="Trier par numero, du dernier au premier">
                  <input type="radio" class="cartu-tri-radio" name="cartu-tri-{$gid}" value="num-desc"/>
                  <span class="cartu-fleche">&#x25BC;</span>
                </label>
              </span>
            </th>
            <th class="cartu-c-date" scope="col">
              <span class="cartu-th-nom">Date</span>
              <span class="cartu-tri">
                <label class="cartu-tri-b cartu-tri-asc" title="Trier par date, de la plus ancienne a la plus recente">
                  <input type="radio" class="cartu-tri-radio" name="cartu-tri-{$gid}" value="date-asc"/>
                  <span class="cartu-fleche">&#x25B2;</span>
                </label>
                <label class="cartu-tri-b cartu-tri-desc" title="Trier par date, de la plus recente a la plus ancienne">
                  <input type="radio" class="cartu-tri-radio" name="cartu-tri-{$gid}" value="date-desc"/>
                  <span class="cartu-fleche">&#x25BC;</span>
                </label>
              </span>
            </th>
          </tr>
        </thead>
        <tbody>
          <!-- Les lignes sont emises dans l'ordre CHRONOLOGIQUE : position() y donne
               directement ord-d. Le rang par numero (ord-n) se lit, lui, sur l'arbre
               source : count(preceding-sibling::tei:text) — pas besoin d'une seconde passe
               triee, impossible a garder en XSLT 1.0. L'ordre affiche par defaut reste celui
               des numeros (regle CSS `order: var(ord-n)`). -->
          <xsl:for-each select="tei:text">
            <xsl:sort data-type="number" order="ascending"
                      select="number(not(tei:front/tei:docDate/tei:date[1]/@when) and not(tei:front/tei:docDate/tei:date[1]/@notBefore) and not(tei:front/tei:docDate/tei:date[1]/@notAfter))"/>
            <xsl:sort data-type="text" order="ascending"
                      select="substring(concat(substring(tei:front/tei:docDate/tei:date[1]/@when, 1, 10), substring(tei:front/tei:docDate/tei:date[1]/@notBefore, 1, 10 * number(not(tei:front/tei:docDate/tei:date[1]/@when))), substring(tei:front/tei:docDate/tei:date[1]/@notAfter, 1, 10 * number(not(tei:front/tei:docDate/tei:date[1]/@when) and not(tei:front/tei:docDate/tei:date[1]/@notBefore))), '----------'), 1, 10)"/>
            <tr class="cartu-acte">
              <xsl:attribute name="style">
                <xsl:text>--ord-n:</xsl:text>
                <xsl:value-of select="count(preceding-sibling::tei:text) + 1"/>
                <xsl:text>;--ord-d:</xsl:text>
                <xsl:value-of select="position()"/>
              </xsl:attribute>
              <td class="cartu-c-num">
                <xsl:choose>
                  <xsl:when test="@xml:id">
                    <a class="cartu-acte-lien">
                      <xsl:attribute name="href"><xsl:call-template name="cartulaires-acte-href"><xsl:with-param name="meme-page" select="$meme-page"/></xsl:call-template></xsl:attribute>
                      <xsl:choose>
                        <xsl:when test="normalize-space(@n) != ''"><xsl:value-of select="normalize-space(@n)"/></xsl:when>
                        <xsl:otherwise><xsl:text>&#x2014;</xsl:text></xsl:otherwise>
                      </xsl:choose>
                    </a>
                  </xsl:when>
                  <xsl:when test="normalize-space(@n) != ''"><xsl:value-of select="normalize-space(@n)"/></xsl:when>
                  <xsl:otherwise><xsl:text>&#x2014;</xsl:text></xsl:otherwise>
                </xsl:choose>
              </td>
              <td class="cartu-c-date">
                <xsl:choose>
                  <xsl:when test="@xml:id">
                    <a class="cartu-acte-lien">
                      <xsl:attribute name="href"><xsl:call-template name="cartulaires-acte-href"><xsl:with-param name="meme-page" select="$meme-page"/></xsl:call-template></xsl:attribute>
                      <xsl:call-template name="cartulaires-date-libelle"/>
                    </a>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:call-template name="cartulaires-date-libelle"/>
                  </xsl:otherwise>
                </xsl:choose>
              </td>
            </tr>
          </xsl:for-each>
        </tbody>
      </table>
    </section>
  </xsl:template>

  <!-- Accroche 1 : groupe d'actes AVEC titre — le tableau se place juste apres le <h1> du
       groupe, sans toucher au modele de groupe de hteiml (apply-imports). -->
  <xsl:template match="tei:group[tei:text][tei:head]/tei:head" priority="16">
    <xsl:apply-imports/>
    <xsl:for-each select="..">
      <xsl:call-template name="cartulaires-table-actes"/>
    </xsl:for-each>
  </xsl:template>

  <!-- Accroche 2 : groupe d'actes SANS titre — le tableau ouvre le groupe. -->
  <xsl:template match="tei:group[tei:text][not(tei:head)]" priority="16">
    <xsl:call-template name="cartulaires-table-actes"/>
    <xsl:apply-imports/>
  </xsl:template>

  <!-- Accroche 3 : LA PAGE DU GROUPE ELLE-MEME (priorite la plus haute).
       Quand DoTS-vue demande l'unite d'un groupe, l'API sert <TEI><dts:wrapper><group>...
       — le groupe est alors fils DIRECT du wrapper, ce qui n'arrive ni dans le document entier
       (il y est sous <text><body>) ni sur la page d'un acte (le wrapper y porte un <text>).
       On y rend les titres et les tableaux, et RIEN d'autre.

       Pourquoi : sans cela la feuille engendrait la page entiere, soit 52,1 Mo pour
       Saint-Martin de Pontoise et 16,6 Mo pour le Magnum pastorale de Notre-Dame de Paris
       (mesures du 2026-09-21) — la page ne s'affichait plus. Ce sont les octets ENGENDRES par
       la feuille : ne pas les produire ramene la page a quelques dizaines de kilo-octets.
       Les actes restent lisibles un a un, par leur propre page, ou le tableau conduit.

       Le test porte sur .//tei:text et NON sur tei:text : dans la moitie du corpus les actes ne
       sont pas les enfants directs du groupe demande mais d'un sous-groupe (Notre-Dame de Paris
       t. 1 a 3, Saint-Maur-des-Fosses t. 2 — jusqu'a TROIS niveaux de <group> imbriques,
       releve du 2026-09-21). D'ou le modele recursif ci-dessous, qui descend jusqu'au niveau
       qui porte reellement les <text> et y pose un tableau. « wrapper » est teste par
       local-name(), comme ailleurs dans cette feuille. -->
  <xsl:template match="tei:group[parent::*[local-name() = 'wrapper']][.//tei:text]" priority="20">
    <div class="cartu-groupe-seul">
      <xsl:call-template name="cartulaires-groupe-resume"/>
    </div>
  </xsl:template>

  <!-- Un groupe : son titre, son argument s'il en a un (les sommaires imprimes de
       Saint-Maur-des-Fosses), son tableau s'il porte des actes, puis ses sous-groupes. -->
  <xsl:template name="cartulaires-groupe-resume">
    <xsl:param name="niveau" select="1"/>
    <div class="group">
      <xsl:if test="@xml:id">
        <xsl:attribute name="id"><xsl:value-of select="@xml:id"/></xsl:attribute>
      </xsl:if>
      <xsl:if test="tei:head">
        <xsl:choose>
          <xsl:when test="$niveau &lt;= 1">
            <h1 class="head"><xsl:apply-templates select="tei:head/node()"/></h1>
          </xsl:when>
          <xsl:when test="$niveau = 2">
            <h2 class="head"><xsl:apply-templates select="tei:head/node()"/></h2>
          </xsl:when>
          <xsl:otherwise>
            <h3 class="head"><xsl:apply-templates select="tei:head/node()"/></h3>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>
      <xsl:apply-templates select="tei:argument"/>
      <xsl:if test="tei:text">
        <xsl:call-template name="cartulaires-table-actes">
          <xsl:with-param name="meme-page" select="false()"/>
        </xsl:call-template>
      </xsl:if>
      <xsl:for-each select="tei:group[.//tei:text]">
        <xsl:call-template name="cartulaires-groupe-resume">
          <xsl:with-param name="niveau" select="$niveau + 1"/>
        </xsl:call-template>
      </xsl:for-each>
    </div>
  </xsl:template>

  <!-- ==== W1-TABLEAU-FIN ==== -->

</xsl:transform>
