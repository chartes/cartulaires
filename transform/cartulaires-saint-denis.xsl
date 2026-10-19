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
  <xsl:variable name="sd-vers-sd" select="'../../saint-denis/document/'"/>

  <xsl:output indent="no"/>

  <xsl:key name="sd-note-by-id" match="tei:note[@xml:id]" use="@xml:id"/>

  <xsl:key name="sd-ref-by-target" match="tei:ref[@type='note'][@target]" use="substring-after(@target, '#')"/>

  <xsl:variable name="sd-images" select="'../../images/saint-denis/'"/>

  <xsl:variable name="sd-chap-motif"
                select="'Beaurain|Dugny|Pierrefitte|Rueil|Saint-Martin|Tremblay|Ully'"/>

  <xsl:variable name="sd-ig-motif"
                select="'Inv\.[\s&#160;]*gén\.[\s&#160;]*(III|II|I)[\s&#160;]*,[\s&#160;]*(p\.[\s&#160;]*\d+(-\d+)?[\s&#160;]*,[\s&#160;]*)?n[\s&#160;]*[°o][\s&#160;]*(\d+)'"/>

  <xsl:variable name="sd-ig-lacunes" select="' 1-76 1-799 2-1579 2-2835 3-3201 '"/>

  <xsl:variable name="sd-chapitres" select="' beaurain dugny pierrefitte rueil saint-martin tremblay ully '"/>

  <xsl:variable name="sd-renvois-corriges" select="' rueil-acte101=rueil-acte44 rueil-acte103=rueil-acte46 rueil-acte108=rueil-acte51 rueil-acte110=rueil-acte53 rueil-acte111=rueil-acte54 rueil-acte112=rueil-acte55 rueil-acte115=rueil-acte58 rueil-acte117=rueil-acte60 rueil-acte120=rueil-acte63 rueil-acte121=rueil-acte64 rueil-acte122=rueil-acte65 rueil-acte123=rueil-acte66 rueil-acte125=rueil-acte68 rueil-acte127=rueil-acte70 rueil-acte71=rueil-acte16a rueil-acte73=rueil-acte17 rueil-acte76=rueil-acte20 rueil-acte77=rueil-acte21 rueil-acte79=rueil-acte23 rueil-acte84=rueil-acte28a rueil-acte85=rueil-acte28b rueil-acte88=rueil-acte31 rueil-acte90=rueil-acte33 rueil-acte94=rueil-acte37 rueil-acte96=rueil-acte39 rueil-acte97=rueil-acte40 rueil-acte98=rueil-acte41 ully-acte140=ully-acte40 '"/>

  <!-- ==== 1. HISTORIQUE : surcharge reprise de la feuille de l'ÉLEC (rendu du texte de l'édition) ==== -->

  <!-- Structure d'un acte, comme Pleade : en-tête (titre, date, analyse), puis tradition,
       commentaire et transcription, séparés par un filet. -->
  <xsl:template match="tei:text/tei:front" priority="12">
    <div class="front"><xsl:apply-templates/></div>
  </xsl:template>

  <!-- Sigle d'un témoin (A, B, a…) : en italique chez Pleade. -->
  <xsl:template match="tei:witness/tei:label" priority="12">
    <span class="tei-label"><xsl:apply-templates/></span>
  </xsl:template>

  <!-- Citations des anciens inventaires et rubriques : entre guillemets, comme Pleade. -->
  <xsl:template match="tei:quote[@type = ('summary', 'rubric')]" priority="12">
    <span class="quote-{@type}">«&#160;<xsl:apply-templates/>&#160;»</span>
  </xsl:template>

  <!-- ==== 2. BLOCS HTEIML GÉNÉRIQUES : enveloppe dts:wrapper, notes, apparat critique, bibliographie (listBibl) ==== -->

  <xsl:template match="tei:app" priority="12">
    <span class="app">
      <xsl:apply-templates select="tei:lem"/>
      <xsl:call-template name="noteref">
        <xsl:with-param name="class">noteref app-ref</xsl:with-param>
      </xsl:call-template>
    </span>
  </xsl:template>

  <xsl:template match="tei:lem">
    <xsl:variable name="prev" select="normalize-space(../preceding-sibling::node()[1])"/>
    <xsl:variable name="prevnode" select="../preceding-sibling::node()[not(self::comment())][1]"/>
    <xsl:if test="translate(substring($prev, string-length($prev)), concat($apos, '’'), '') != ''
                  and not($prevnode/self::text() and matches(string($prevnode), '[\s&#160;]$'))">
      <xsl:text>&#160;</xsl:text>
    </xsl:if>
    <span>
      <xsl:call-template name="atts"/>
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <xsl:template match="tei:lem//tei:choice[tei:sic][tei:corr]" priority="12">
    <em class="sic"><xsl:apply-templates select="tei:sic/node()"/></em>
  </xsl:template>

  <xsl:template match="tei:div[@type='tradition']/tei:listWit[tei:listWit]" priority="12">
    <div class="tei-tradition"><xsl:apply-templates select="tei:listWit"/></div>
  </xsl:template>

  <xsl:template match="tei:div[@type='tradition']/tei:listWit/tei:listWit" priority="12">
    <xsl:variable name="id" select="concat(@xml:id, '#')"/>
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="contains($id, '-originaux#')">orig</xsl:when>
        <xsl:when test="contains($id, '-copies#')">cop</xsl:when>
        <xsl:when test="contains($id, '-editions#')">edi</xsl:when>
        <xsl:when test="contains($id, '-indiqué#')">ind</xsl:when>
        <xsl:otherwise>autre</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="label">
      <xsl:choose>
        <xsl:when test="$type = 'orig'">Originaux</xsl:when>
        <xsl:when test="$type = 'cop'">Copies</xsl:when>
        <xsl:when test="$type = 'edi'">Éditions</xsl:when>
        <xsl:when test="$type = 'ind'">Indiqué</xsl:when>
        <xsl:otherwise><xsl:value-of select="normalize-space(tei:head)"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="witnesses">
      <xsl:for-each select="tei:witness">
        <xsl:if test="position() &gt; 1"><xsl:text> — </xsl:text></xsl:if>
        <span class="witness">
          <xsl:if test="@xml:id"><xsl:attribute name="id"><xsl:value-of select="@xml:id"/></xsl:attribute></xsl:if>
          <xsl:apply-templates/>
        </span>
      </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$type = 'ind' or ($type = 'autre' and tei:head)">
        <div class="indiqué-ig tei-docs-{$type}">
          <xsl:if test="@xml:id"><xsl:attribute name="id"><xsl:value-of select="@xml:id"/></xsl:attribute></xsl:if>
          <p class="listWit-head"><b><xsl:value-of select="$label"/><xsl:text>&#160;:</xsl:text></b></p>
          <p class="tei-witnesses"><xsl:copy-of select="$witnesses"/></p>
        </div>
      </xsl:when>
      <xsl:otherwise>
        <p class="tei-docs-{$type}">
          <xsl:if test="@xml:id"><xsl:attribute name="id"><xsl:value-of select="@xml:id"/></xsl:attribute></xsl:if>
          <xsl:if test="$label != ''">
            <span class="listWit-head"><b><xsl:value-of select="$label"/><xsl:text>&#160;: </xsl:text></b></span>
          </xsl:if>
          <xsl:copy-of select="$witnesses"/>
        </p>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="*[local-name() = 'wrapper']">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="tei:ref[@type='note']">
    <xsl:variable name="noteid" select="substring-after(@target, '#')"/>
    <xsl:variable name="rang" select="count(preceding::tei:ref[@type='note'][@target = current()/@target])"/>
    <a class="noteref" href="#{$noteid}">
      <xsl:attribute name="id">
        <xsl:value-of select="$noteid"/>
        <xsl:text>_</xsl:text>
        <xsl:if test="$rang &gt; 0"><xsl:value-of select="$rang + 1"/></xsl:if>
      </xsl:attribute>
      <sup>
        <xsl:choose>
          <xsl:when test="@n"><xsl:value-of select="@n"/></xsl:when>
          <xsl:otherwise><xsl:call-template name="note-n"/></xsl:otherwise>
        </xsl:choose>
      </sup>
    </a>
  </xsl:template>

  <xsl:template match="tei:note[not(@xml:id) and not(parent::tei:div[@type = 'notes'])]" priority="8">
    <span class="gloss"> [<xsl:apply-templates/>]</span>
  </xsl:template>

  <xsl:template match="tei:note[not(@xml:id)][parent::tei:quote]" mode="fn" priority="9"/>

  <xsl:template match="tei:ref[@type='note'][not(key('sd-note-by-id', substring-after(@target, '#')))]" priority="9">
    <sup class="noteref-orphan">
      <xsl:choose>
        <xsl:when test="@n"><xsl:value-of select="@n"/></xsl:when>
        <xsl:otherwise><xsl:call-template name="note-n"/></xsl:otherwise>
      </xsl:choose>
    </sup>
  </xsl:template>

  <xsl:template match="tei:div[@type = 'notes' or @type = 'footnotes']" priority="30"/>

  <xsl:template match="tei:div[@type = 'notes' or @type = 'footnotes']//tei:note[@xml:id]" mode="fn" priority="20">
    <xsl:param name="resp"/>
    <xsl:if test="($resp = '' and not(@resp))
                  or (@resp and @resp = $resp)
                  or ($resp = '' and @resp and @resp != 'author' and @resp != 'editor')">
      <aside class="note" id="{@xml:id}">
        <xsl:choose>
          <xsl:when test="key('sd-ref-by-target', @xml:id)">
            <a class="noteback" href="#{@xml:id}_">
          <xsl:choose>
            <xsl:when test="key('sd-ref-by-target', @xml:id)[1]/@n">
              <xsl:value-of select="key('sd-ref-by-target', @xml:id)[1]/@n"/>
            </xsl:when>
            <xsl:when test="contains(@xml:id, '-n-')">
              <xsl:value-of select="substring-after(@xml:id, '-n-')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:number count="tei:div[@type = 'notes' or @type = 'footnotes']//tei:note[@xml:id]" level="any" from="/"/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:text>. </xsl:text>
        </a>
          </xsl:when>
          <xsl:otherwise>
            <span class="noteback-orphan">
          <xsl:choose>
            <xsl:when test="key('sd-ref-by-target', @xml:id)[1]/@n">
              <xsl:value-of select="key('sd-ref-by-target', @xml:id)[1]/@n"/>
            </xsl:when>
            <xsl:when test="contains(@xml:id, '-n-')">
              <xsl:value-of select="substring-after(@xml:id, '-n-')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:number count="tei:div[@type = 'notes' or @type = 'footnotes']//tei:note[@xml:id]" level="any" from="/"/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:text>. </xsl:text>
        </span>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates/>
      </aside>
    </xsl:if>
  </xsl:template>

  <!-- ==== 3. PROPRE AU PROJET ==== -->

  <xsl:template match="tei:table[tei:row[1]/tei:cell[last()][normalize-space(.) = ('Nb. actes', 'Édition de la notice dans l’inventaire')]]/tei:row[1]/tei:cell" priority="5">
    <th scope="col">
      <xsl:if test="@cols &gt; 1"><xsl:attribute name="colspan" select="@cols"/></xsl:if>
      <xsl:if test="@rows &gt; 1"><xsl:attribute name="rowspan" select="@rows"/></xsl:if>
      <xsl:apply-templates/>
    </th>
  </xsl:template>

  <xsl:template match="tei:summary" priority="20">
    <div class="summary"><xsl:apply-templates/></div>
  </xsl:template>

  <xsl:template match="tei:msName" priority="20">
    <span class="msName"><xsl:apply-templates/></span>
  </xsl:template>

  <xsl:template match="tei:am" priority="20">
    <span class="am"><xsl:apply-templates/></span>
  </xsl:template>

  <xsl:template match="tei:front/tei:docAuthor" priority="12"/>

  <xsl:template match="tei:front/tei:docDate" priority="12">
    <p class="tei-docDate"><xsl:apply-templates/></p>
    <xsl:variable name="acte" select="string(ancestor::tei:text[@xml:id][1]/@xml:id)"/>
    <xsl:if test="contains($acte, '-acte') and not(following-sibling::tei:docDate)">
      <div class="tei-summary-refurl">
        <span class="refurl-label"><b>URL de cette page : </b></span>
        <span class="sd-permalien">
          <xsl:text>&lt;</xsl:text>
          <xsl:value-of select="concat($elec-base, '/cartulaires/document/', substring-before($acte, '-acte'), '?refId=', $acte)"/>
          <xsl:text>&gt;</xsl:text>
        </span>
      </div>
    </xsl:if>
  </xsl:template>

  <xsl:template match="tei:front/tei:docDate/tei:placeName" priority="12">
    <xsl:text>. — </xsl:text>
    <xsl:apply-imports/>
  </xsl:template>

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

  <xsl:template match="tei:front/tei:titlePart" priority="12">
    <h1 class="tei-doc-title"><xsl:apply-templates/></h1>
  </xsl:template>

  <xsl:template match="tei:front/tei:docDate/tei:date" priority="12">
    <span class="tei-date"><xsl:apply-templates/></span>
  </xsl:template>

  <xsl:template match="tei:front/tei:div[@type = 'summary']" priority="12">
    <div class="tei-summary"><xsl:apply-templates/></div>
  </xsl:template>

  <xsl:template match="tei:text/tei:body" priority="12">
    <div class="tei-doc-body"><xsl:apply-templates/></div>
  </xsl:template>

  <xsl:template match="tei:body/tei:div[@type = ('tradition', 'comments', 'transcription')]" priority="12">
    <hr/>
    <div class="tei-{@type}">
      <xsl:if test="@xml:lang"><xsl:attribute name="lang" select="@xml:lang"/></xsl:if>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="tei:TEI[tei:teiHeader]/tei:text/tei:group" priority="15"/>

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
      <h2 class="sd-part-title"><xsl:value-of select="tei:head[1]"/></h2>
      <xsl:apply-templates select="node()[not(self::tei:head[1])]"/>
    </section>
  </xsl:template>

  <xsl:template match="tei:div[@type='subpart']" priority="12">
    <section class="sd-subpart">
      <xsl:if test="@xml:id">
        <xsl:attribute name="id"><xsl:value-of select="@xml:id"/></xsl:attribute>
      </xsl:if>
      <h3 class="sd-subpart-title"><xsl:value-of select="tei:head[1]"/></h3>
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
      <h1 class="sd-page-title"><xsl:value-of select="tei:head[1]"/></h1>
      <xsl:apply-templates select="node()[not(self::tei:head[1])]"/>
    </article>
  </xsl:template>

  <xsl:template match="tei:p[starts-with(@rend,'heading-h2')]" priority="12">
    <h2 class="sd-legacy-h2"><xsl:apply-templates/></h2>
  </xsl:template>

  <xsl:template match="tei:p[starts-with(@rend,'heading-h3')]" priority="12">
    <h3 class="sd-legacy-h3"><xsl:apply-templates/></h3>
  </xsl:template>

  <xsl:template match="tei:ab[@type = 'legacy-inline']" priority="12">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="tei:trailer[@type = 'retour-debut']" priority="12">
    <xsl:variable name="prev" select="preceding-sibling::*[not(self::tei:pb)][1]"/>
    <p>
      <xsl:attribute name="class">
        <xsl:choose>
          <xsl:when test="contains('-–—', substring(normalize-space($prev), 1, 1))">p</xsl:when>
          <xsl:when test="local-name($prev) = 'p' and translate($prev, '*∾  ', '') != ''">p</xsl:when>
          <xsl:otherwise>p noindent</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <xsl:template match="tei:div[@type='search']" priority="30">
    <section class="sd-search" id="sd-search">
      <h2>Rechercher dans les chartes éditées</h2>
      <p class="sd-search-help">La recherche plein texte dans les actes du Cartulaire blanc
        (Beaurain, Dugny, Pierrefitte, Rueil, Saint-Martin, Tremblay, Ully) se fait avec le
        moteur de recherche de l’application, alimenté par l’index dots-cli-es.</p>
      <p class="sd-search-go"><a class="sd-search-link" href="../search">Ouvrir la recherche plein texte</a></p>
    </section>
  </xsl:template>

  <xsl:template match="tei:div[@type = 'notice']" priority="14">
    <article class="isd-notice" id="{@xml:id}">
      <h3 class="isd-notice-head"><xsl:apply-templates select="tei:head[1]/node()"/></h3>
      <xsl:apply-templates select="node() except tei:head[1]"/>
    </article>
  </xsl:template>

  <xsl:template match="tei:div[@type = 'section']" priority="14">
    <section class="isd-section" id="{@xml:id}">
      <h2 class="isd-section-head"><xsl:apply-templates select="tei:head[1]/node()"/></h2>
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
          <xsl:value-of select="concat($elec-base, '/saint-denis/document/', $vol, '?refId=', $vol, '_', $unite)"/>
          <xsl:text>&gt;</xsl:text>
        </span>
      </xsl:when>
      <xsl:otherwise><xsl:apply-templates select="$secours"/></xsl:otherwise>
    </xsl:choose>
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

  <xsl:template match="tei:expan" priority="20">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="tei:ex" priority="20">
    <span class="sd-ex">
      <xsl:text>(</xsl:text>
      <xsl:apply-templates/>
      <xsl:text>)</xsl:text>
    </span>
  </xsl:template>

  <xsl:template match="tei:div[@type = 'appendices']/tei:list[not(tei:head)]" priority="12">
    <p class="sd-annexes-label">Documents annexes</p>
    <xsl:apply-imports/>
  </xsl:template>

  <xsl:template match="tei:div[@type = 'short-summary']" priority="12"/>

  <xsl:template match="tei:div[@type = 'index'][starts-with(@xml:id, 'sd-index-auteurs-')]"
                priority="16">
    <xsl:variable name="cle" select="substring-after(@xml:id, 'sd-index-auteurs-')"/>
    <section class="sd-index-auteurs" id="{@xml:id}">
      <h2 class="sd-index-auteurs-titre">
        <xsl:value-of select="tei:head[1]"/>
      </h2>
      <p class="sd-index-auteurs-chapeau">
        <xsl:value-of select="count(tei:list/tei:item)"/>
        <xsl:text> termes, </xsl:text>
        <xsl:value-of select="count(tei:list/tei:item/tei:ptr)"/>
        <xsl:text> renvois. Index reconstitué depuis le texte encodé, en parité avec l’index publié par le site d’origine.</xsl:text>
      </p>
      <nav class="sd-index-lettres" aria-label="Aller à une initiale">
        <xsl:for-each select="tei:list">
          <a class="sd-index-lettre-lien" href="#sd-index-auteurs-{$cle}-{translate(@n, '*', '0')}">
            <xsl:choose>
              <xsl:when test="@n = '*'">&#8226;</xsl:when>
              <xsl:otherwise><xsl:value-of select="@n"/></xsl:otherwise>
            </xsl:choose>
          </a>
        </xsl:for-each>
      </nav>
      <xsl:for-each select="tei:list">
        <div class="sd-index-groupe" id="sd-index-auteurs-{$cle}-{translate(@n, '*', '0')}">
          <h3 class="sd-index-initiale"><xsl:value-of select="tei:head[1]"/></h3>
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
      </xsl:for-each>
    </section>
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
      <h1 class="sd-page-title"><xsl:value-of select="tei:head[1]"/></h1>
      <xsl:apply-templates select="node()[not(self::tei:head[1])]"/>
    </article>
  </xsl:template>

  <!-- ==== 4. MÉCANISMES COMMUNS : tableau filtrable (tf-*), liens vers l'ancien site (D5), liens internes entre fragments ==== -->

  <xsl:template match="tei:ref[starts-with(@target, 'illustrations/')] | tei:ptr[starts-with(@target, 'illustrations/')]" priority="12">
    <xsl:variable name="file" select="substring-after(@target, 'illustrations/')"/>
    <xsl:variable name="jointe" select="substring-after(@facs, 'images/saint-denis/illustrations/')"/>
    <xsl:choose>
      <xsl:when test="$jointe">
        <xsl:variable name="src" select="concat($sd-images, 'illustrations/', $jointe)"/>
        <xsl:choose>
          <xsl:when test="ends-with(lower-case($file), '.pdf') or ends-with(lower-case(string($jointe)), '.pdf')">
            <a class="sd-illustration-pdf" href="{$sd-fichiers}/images/saint-denis/illustrations/{$jointe}" target="_blank" rel="noopener">
              <xsl:apply-templates/>
              <xsl:text> (PDF)</xsl:text>
            </a>
          </xsl:when>
          <xsl:otherwise>
            <details class="sd-illustration">
              <summary><span class="sd-illustration-libelle"><xsl:apply-templates/></span></summary>
              <img class="sd-illustration-img" loading="lazy" src="{$src}" alt="{normalize-space(.)}"/>
            </details>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <span class="sd-illustration-absente" title="Illustration du site d’origine absente de cette copie ({$file})">
          <xsl:apply-templates/>
        </span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

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

  <xsl:template match="tei:ref[contains(@target, 'images/cartulaireblanc/') or contains(@target, 'images/inventaire/')]
                              [contains(@target, '/voir.html')][not(contains(@target, 'ns='))]"
                priority="15">
    <xsl:variable name="serie" select="substring-before(substring-after(@target, 'images/'), '/voir.html')"/>
    <xsl:variable name="n" select="normalize-space(@n)"/>
    <span class="sd-visionneuse-absente">
      <xsl:attribute name="title">
        <xsl:choose>
          <xsl:when test="$n &gt; 0">
            <xsl:text>La visionneuse de l'ancien site n'a pas d'équivalent ici. Sur cette série, </xsl:text>
            <xsl:value-of select="$n"/>
            <xsl:text> pages sont conservées en local : elles se déplient depuis les renvois du corpus qui les désignent.</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>La visionneuse de l'ancien site n'a pas d'équivalent ici : aucune image de cette série n'a été rapatriée.</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:apply-templates/>
      <xsl:if test="not(node())"><xsl:value-of select="$serie"/></xsl:if>
    </span>
  </xsl:template>

  <xsl:template priority="5"
      match="text()[not(ancestor::tei:ref)]
                   [ancestor::tei:p or ancestor::tei:note or ancestor::tei:item or ancestor::tei:witness]
                   [matches(., concat('actes?[\s&#160;]+(', $sd-chap-motif, ')[\s&#160;]*(n[\s&#160;]*[°o][\s&#160;]*)?\d'))]">
    <xsl:analyze-string select="."
        regex="{concat('(actes?[\s&#160;]+(', $sd-chap-motif, ')[\s&#160;]*(?:n[\s&#160;]*[°o][\s&#160;]*)?)(\d+[a-z]?)')}">
      <xsl:matching-substring>
        <xsl:value-of select="regex-group(1)"/>
        <xsl:call-template name="sd-lien-acte">
          <xsl:with-param name="chapitre" select="regex-group(2)"/>
          <xsl:with-param name="numero" select="regex-group(3)"/>
        </xsl:call-template>
      </xsl:matching-substring>
      <xsl:non-matching-substring><xsl:value-of select="."/></xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>

  <xsl:template priority="6"
      match="text()[not(ancestor::tei:ref)]
                   [preceding-sibling::node()[1][self::tei:hi][normalize-space() = 'o']]
                   [matches(., '^\s*\d')]
                   [matches(string(preceding-sibling::node()[2]),
                            concat('actes?\s+(', $sd-chap-motif, ')\s*n\s*$'))]">
    <xsl:variable name="avant" select="string(preceding-sibling::node()[2])"/>
    <xsl:variable name="chap">
      <xsl:for-each select="tokenize($sd-chap-motif, '\|')">
        <xsl:if test="matches($avant, concat('actes?\s+', ., '\s*n\s*$'))">
          <xsl:value-of select="."/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="string($chap) != ''">
        <xsl:analyze-string select="." regex="^(\s*)(\d+[a-z]?)">
          <xsl:matching-substring>
            <xsl:value-of select="regex-group(1)"/>
            <xsl:call-template name="sd-lien-acte">
              <xsl:with-param name="chapitre" select="string($chap)"/>
              <xsl:with-param name="numero" select="regex-group(2)"/>
            </xsl:call-template>
          </xsl:matching-substring>
          <xsl:non-matching-substring><xsl:value-of select="."/></xsl:non-matching-substring>
        </xsl:analyze-string>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="sd-lien-acte">
    <xsl:param name="chapitre"/>
    <xsl:param name="numero"/>
    <xsl:variable name="rid" select="lower-case($chapitre)"/>
    <a class="sd-acte-renvoi" title="Aller à l'acte {$chapitre} n° {$numero}"
       href="{$sd-vers-chapitres}{$rid}?refId={$rid}-acte{$numero}">
      <xsl:value-of select="$numero"/>
    </a>
  </xsl:template>

  <xsl:template priority="7"
      match="text()[not(ancestor::tei:ref)]
                   [ancestor::tei:witness[contains(@xml:id, '-indiqué-ig')]]
                   [matches(., $sd-ig-motif)]">
    <xsl:analyze-string select="." regex="{$sd-ig-motif}">
      <xsl:matching-substring>
        <xsl:variable name="v" select="string-length(regex-group(1))"/>
        <xsl:variable name="num" select="regex-group(4)"/>
        <xsl:variable name="n" select="number($num)"/>
        <xsl:choose>
          <xsl:when test="(($v = 1 and $n &gt;= 1 and $n &lt;= 1181)
                           or ($v = 2 and $n &gt;= 1182 and $n &lt;= 3195)
                           or ($v = 3 and $n &gt;= 3196 and $n &lt;= 3253))
                          and not(contains($sd-ig-lacunes, concat(' ', $v, '-', $num, ' ')))">
            <a class="sd-inventaire sd-ig-renvoi"
               title="Notice n° {$num} de l'Inventaire général, tome {regex-group(1)}"
               href="{$sd-vers-sd}ISD-vol{$v}?refId=ISD-vol{$v}_notice{$num}">
              <xsl:value-of select="."/>
            </a>
          </xsl:when>
          <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
        </xsl:choose>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:analyze-string select="."
            regex="{concat('(actes?[\s&#160;]+(', $sd-chap-motif, ')[\s&#160;]*(?:n[\s&#160;]*[°o][\s&#160;]*)?)(\d+[a-z]?)')}">
          <xsl:matching-substring>
            <xsl:value-of select="regex-group(1)"/>
            <xsl:call-template name="sd-lien-acte">
              <xsl:with-param name="chapitre" select="regex-group(2)"/>
              <xsl:with-param name="numero" select="regex-group(3)"/>
            </xsl:call-template>
          </xsl:matching-substring>
          <xsl:non-matching-substring><xsl:value-of select="."/></xsl:non-matching-substring>
        </xsl:analyze-string>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>

  <xsl:template match="tei:ref[contains(@target, 'ducange.enc.sorbonne.fr/')]" priority="14">
    <xsl:variable name="cible" select="substring-after(@target, 'ducange.enc.sorbonne.fr/')"/>
    <xsl:variable name="brut" select="replace(replace(upper-case(substring-before(concat($cible, '#'), '#')), '%20', ''), ' ', '')"/>
    <xsl:variable name="entree" select="if ($brut = 'PERTICA') then 'PERTICA1' else if ($brut = 'NUMMATA') then 'NUMISMA' else $brut"/>
    <xsl:variable name="ancre" select="substring-after($cible, '#')"/>
    <a href="{$elec-base}/ducange/document/ducange_{substring($entree, 1, 1)}?refId={$entree}{if ($ancre != '') then concat('#', $ancre) else ''}">
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

  <xsl:template match="tei:ref[not(@type = 'note')][contains(@target, '.xml')][not(contains(@target, ':'))]" priority="12">
    <xsl:variable name="file" select="substring-before(@target, '.xml')"/>
    <xsl:variable name="frag" select="substring-after(@target, '#')"/>
    <xsl:choose>
      <xsl:when test="contains($sd-chapitres, concat(' ', $file, ' ')) and $frag != ''">
        <a class="sd-internal" href="{$sd-vers-chapitres}{$file}?refId={$frag}"><xsl:apply-templates/></a>
      </xsl:when>
      <xsl:when test="contains($sd-chapitres, concat(' ', $file, ' '))">
        <a class="sd-internal" href="{$sd-vers-chapitres}{$file}"><xsl:apply-templates/></a>
      </xsl:when>
      <xsl:when test="starts-with($file, 'ISD-vol') and starts-with($frag, 'notice')">
        <a class="sd-inventaire" href="{$sd-vers-sd}{$file}?refId={$file}_{$frag}"><xsl:apply-templates/></a>
      </xsl:when>
      <xsl:otherwise><xsl:apply-imports/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tei:ref[not(@type = 'note')][contains(@target, '-acte')][not(contains(@target, '#') or contains(@target, '/') or contains(@target, '.') or contains(@target, ':'))]" priority="12">
    <xsl:variable name="chap" select="substring-before(@target, '-acte')"/>
    <xsl:choose>
      <xsl:when test="contains($sd-chapitres, concat(' ', $chap, ' '))">
        <a class="sd-internal" href="{$sd-vers-chapitres}{$chap}?refId={@target}"><xsl:apply-templates/></a>
      </xsl:when>
      <xsl:otherwise><xsl:apply-imports/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tei:ref[not(@type = 'note')][starts-with(@target, '#')][contains(@target, '-intro')][not(key('id', substring-after(@target, '#')))]" priority="13">
    <xsl:variable name="chap" select="substring-before(substring-after(@target, '#'), '-intro')"/>
    <xsl:choose>
      <xsl:when test="contains($sd-chapitres, concat(' ', $chap, ' '))">
        <a class="sd-internal" href="{$sd-vers-chapitres}{$chap}"><xsl:apply-templates/></a>
      </xsl:when>
      <xsl:otherwise><xsl:apply-imports/></xsl:otherwise>
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
    <a class="idno d5-local" href="../../saint-denis/"><xsl:apply-templates/></a>
  </xsl:template>

  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://saint-denis.enc.sorbonne.fr/cartulaire/tome1/beaurain/']" priority="14">
    <a class="idno d5-local" href="{$sd-vers-chapitres}beaurain"><xsl:apply-templates/></a>
  </xsl:template>

  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://saint-denis.enc.sorbonne.fr/cartulaire/tome1/dugny/']" priority="14">
    <a class="idno d5-local" href="{$sd-vers-chapitres}dugny"><xsl:apply-templates/></a>
  </xsl:template>

  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://saint-denis.enc.sorbonne.fr/cartulaire/tome1/pierrefitte/']" priority="14">
    <a class="idno d5-local" href="{$sd-vers-chapitres}pierrefitte"><xsl:apply-templates/></a>
  </xsl:template>

  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://saint-denis.enc.sorbonne.fr/cartulaire/tome1/rueil/']" priority="14">
    <a class="idno d5-local" href="{$sd-vers-chapitres}rueil"><xsl:apply-templates/></a>
  </xsl:template>

  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://saint-denis.enc.sorbonne.fr/cartulaire/tome1/saint-martin/']" priority="14">
    <a class="idno d5-local" href="{$sd-vers-chapitres}saint-martin"><xsl:apply-templates/></a>
  </xsl:template>

  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://saint-denis.enc.sorbonne.fr/cartulaire/tome1/tremblay/']" priority="14">
    <a class="idno d5-local" href="{$sd-vers-chapitres}tremblay"><xsl:apply-templates/></a>
  </xsl:template>

  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://saint-denis.enc.sorbonne.fr/cartulaire/tome1/ully/']" priority="14">
    <a class="idno d5-local" href="{$sd-vers-chapitres}ully"><xsl:apply-templates/></a>
  </xsl:template>

  <xsl:template match="tei:ref[@target = 'http://elec.enc.sorbonne.fr/cartulaires/']" priority="14">
    <a class="ref d5-local" href="{$elec-base}/cartulaires"><xsl:apply-templates/></a>
  </xsl:template>

  <xsl:template match="tei:ref[not(@type = 'note')][starts-with(@target, '#sd-')][not(key('id', substring-after(@target, '#')))]" priority="14">
    <xsl:variable name="id" select="substring-after(@target, '#')"/>
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
        <a class="sd-inventaire sd-inventaire-url" href="{$sd-vers-sd}ISD-vol{$tome}?refId=ISD-vol{$tome}_{$notice}"><xsl:apply-templates/></a>
      </xsl:when>
      <xsl:when test="$tome != '' and normalize-space($notice) = ''">
        <a class="sd-inventaire sd-inventaire-tome" href="{$sd-vers-sd}ISD-vol{$tome}"><xsl:apply-templates/></a>
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
           href="{$sd-vers-sd}{$file}?refId={$file}_{$frag}">
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
    <a class="sd-internal sd-index-ancre" href="#sd-index-auteurs-{$cle}"
       title="Index reconstitué depuis le texte encodé, au bas de cette page.">
      <xsl:apply-templates/>
    </a>
  </xsl:template>
</xsl:transform>
