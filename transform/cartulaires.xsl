<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.1" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:dts="https://w3id.org/dts/api#"
  exclude-result-prefixes="tei dts"
>
  <xsl:import href="../hteiml/xsl/tei2html.xsl"/>
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

 <!-- 2026-09-11 (autopilote, B8b 5) : cibles de <ref> que DoTS-vue ne sait pas ouvrir telles quelles (anciens noms
      de cartulaire « hotelpontoise_… », « smchamps_…_A » (témoin → acte), zéros « _0434 » → « _434 », renvois « voir »
      sans @corresp valable → unité de l'index + ancre, NON_TROUVE et cibles absentes → texte sans lien).
      Table générée depuis les TEI et la navigation DTS : dots-autopilot/scripts/cartulaires_refs_sidecar.py
      → cartulaires-refs.xml (relancer le script si les TEI changent, puis toucher ce fichier). Sauvegarde *.bak_b8b5_20260911. -->
 <xsl:variable name="cartulaires-refs" select="document('cartulaires-refs.xml')/cibles"/>
 <xsl:key name="cartulaires-ref" match="c" use="@t"/>

 <xsl:template match="tei:ref[@target]">
   <xsl:variable name="corrige" select="key('cartulaires-ref', string(@target), $cartulaires-refs)[1]"/>
   <xsl:choose>
     <xsl:when test="$corrige and normalize-space($corrige/@href) = ''">
       <span class="ref-sans-cible"><xsl:apply-templates/>&#x200c;</span>
     </xsl:when>
     <xsl:when test="$corrige">
       <a href="{$corrige/@href}">
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

</xsl:transform>
