<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.1" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:dts="https://w3id.org/dts/api#"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:edt="urn:cartu-edition"
  xmlns:cartu="urn:cartu"
  xmlns:tf="urn:elec:tableau-filtrable"
  xmlns:chr="urn:cartu-tableaux"
  xmlns:cartu-app="urn:cartu-appendice"
  xmlns:h="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="tei dts xs edt cartu tf chr cartu-app h"
>
  <!-- Cartulaires — feuille en blocs (2026-10-19), comme les autres corpus :
       0. déclarations ; 1. historique ÉLEC ; 2. blocs hteiml génériques (enveloppe dts:wrapper,
       numérotation des notes, noms) ; 3. propre au projet (index, renvois, témoins et folios,
       présentation des actes, tables de SSCO et SCOR ; la page Édition et les tableaux sont en fin de
       feuille) ; 4. mécanismes communs (liens vers
       l'ancien site, D5). Les modules communs (tableau filtrable, bibliographie) sont importés. -->

  <!-- ==== 0. DÉCLARATIONS : imports, modules, paramètres, sortie ==== -->

  <xsl:import href="../../renderers/hteiml/xsl/tei2html.xsl"/>
  <!-- Modules communs à tous les corpus (copies à côté de cette feuille) : tableaux triables et
       filtrables (classes tf-*, comportement dans le JS générique de l'ÉLEC) et bibliographies
       (listBibl). La page de titre est servie à part (teiHeader2html.xsl). -->
  <xsl:import href="tableau-filtrable.xsl"/>
  <xsl:import href="bibliographie.xsl"/>
  <!-- 2026-09-21 : identifiant de la ressource servie. dots/webapp/restxq/routes.xqm l. 273 le
       passe deja a la feuille : xslt:transform($result, doc($style),
       map {"static_path": $G:static_path, "resource": $resource}). Sans declaration, XSLT
       l'ignore silencieusement. Il sert a fabriquer les liens du tableau des actes vers la page
       de chaque acte (voir cartulaires-acte-href). -->
  <!-- 2026-10-19 : DoTS dev (0fb0c43, routes.xqm l. 312) ne passe plus que static_path : sans valeur par
       défaut, $resource restait vide (liens du tableau des actes, compagnon de la page Édition, noms des
       fichiers CSV). Par défaut, le code de la ressource est lu sur les identifiants du document servi,
       qui commencent tous par lui (« SMPA-EG_0001 », « SMPA-AB-01_front_0003 »). -->
  <xsl:param name="resource" select="(for $i in (//@xml:id)[matches(., '^[A-Z]{4,5}-[A-Z]{2}(-\d+)?_')][1] return replace($i, '^([A-Z]{4,5}-[A-Z]{2}(-\d+)?)_.*$', '$1'), '')[1]"/>
  <!-- 2026-10-02 : début des liens internes. Le front dev est monté sous /elec/ : sans ce
       préfixe, les renvois de l'index et les liens vers les actes sortaient de l'application.
       La copie servie en local (dots-clean) remplace cette valeur par '/cartulaires/document/'. -->
  <!-- 2026-10-28 : liens relatifs (« HDPAR-HD?refId=… »), justes sous /elec/ comme en local : dots-vue les
       résout depuis /<projet>/document/<ressource>. -->
  <xsl:variable name="document-base" select="''"/>
  <xsl:output indent="no"/><!-- autopilote 2026-09-11 : sinon DoTS-vue colle les mots (condense) -->
  <!-- 2026-10-20 : chapitres du Cartulaire blanc de Saint-Denis (beaurain, dugny, pierrefitte, rueil, saint-martin,
       tremblay, ully) et ses pages (cartulaire-blanc, sd-…) : rendus par cartulaires-saint-denis.xsl, appelée ici par
       transform(), au lieu d'une feuille <ressource>.xsl par chapitre (routes.xqm). Repérés à leur premier identifiant. -->
  <xsl:variable name="cartu-sd" as="xs:boolean"
    select="matches(string((//@xml:id)[1]), '^((beaurain|dugny|pierrefitte|rueil|saint-martin|tremblay|ully|cartulaire-blanc)(-|$)|sd-)')"/>
  <xsl:template match="document-node()[$cartu-sd]" priority="1000">
    <xsl:sequence select="transform(map {
        'stylesheet-location': resolve-uri('cartulaires-saint-denis.xsl', static-base-uri()),
        'source-node': .,
        'stylesheet-params': map { QName('', 'static_path'): $static_path } })?output"/>
  </xsl:template>
  <!-- Diple relativement à ici pour CSS et js par défaut
  <xsl:param name="dipleHref">
    <xsl:value-of select="$xslBase"/>
    <xsl:text>../../diple/</xsl:text>
  </xsl:param>
  -->

  <!-- ==== 1. HISTORIQUE : feuille de l'ÉLEC ==== -->

  <xsl:template match="tei:unclear[not(node())]" priority="5">
    <span class="unclear" title="lecture incertaine">[?]</span>
  </xsl:template>
  <!-- ne pas sortir le back qui ne doit contenir que des index -->
  <xsl:template match="/tei:TEI/tei:text/tei:back"/>
  <!-- lien vers un dictionnaire -->
  <xsl:template match="@xml:lang[.='fro']">
    <!-- à corriger
    <xsl:attribute name="ondblclick">if (window.Win) Win.dmf()</xsl:attribute>
    -->
  </xsl:template>

  <xsl:template match="//tei:front/tei:div[@type='dissertation']">
    <section class="div dissertation level2">
      <h3>Dissertation critique</h3><xsl:apply-templates/>
    </section>
  </xsl:template>

  <!-- ==== 2. BLOCS HTEIML GÉNÉRIQUES : enveloppe dts:wrapper et notes, numérotation des notes, noms ==== -->
  <!-- 2026-10-19 : APPELS D'APPARAT. Les notes d'apparat des cartulaires sont des notes à lettre
       (@n="a", Saint-Martin-des-Champs, Orléans…) : hteiml leur donne la même classe qu'aux notes savantes.
       L'appel affiché en lettre reçoit en plus la classe app-ref, que la CSS met en italique (modèle :
       Montferrand, a.apparatus-call). Le rendu de hteiml est gardé tel quel (next-match). -->
  <!-- 2026-10-19 : NOTE RÉPÉTÉE. Une note identique à une note précédente de même numéro, dans le même
       acte (SMPO-AB_1b : deux notes 3 « Amaury de Pontoise… », une par appel) n'est pas répétée en pied de
       page ; son appel renvoie à la première. -->
  <xsl:function name="cartu:note-premiere" as="element()?" version="3.0" xmlns:cartu="urn:cartu">
    <xsl:param name="n" as="element()"/>
    <xsl:sequence select="($n/preceding::tei:note[@n = $n/@n][@xml:id][normalize-space(.) = normalize-space($n)][let $a := ancestor::tei:text[1], $b := $n/ancestor::tei:text[1] return (empty($a) and empty($b)) or ($a is $b)])[1]"/>  <!-- le pied de page travaille sur une copie des notes, sans acte parent -->
  </xsl:function>
  <xsl:template match="tei:note[@n][exists(cartu:note-premiere(.))]" mode="fn" priority="40" xmlns:cartu="urn:cartu"/>

  <xsl:template match="tei:note" priority="40" version="3.0">
    <xsl:variable name="n"><xsl:call-template name="note-n"/></xsl:variable>
    <xsl:variable name="lettre" select="matches(normalize-space($n), '^[a-z]{1,2}$')"/>
    <xsl:variable name="premiere" select="if (@n) then cartu:note-premiere(.) else ()" xmlns:cartu="urn:cartu"/>
    <xsl:choose>
      <xsl:when test="$lettre or exists($premiere)">
        <xsl:variable name="rendu"><xsl:next-match/></xsl:variable>
        <xsl:apply-templates select="$rendu/node()" mode="cartu-app-ref">
          <xsl:with-param name="lettre" select="$lettre" tunnel="yes"/>
          <xsl:with-param name="cible" select="string($premiere/@xml:id)" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise><xsl:next-match/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="@* | node()" mode="cartu-app-ref">
    <xsl:copy><xsl:apply-templates select="@* | node()" mode="cartu-app-ref"/></xsl:copy>
  </xsl:template>
  <xsl:template match="*[local-name() = 'a'][tokenize(@class, '\s+') = 'noteref']/@href" mode="cartu-app-ref">
    <xsl:param name="cible" tunnel="yes" select="''"/>
    <xsl:attribute name="href" select="if ($cible != '') then concat('#', $cible) else ."/>
  </xsl:template>
  <xsl:template match="*[local-name() = 'a'][tokenize(@class, '\s+') = 'noteref']/@class" mode="cartu-app-ref">
    <xsl:param name="lettre" tunnel="yes" select="false()"/>
    <xsl:attribute name="class" select="if ($lettre) then concat(., ' app-ref') else ."/>
  </xsl:template>

  <!-- 2026-10-19 : ESPACES PERDUS ENTRE DEUX ÉLÉMENTS. Un retour à la ligne du TEI entre deux éléments
       en ligne (« <placeName>Bernuzum</placeName>⏎<sic>(sic)</sic> », SMPA-EG n° I) passe tel quel dans
       le HTML ; dots-vue compile la page en gabarit Vue (mode condense), qui SUPPRIME un blanc entre deux
       éléments s'il contient un retour à la ligne : « Bernuzum(sic) » (517 cas dans 115 pages de
       l'échantillon). Dans un contenu mixte, ce blanc devient une espace simple, que Vue garde. Pas
       devant une note : l'appel reste collé au mot. -->
  <xsl:template match="text()[not(normalize-space())][contains(., '&#10;')][preceding-sibling::*][following-sibling::*[1][not(self::tei:note)]][../text()[normalize-space()]]" priority="2">
    <xsl:text> </xsl:text>
  </xsl:template>


  <!-- 2026-09-11 (autopilote, B8b 8) : fragment sans tei:text (index, parties) servi dans un dts:wrapper : hteiml traverse
       le wrapper sans appeler « footnotes » (seul son modèle tei:text le fait) → appels #noteN sans note (ex. NDPA-EG-04
       r427440 : 21 appels ; les renvois « Vide … » de l'index y sont). Bloc de notes de hteiml rétabli, sans le
       classement par page (tei:pb masqués ici : leurs repères « p. N » seraient des ancres mortes).
       Sauvegarde *.bak_b8b8_20260911. -->
  <!-- Pas de second bloc si le rendu en contient déjà un (ex. NDCH-EG r109063). Dans ce bloc, hteiml donne à la note l'id
       de l'appel (note1 ↔ appel href="#note1" id="note1_") mais un retour vers un autre id (#p3229_fn1) : le retour est
       réécrit en #<id de la note>_ (id de l'appel chez hteiml). -->
  <!-- 2026-10-06 : le conteneur dts:wrapper de DoTS est traversé ICI, dans la feuille du corpus,
       et non plus seulement par le HTEIML : la copie locale du HTEIML (dots-clean) a cette règle,
       celle du serveur dev (/dots/xsl/) ne l'a pas, et marquait le wrapper comme élément inconnu
       (« <dts:wrapper> » en rouge en tête de chaque acte). Les pages sans <text> (index, parties)
       ont leur propre modèle, ci-dessous (priorité supérieure). -->
  <!-- 2026-10-22, repris le 2026-10-28 (Maxime : « séparer apparat critique et notes », « 1 à n ») : PIED DE PAGE
       EN DEUX SECTIONS. Dernière passe sur le rendu de toute page qui a des notes (acte, index, liste) :
       - l'apparat (notes à lettre : @n="a", « 270_a ») rejoint le bloc p.apparatus (celui de Micy s'il existe),
         au format de hteiml (span.note, lettre en lien de retour) : le bloc CSS commun « apparat » s'y applique ;
       - les notes numérotées suivent, renumérotées 1 à n dans l'ordre de leur premier appel (le TEI garde
         parfois le numéro de l'imprimé : « 271 », « 64 ») ; les notes sans appel viennent à la fin ;
       - plus d'intertitre de page (« p. 207 », « t. I, p. 4 ») dans le pied de page. -->
  <xsl:template match="*[local-name() = 'wrapper'][.//tei:note]" priority="30" version="3.0">
    <xsl:variable name="rendu"><xsl:next-match/></xsl:variable>
    <xsl:variable name="en-place" select="$rendu//*[local-name() = 'p'][tokenize(@class, '\s+') = 'note-place']/@data-note/string()"/>
    <xsl:variable name="notes" select="$rendu//*[local-name() = 'section'][tokenize(@class, '\s+') = 'footnotes']//*[local-name() = ('aside', 'div')][tokenize(@class, '\s+') = 'note'][@id][not(@id = $en-place)]"/>
    <xsl:variable name="numerotees" select="$notes[not(cartu:pied-lettre(.))]/string(@id)"/>
    <xsl:variable name="appels" select="distinct-values($rendu//*[local-name() = 'a'][tokenize(@class, '\s+') = 'noteref']/substring-after(@href, '#'))"/>
    <xsl:variable name="ordre" select="($appels[. = $numerotees], $numerotees[not(. = $appels)])"/>
    <!-- une seule section de notes, la dernière : hteiml en ouvre une autre pour une note sans appel de
         l'en-tête de l'acte, qui sortait avant les autres (NDVC-AB_0003) -->
    <xsl:variable name="sections" select="$rendu//*[local-name() = 'section'][tokenize(@class, '\s+') = 'footnotes']"/>
    <xsl:apply-templates select="$rendu/node()" mode="cartu-pied">
      <xsl:with-param name="ordre" select="$ordre" tunnel="yes"/>
      <xsl:with-param name="sections" select="$sections" tunnel="yes"/>
      <xsl:with-param name="en-place" select="$en-place" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>
  <xsl:function name="cartu:pied-lettre" as="xs:boolean" version="3.0">
    <xsl:param name="note" as="element()"/>
    <xsl:sequence select="matches(normalize-space(($note//*[local-name() = 'a'][tokenize(@class, '\s+') = 'noteback'])[1]), '^[a-z]{1,2}\.?$')"/>
  </xsl:function>
  <xsl:template match="@* | node()" mode="cartu-pied">
    <xsl:copy><xsl:apply-templates select="@* | node()" mode="cartu-pied"/></xsl:copy>
  </xsl:template>
  <!-- appel d'une note numérotée : nouveau numéro -->
  <xsl:template match="*[local-name() = 'a'][tokenize(@class, '\s+') = 'noteref']" mode="cartu-pied" version="3.0">
    <xsl:param name="ordre" tunnel="yes" as="xs:string*"/>
    <xsl:variable name="rang" select="index-of($ordre, substring-after(@href, '#'))[1]"/>
    <xsl:choose>
      <xsl:when test="exists($rang)">
        <xsl:copy>
          <xsl:copy-of select="@*"/>
          <sup><xsl:value-of select="$rang"/></sup>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise><xsl:next-match/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="*[local-name() = 'section'][tokenize(@class, '\s+') = 'footnotes']" mode="cartu-pied" version="3.0">
    <xsl:param name="ordre" tunnel="yes" as="xs:string*"/>
    <xsl:param name="sections" tunnel="yes" as="element()*"/>
    <xsl:param name="en-place" tunnel="yes" as="xs:string*"/>
    <xsl:variable name="tout" select="$sections//*[local-name() = ('aside', 'div')][tokenize(@class, '\s+') = 'note'][@id]"/>
    <xsl:variable name="notes" select="$tout[not(@id = $en-place)]"/>
    <xsl:variable name="apparat" select="$notes[cartu:pied-lettre(.)]"/>
    <xsl:variable name="micy" select="$sections/*[local-name() = 'p'][tokenize(@class, '\s+') = 'apparatus']"/>
    <xsl:if test=". is $sections[last()] and (exists($notes) or exists($micy))">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <!-- ce qui n'est ni note, ni intertitre de page, ni apparat (rare) est gardé en tête -->
      <xsl:apply-templates select="$sections/node()[not(self::*[local-name() = 'div'][tokenize(@class, '\s+') = 'page'])][not(. intersect ($tout, $micy))]" mode="cartu-pied"/>
      <xsl:if test="exists($apparat) or exists($micy)">
        <p class="apparatus">
          <xsl:apply-templates select="$micy/node()" mode="cartu-pied"/>
          <xsl:for-each select="$apparat">
            <xsl:variable name="retour" select="(.//*[local-name() = 'a'][tokenize(@class, '\s+') = 'noteback'])[1]"/>
            <span class="note" id="{@id}">
              <a class="" href="{$retour/@href}"><xsl:value-of select="replace(normalize-space($retour), '\.$', '')"/></a>
              <xsl:text> </xsl:text>
              <xsl:for-each select="node()[not(. is $retour)]">
                <xsl:choose>
                  <!-- note d'apparat en paragraphes : le contenu, sans le <p> (pas de bloc dans un span) -->
                  <xsl:when test="self::*[local-name() = 'p']">
                    <xsl:apply-templates select="node()[not(. is $retour)]" mode="cartu-pied"/>
                    <xsl:text> </xsl:text>
                  </xsl:when>
                  <xsl:otherwise><xsl:apply-templates select="." mode="cartu-pied"/></xsl:otherwise>
                </xsl:choose>
              </xsl:for-each>
            </span>
            <xsl:text> </xsl:text>
          </xsl:for-each>
        </p>
      </xsl:if>
      <xsl:for-each select="$notes[not(cartu:pied-lettre(.))]">
        <xsl:sort select="(index-of($ordre, string(@id)), 9999)[1]" data-type="number"/>
        <xsl:apply-templates select="." mode="cartu-pied"/>
      </xsl:for-each>
    </xsl:copy>
    </xsl:if>
  </xsl:template>
  <!-- numéro affiché dans la note -->
  <xsl:template match="*[local-name() = 'a'][tokenize(@class, '\s+') = 'noteback']" mode="cartu-pied" version="3.0">
    <xsl:param name="ordre" tunnel="yes" as="xs:string*"/>
    <xsl:variable name="rang" select="index-of($ordre, string(ancestor::*[local-name() = ('aside', 'div')][tokenize(@class, '\s+') = 'note'][@id][1]/@id))[1]"/>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:value-of select="if (exists($rang)) then concat($rang, '. ') else string(.)"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[local-name() = 'wrapper']" priority="5" version="3.0">
    <!-- 2026-10-19 : notes répétées (voir « NOTE RÉPÉTÉE », bloc 3) retirées du pied de page : hteiml y
         rend les notes par le modèle nommé « note », qu'on ne peut pas surcharger sans le recopier. -->
    <xsl:variable name="doublons" select="for $n in .//tei:note[@n][@xml:id] return (if (exists(cartu:note-premiere($n))) then string($n/@xml:id) else ())" xmlns:cartu="urn:cartu"/>
    <xsl:choose>
      <xsl:when test="not(.//tei:note)"><xsl:apply-templates/></xsl:when>
      <xsl:otherwise>
        <xsl:variable name="rendu"><xsl:apply-templates/></xsl:variable>
        <!-- et toute note rendue deux fois sous le même identifiant (hteiml : avant le premier saut de
             page et sur sa page, NDVC-AB_0712) -->
        <xsl:variable name="ids" select="$rendu//*[local-name() = ('aside', 'div')][tokenize(@class, '\s+') = 'note']/@id/string()"/>
        <xsl:choose>
          <xsl:when test="empty($doublons) and count($ids) = count(distinct-values($ids))"><xsl:sequence select="$rendu/node()"/></xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="$rendu/node()" mode="cartu-sans-doublon">
              <xsl:with-param name="doublons" select="$doublons" tunnel="yes"/>
            </xsl:apply-templates>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="@* | node()" mode="cartu-sans-doublon">
    <xsl:copy><xsl:apply-templates select="@* | node()" mode="cartu-sans-doublon"/></xsl:copy>
  </xsl:template>
  <xsl:template match="*[local-name() = ('aside', 'div')][tokenize(@class, '\s+') = 'note'][@id]" mode="cartu-sans-doublon">
    <xsl:param name="doublons" tunnel="yes" as="xs:string*"/>
    <xsl:variable name="id" select="string(@id)"/>
    <xsl:if test="not($id = $doublons) and not(preceding::*[local-name() = ('aside', 'div')][tokenize(@class, '\s+') = 'note'][@id = $id])"><xsl:next-match/></xsl:if>
  </xsl:template>
  <xsl:template match="*[local-name() = 'wrapper'][not(.//tei:text)]" priority="20">
    <!-- 2026-10-19 : apply-templates et non apply-imports : le hteiml du serveur n'a pas de règle pour
         dts:wrapper et l'affichait comme élément inconnu (span « <dts:wrapper> » en rouge, 861 pages de
         l'échantillon) ; un tableau (div) dans ce span empêchait dots-vue de compiler la page. -->
    <xsl:variable name="rendu">
      <xsl:apply-templates/>
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
  <!-- 2026-10-06 : SMPA-AB, SCCO-AB (et quelques notes de SAPC, SGDP) numérotent leurs notes
       « acte_note » (n="270_4", n="270_a"), pour qu'elles soient uniques dans le volume. Le
       HTEIML affichait ce @n tel quel (« 270_4 ») : on n'affiche que la partie après le
       préfixe… non : comme le dev (« ça marche super »), toutes les notes de l'acte sont
       numérotées à la suite, lettres comprises (270 : 1 à 8). Copie de note-n (tei2html.xsl) avec ce seul cas
       en plus : un modèle nommé ne peut pas appeler celui qu'il remplace. -->
  <xsl:template name="note-n">
    <xsl:variable name="resp" select="@resp"/>
    <xsl:variable name="hasformat" select="@rend != '' and boolean(translate(substring-before(concat(@rend, ' '), ' '), '1AaIi', '') = '')"/>
    <xsl:choose>
      <!-- 2026-10-28 (Maxime, SMPA-AB-03_1 : « séparer apparat critique et notes ») : « 270_a » → « a »
           (apparat), « 270_4 » → « 4 » ; le pied de page (« PIED DE PAGE », plus bas) renumérote les
           chiffres de 1 à n. Remplace la numérotation à la suite, lettres comprises, du 2026-10-06. -->
      <xsl:when test="matches(normalize-space(@n), '^[^_\s]+_[^_\s]+$')">
        <xsl:value-of select="replace(normalize-space(@n), '^[^_]+_', '')"/>
      </xsl:when>
      <!-- 2026-10-27 : Micy (SMMI-AB), variantes <note type="n1"> : lettres a, b, c… (appel et apparat) -->
      <xsl:when test="self::tei:note[@type = 'n1'][not(@n)]">
        <xsl:number count="tei:note[@type = 'n1'][not(@n)]" format="a" level="any" from="tei:group/tei:text | *[local-name() = 'wrapper']"/>
      </xsl:when>
      <xsl:when test="@n">
        <xsl:value-of select="@n"/>
      </xsl:when>
      <xsl:when test="self::tei:ref[@type='note']">
        <xsl:for-each select="key('id', substring-after(@target, '#'))[1]">
          <xsl:call-template name="n"/>
        </xsl:for-each>
      </xsl:when>
      <xsl:when test="self::tei:app">
        <xsl:number count="tei:app" format="a" level="any" from="*[local-name() = 'wrapper']"/>
      </xsl:when>
      <xsl:when test="$hasformat">
        <xsl:number count="tei:note[@rend=$hasformat]" format="{@rend}" level="any" from="/"/>
      </xsl:when>
      <xsl:when test="@type='app'">
        <xsl:number count="tei:note[@type='app']" format="a" level="any" from="/"/>
      </xsl:when>
      <xsl:when test="@resp='editor'">
        <xsl:number count="tei:note[@resp=$resp]" format="I" level="any" from="/"/>
      </xsl:when>
      <xsl:when test="@resp">
        <xsl:number count="tei:note[@resp=$resp]" level="any" from="/"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:number count="tei:note[not(@resp) and not(@rend) and not(parent::tei:div) and not(parent::tei:notesStmt)][not(@type = 'n1' or (string-length(normalize-space(@n)) = 1 and contains('abcdefghijklmnopqrstuvwxyz', normalize-space(@n))) or (not(@n) and not(@type) and (parent::tei:front or parent::tei:div[ancestor::tei:front]) ))]" level="any" from="/"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- 2026-10-27 : note sans numéro placée dans le front, hors du texte (« L'édition a été établie d'après B. »,
       après la liste des témoins) : rendue à sa place, en paragraphe, et non en note de bas de page numérotée. -->
  <xsl:template match="tei:note[(not(@n) and not(@type) and (parent::tei:front or parent::tei:div[ancestor::tei:front]) )]" priority="45">
    <p class="note-tradition"><xsl:apply-templates select="if (count(*) = 1 and tei:p and normalize-space(string-join(text(), '')) = '') then tei:p/node() else node()"/></p>
  </xsl:template>
  <!-- 2026-10-28 (Maxime, SSCO-AB_a02 : « pourquoi j'ai un . à côté de ma note ») : NOTE SANS APPEL ENTRE DEUX
       PARAGRAPHES. <note> nue, enfant d'une div du corps (« (Collacio fit) », « (Signa) », « (Monogramme) »,
       courts commentaires de l'éditeur : 67 dans 12 cartulaires) : rendue à sa place, en petit paragraphe, et
       non plus en note « 1. » sans appel. data-note porte l'id que hteiml lui donnerait en pied de page : la
       passe « PIED DE PAGE » y retire cette note. -->
  <xsl:template match="tei:note[not(@*)][parent::tei:div or parent::tei:body][ancestor::tei:body]" priority="45">
    <xsl:variable name="id"><xsl:call-template name="id"/></xsl:variable>
    <p class="note-place" data-note="{$id}"><xsl:apply-templates select="if (count(*) = 1 and tei:p and normalize-space(string-join(text(), '')) = '') then tei:p/node() else node()"/></p>
  </xsl:template>
  <!-- 2026-10-28 (Maxime, SMPA-EG_censier_0006 : « c'est des notes, ça ? ») : notes du censier de SMPA-EG converties
       en paragraphes <p type="note">1. Troisième main.</p> (175), appels collés au texte (« Blont1] ») : 19 seulement
       retrouvent un appel unique, 42 ont avalé l'article suivant ; reconversion à faire sur le fac-similé. En
       attendant, rendues comme des notes (petites, sous un filet), et non comme des articles du censier. -->
  <xsl:template match="tei:p[@type = 'note']" priority="35">
    <p class="cartu-note-censier{if (preceding-sibling::*[1][self::tei:p[@type = 'note']]) then '' else ' premiere'}"><xsl:apply-templates/></p>
  </xsl:template>
  <!-- 2026-10-27 : Corpus sigillorum (annexes de SAPC-AB) : paragraphes plats dans la source ; une classe par sorte de
       ligne pour la mise en retrait (CSS) : sigillant (« I. INNOCENTIUS III. »), lieu (« – Embrun. »), date et cote
       (« 1 - 1207, 19 février. L 237 n° 58. »), description du sceau (le reste). -->
  <xsl:template version="3.0" priority="35" match="tei:div[tei:head[matches(normalize-space(.), 'Corpus sigillorum', 'i')]]/tei:div//tei:p">
    <xsl:variable name="s" select="normalize-space(string-join(.//text()[not(ancestor::tei:note)], ''))"/>
    <xsl:variable name="sorte" select="if (*[1][self::tei:hi[@rend = 'b']] and normalize-space(string-join(text()[. &lt;&lt; current()/*[1]], '')) = '') then 'sceau-sigillant'
      else if (matches($s, '^[–-]\s')) then 'sceau-lieu'
      else if (matches($s, '^(\d+\s*[-–]\s*)?\d{4}')) then 'sceau-cote'
      else 'sceau-description'"/>
    <p class="p {$sorte}"><xsl:apply-templates/></p>
  </xsl:template>
  <!-- 2026-10-27 : APPARAT CRITIQUE DE SMMI-AB. Les variantes du Cartulaire de Micy sont des notes
       <note type="n1"> (sans tei:app, sans @n) : hteiml les rendait en bas de page, mêlées aux notes
       savantes (n2, notes sans type). Elles sortent désormais dans <p class="apparatus"> en tête de la
       section des notes, comme l'apparat de chroniqueslatines ; leurs appels restent dans le texte.
       Copie du modèle nommé « footnotes » de tei2html.xsl (un modèle nommé ne peut pas appeler celui qu'il
       remplace) : seule différence, les notes n1 sont retirées des pages de notes et ajoutées à l'apparat.
       Sans note n1 (tous les autres cartulaires), le résultat est celui de hteiml. -->
  <xsl:template match="tei:note[@type = 'n1' or (string-length(normalize-space(@n)) = 1 and contains('abcdefghijklmnopqrstuvwxyz', normalize-space(@n))) or (not(@n) and not(@type) and (parent::tei:front or parent::tei:div[ancestor::tei:front]) )]" mode="fn" priority="25"/>
  <xsl:template name="footnotes" xmlns:epub="http://www.idpf.org/2007/ops">
    <xsl:param name="cont" select="*"/>
    <xsl:param name="pb" select="$cont//tei:pb[@n][not(@ed)]"/>
    <xsl:variable name="notes">
      <xsl:variable name="apparatus">
        <xsl:for-each select="$cont//(tei:app | tei:note[@type = 'n1' or (string-length(normalize-space(@n)) = 1 and contains('abcdefghijklmnopqrstuvwxyz', normalize-space(@n)))])">
          <xsl:choose>
            <!-- 2026-10-27 : variante de Micy : la lettre, puis le texte (sans la virgule de note-inline) -->
            <xsl:when test="self::tei:note[@type = 'n1' or (string-length(normalize-space(@n)) = 1 and contains('abcdefghijklmnopqrstuvwxyz', normalize-space(@n)))]">
              <xsl:variable name="id"><xsl:call-template name="id"/></xsl:variable>
              <span class="note" id="{$id}"><a class="" href="#{$id}_"><xsl:call-template name="note-n"/></a><xsl:text> </xsl:text><xsl:apply-templates select="if (count(*) = 1 and tei:p and normalize-space(string-join(text(), '')) = '') then tei:p/node() else node()"/></span>
              <xsl:text> </xsl:text>
            </xsl:when>
            <xsl:otherwise><xsl:call-template name="note-inline"/></xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:variable>
      <xsl:if test="$apparatus != ''">
        <p class="apparatus">
          <xsl:copy-of select="$apparatus"/>
        </p>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="$pb">
          <xsl:variable name="notes1" select="key('note-pb', '')[not(@type = 'n1' or (string-length(normalize-space(@n)) = 1 and contains('abcdefghijklmnopqrstuvwxyz', normalize-space(@n))) or (not(@n) and not(@type) and (parent::tei:front or parent::tei:div[ancestor::tei:front]) ))][not(cartu:lettre-cachee(.))]"/>
          <xsl:if test="$notes1">
            <div class="page">
              <xsl:for-each select="$notes1[@resp = 'author'][not(@place = 'margin')]">
                <xsl:call-template name="note"/>
              </xsl:for-each>
              <xsl:for-each select="$notes1[@resp = 'editor'][not(@place = 'margin')]">
                <xsl:call-template name="note"/>
              </xsl:for-each>
              <xsl:for-each select="$notes1[not(@resp) or (@resp != 'editor' and @resp != 'author')][not(@place = 'margin')]">
                <xsl:call-template name="note"/>
              </xsl:for-each>
            </div>
          </xsl:if>
          <xsl:for-each select="$pb">
            <xsl:variable name="notes4page">
              <xsl:for-each select="key('note-pb', generate-id())[not(@type = 'n1' or (string-length(normalize-space(@n)) = 1 and contains('abcdefghijklmnopqrstuvwxyz', normalize-space(@n))) or (not(@n) and not(@type) and (parent::tei:front or parent::tei:div[ancestor::tei:front]) ))][not(cartu:lettre-cachee(.))][@resp = 'author'][not(@place = 'margin')]">
                <xsl:call-template name="note"/>
              </xsl:for-each>
              <xsl:for-each select="key('note-pb', generate-id())[not(@type = 'n1' or (string-length(normalize-space(@n)) = 1 and contains('abcdefghijklmnopqrstuvwxyz', normalize-space(@n))) or (not(@n) and not(@type) and (parent::tei:front or parent::tei:div[ancestor::tei:front]) ))][not(cartu:lettre-cachee(.))][@resp = 'editor'][not(@place = 'margin')]">
                <xsl:call-template name="note"/>
              </xsl:for-each>
              <xsl:for-each select="key('note-pb', generate-id())[not(@type = 'n1' or (string-length(normalize-space(@n)) = 1 and contains('abcdefghijklmnopqrstuvwxyz', normalize-space(@n))) or (not(@n) and not(@type) and (parent::tei:front or parent::tei:div[ancestor::tei:front]) ))][not(cartu:lettre-cachee(.))][not(@resp) or (@resp != 'editor' and @resp != 'author')][not(@place = 'margin')]">
                <xsl:call-template name="note"/>
              </xsl:for-each>
            </xsl:variable>
            <xsl:if test="$notes4page != ''">
              <div class="page">
                <div class="b note-page">
                  <xsl:call-template name="a"/>
                </div>
                <xsl:copy-of select="$notes4page"/>
              </div>
            </xsl:if>
          </xsl:for-each>
        </xsl:when>
        <xsl:when test="$cont">
          <xsl:apply-templates select="$cont" mode="fn">
            <xsl:with-param name="resp">author</xsl:with-param>
          </xsl:apply-templates>
          <xsl:apply-templates select="$cont" mode="fn">
            <xsl:with-param name="resp">editor</xsl:with-param>
          </xsl:apply-templates>
          <xsl:apply-templates select="$cont" mode="fn"/>
        </xsl:when>
        <xsl:when test="key('id', 'note-footseq')">
          <xsl:apply-templates select="*" mode="fn"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="*" mode="fn">
            <xsl:with-param name="resp">author</xsl:with-param>
          </xsl:apply-templates>
          <xsl:apply-templates select="*" mode="fn">
            <xsl:with-param name="resp">editor</xsl:with-param>
          </xsl:apply-templates>
          <xsl:apply-templates select="*" mode="fn"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="$notes != ''">
      <xsl:variable name="el">
        <xsl:choose>
          <xsl:when test="$format = $epub2">div</xsl:when>
          <xsl:otherwise>section</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:element name="{$el}" namespace="http://www.w3.org/1999/xhtml">
        <xsl:attribute name="class">footnotes</xsl:attribute>
        <xsl:if test="$format = $epub3">
          <xsl:attribute name="epub:type">footnotes</xsl:attribute>
        </xsl:if>
        <xsl:copy-of select="$notes"/>
      </xsl:element>
    </xsl:if>
  </xsl:template>

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
           | tei:placeName[tei:surname] | tei:orgName[tei:surname]
           | tei:author[tei:surname] | tei:editor[tei:surname]">
    <!-- 2026-10-19 : author et editor ajoutés : les bibliographies passent désormais par le module
         commun, qui laisse hteiml rendre la référence (« Berman (Constance H.) » perdait son prénom). -->
    <span class="{local-name()}"><xsl:apply-templates/></span>
  </xsl:template>

  <!-- ==== 3. PROPRE AU PROJET ==== -->

  <!-- 2026-10-19 : intertitre de page des notes (« p. 3_0102 ») pour une notation tome + page : « t. III, p. 102 ». -->
  <xsl:template match="tei:pb[matches(normalize-space(@n), '^(t?\d+_p?\d+|[IVX]+\.\s*\d+)$')]" mode="a" priority="5" version="3.0">
    <a>
      <xsl:attribute name="href"><xsl:call-template name="href"/></xsl:attribute>
      <xsl:value-of select="edt:page-libelle(edt:tome-page(normalize-space(@n)))"/>
    </a>
  </xsl:template>

  <!-- 2026-10-19 : en-tête d'acte. Un <head> qui ne fait que répéter le numéro de l'acte (« I », NDPA-EG, HDPAR-HD :
       2 619 actes) n'est pas répété sous le numéro. -->
  <xsl:template match="tei:text[@n]/tei:front/tei:head[replace(normalize-space(.), '[\s.]', '') = replace(normalize-space(../../@n), '[\s.]', '')]" priority="16" version="3.0"/>
  <!-- 2026-10-19 : date d'acte, lieu et date qui se suivent sans ponctuation (« Compiègne5 mai 877 », « octobre 1245Maubuisson ») :
       une virgule entre les deux ; une ponctuation déjà présente est gardée. -->
  <xsl:template priority="16" version="3.0" match="tei:front/tei:docDate/*[self::tei:date or self::tei:placeName or self::tei:name]
      [following-sibling::*[1][self::tei:date or self::tei:placeName or self::tei:name]]
      [not(following-sibling::node()[1][self::text()][normalize-space()])]">
    <xsl:next-match/>
    <!-- « 21 avril. Paris » : déjà ponctué, une espace seulement -->
    <xsl:if test="not(matches(normalize-space(.), '[.,;:]$'))"><xsl:text>,</xsl:text></xsl:if>
    <xsl:text> </xsl:text>
  </xsl:template>

  <!-- 2026-10-19 : bloc de présentation ou signature vides (<p><!- - TODO - -></p>, SAPC-AB, SMPA-AB-03, SMMI-AB…) :
       rien, au lieu d'un cadre vide ; la page garde alors le sommaire de ses sous-parties (CSS). -->
  <xsl:template match="tei:front/tei:argument[not(normalize-space())] | tei:front/tei:byline[not(normalize-space())]" priority="16"/>

  <!-- 2026-10-19 : BIBLIOGRAPHIES NON ENCODÉES EN listBibl, passées au module commun (une ligne par
       référence) : une liste dont chaque item porte un <bibl> (NDCH-EG), et dans une page « Orientation
       bibliographique », « Bibliographie » ou « Sources imprimées », les paragraphes qui ont la forme d'une
       référence (nom d'auteur en tête, ou titre en italique ; SMMI-AB, STEP-AB, SLES-PR…). La prose reste
       de la prose. Les données ne changent pas : le listBibl est fabriqué à la volée. -->
  <xsl:function name="cartu:page-biblio" as="xs:boolean" version="3.0" xmlns:cartu="urn:cartu">
    <xsl:param name="d" as="element()?"/>
    <xsl:sequence select="exists($d/tei:head[matches(normalize-space(.), 'bibliograph|sources imprim', 'i')]) and empty($d//tei:listBibl)"/>
  </xsl:function>
  <xsl:function name="cartu:p-reference" as="xs:boolean" version="3.0" xmlns:cartu="urn:cartu">
    <xsl:param name="p" as="element()"/>
    <xsl:variable name="t" select="normalize-space($p)"/>
    <xsl:sequence select="matches($t, '^([A-ZÉÈ][\w’''\-]+( [A-ZÉ][\w’''\-]+)? \(|[A-ZÉ]{3,}|[A-ZÉ][a-zé]+ [A-ZÉ][\w’''\-]+,|[A-Z]\.(-[A-Z]\.)? [A-ZÉ]{2,})')
                          or exists($p/node()[self::* or normalize-space()][1][self::tei:hi[@rend = ('i', 'italic')]])"/>
  </xsl:function>
  <xsl:template match="tei:list[tei:item][every $i in tei:item satisfies exists($i/tei:bibl)]" priority="15" version="3.0">
    <xsl:variable name="lb"><tei:listBibl><xsl:copy-of select="tei:item/tei:bibl"/></tei:listBibl></xsl:variable>
    <xsl:apply-templates select="$lb/tei:listBibl"/>
  </xsl:template>
  <xsl:template match="tei:p[cartu:page-biblio(..)][cartu:p-reference(.)]" priority="15" version="3.0" xmlns:cartu="urn:cartu">
    <!-- première référence d'une suite : toute la suite en une liste ; les suivantes sont déjà rendues -->
    <xsl:if test="not(preceding-sibling::*[not(self::tei:pb)][1][self::tei:p][cartu:p-reference(.)])">
      <xsl:variable name="fin" select="following-sibling::*[not(self::tei:pb)][not(self::tei:p and cartu:p-reference(.))][1]"/>
      <xsl:variable name="run" select="(., following-sibling::tei:p[cartu:p-reference(.)][empty($fin) or . &lt;&lt; $fin])"/>
      <xsl:variable name="lb"><tei:listBibl><xsl:for-each select="$run"><tei:bibl><xsl:copy-of select="node()"/></tei:bibl></xsl:for-each></tei:listBibl></xsl:variable>
      <xsl:apply-templates select="$lb/tei:listBibl"/>
    </xsl:if>
  </xsl:template>

  <!-- 2026-10-06 : index, description de l'entrée repliée. La ligne garde la vedette et les
       numéros d'actes ; la description (identification du lieu, de la personne) s'ouvre par
       une pastille « + » en fin de ligne, comme les occurrences du glossaire de Montferrand.
       Le contenu reste rendu par hteiml (apply-imports : div.desc).
       Servie en excludeFragments=true (forme demandée par le front), la page de lettre perd
       son <list> : les <item> sont alors enfants directs du dts:wrapper. -->
  <xsl:template match="tei:item[parent::tei:list[@type = 'index'] or parent::*[local-name() = 'wrapper']]/tei:desc" priority="20">
    <!-- 2026-10-07 : plus de pastille « + » (« overkill ») : la description s'affiche directement,
         à sa place, sous la ligne de l'entrée. -->
    <div class="cartu-desc"><xsl:apply-imports/></div>
  </xsl:template>
  <!-- 2026-10-06 : index, changements de page (pb, vignette Gallica) tombant DANS une
       entrée (après un numéro d'acte, dans la description) : la vignette sortait au milieu
       de la ligne, ou disparaissait avec la description repliée. Tous les pb de l'entrée
       sont remontés en tête (CSS : une ligne à eux, au-dessus du mot) ; le blanc qu'ils
       laissaient avant la ponctuation (« 363 . ») est retiré. -->
  <!-- 2026-10-06 : toute entrée d'index (et toute sous-entrée d'une sous-liste « - », « o », « 1 »)
       passe par ce modèle : repères de page en tête (ci-dessous), puis le contenu. -->
  <xsl:template match="tei:item[parent::tei:list[@type = 'index'] or parent::*[local-name() = 'wrapper'] or parent::tei:list[@type = ('-', 'o', '1')][ancestor::tei:item]]" priority="20" version="3.0">
    <li>
      <xsl:call-template name="atts"/>
      <!-- 2026-10-06 : saut de page posé ENTRE deux entrées (SMPA-AB-02 : </item><pb/><item>) :
           il sortait en vignette au milieu de la liste, un trou de 53 px et un retour à la
           ligne. Il est rattaché à l'entrée qui suit, comme ceux qui sont dedans. -->
      <xsl:variable name="pb-avant" select="preceding-sibling::tei:pb[following-sibling::tei:item[1] is current()]"/>
      <xsl:apply-templates select="$pb-avant | .//tei:pb">
        <xsl:with-param name="pb-en-tete" tunnel="yes" select="true()"/>
      </xsl:apply-templates>
      <!-- 2026-10-06 : repères de page sans image Gallica (fac-similé local ou absent :
           SMPA-AB, HDPAR, SAPC, SCOR, SSCO, SLES, 513 entrées). Ils sortaient en
           « {p. 823} » collé devant le mot, parfois en série (« {p. 614}{p. 615}…{p. 622} »).
           Une seule étiquette discrète, placée dans la marge par la CSS : « p. 823 »,
           « p. 614–622 ». -->
      <!-- Vignettes : Gallica seulement (DoTS-vue n'en fait que pour Gallica ; les images
           d'archive.org de HDPAR-HD restaient en « {p. 570} »). Ailleurs, l'étiquette mène à
           l'image du premier repère quand il en a une (adresse http). -->
      <xsl:variable name="pbs" select="($pb-avant | .//tei:pb)[not(contains(@facs, 'gallica.bnf.fr'))][normalize-space(@n)]"/>
      <xsl:variable name="pages" select="$pbs/normalize-space(@n)"/>
      <xsl:if test="exists($pages)">
        <xsl:variable name="etiquette" select="concat('p.&#160;', $pages[1], if (count($pages) > 1) then concat('–', $pages[last()]) else '')"/>
        <xsl:choose>
          <xsl:when test="starts-with($pbs[1]/@facs, 'http')">
            <a class="cartu-pb-marge" href="{$pbs[1]/@facs}" target="_blank" rel="noopener" title="Page de l’index imprimé">
              <xsl:value-of select="$etiquette"/>
            </a>
          </xsl:when>
          <xsl:otherwise><span class="cartu-pb-marge"><xsl:value-of select="$etiquette"/></span></xsl:otherwise>
        </xsl:choose>
      </xsl:if>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  <!-- 2026-10-08 : ressources dont l'index tient sur une seule page, lettres repliables (seuil :
       jusqu'à SLES-PR, 1 341 entrées). Les entrées restent des lignes, numéros d'actes visibles
       (fiches par entrée essayées puis retirées : « pas besoin de devoir déplier »). -->
  <!-- 2026-10-19 : retour à une page par lettre (comme les autres cartulaires) pour SCHA, SLES, SGGO, SSCO, NDMA,
       dont les lettres sont des unités du sommaire (index-complet n'est plus éditable dans la conf) ; restent
       sur une page les index dont les lettres ne sont pas des unités. -->
  <!-- 2026-10-20 : STEP, NDRC, NDPR, NDMT aussi (lettres devenues unités dans le TEI) : plus aucun index sur une page,
       tous les cartulaires ont une page par lettre (uniformisation demandée par Maxime). -->
  <!-- renvois « voir » : ressources dont les lettres sont des unités citables sous UNE unité
       index-complet, et cette unité (même ordre). Ailleurs le renvoi garde sa cible : soit la page
       est déjà entière (STEP, NDRC, NDPR, NDMT), soit le front redirige la lettre vers sa page
       d'index (SGGO, deux index). -->
  <xsl:variable name="cartu-renvoi-res" select="()" as="xs:string*"/>  <!-- 2026-10-19 : vide, les renvois visent leur lettre (@corresp) -->
  <xsl:variable name="cartu-index-unite" select="()" as="xs:string*"/>
  <!-- 2026-10-28 (Maxime, SMPA-EG_index : « l'index des noms, faut pas charger tout, juste la toc de dots-vue
       avec a b c d s'il y a pas de texte et pas d'autres index ; pour l'intégralité des cartulaires ») : une
       lettre qui est une unité citable (list d'index avec head et xml:id) ne s'affiche que sur SA page, où elle
       est enfant direct du dts:wrapper. Sur la page de l'index (citeType « partie », que le front demande
       entière : editByCiteType), il ne reste que le titre et le texte éventuel ; les lettres sont au sommaire. -->
  <xsl:template match="tei:list[@type = 'index'][tei:head][@xml:id][not(ancestor::tei:item)][not(parent::*[local-name() = 'wrapper'])]" priority="60"/>
  <xsl:template match="tei:list[@type = 'index'][tei:head][@xml:id][not(ancestor::tei:item)][not(parent::*[local-name() = 'wrapper'])]" mode="fn" priority="60"/>
  <!-- note d'une lettre masquée : hors du pied de page (document entier, notes rassemblées par page : footnotes) -->
  <xsl:function name="cartu:lettre-cachee" as="xs:boolean" version="3.0">
    <xsl:param name="n" as="element()"/>
    <xsl:sequence select="exists($n/ancestor::tei:list[@type = 'index'][tei:head][@xml:id][not(ancestor::tei:item)][not(parent::*[local-name() = 'wrapper'])])"/>
  </xsl:function>
  <xsl:template match="tei:item//tei:pb | tei:pb[following-sibling::tei:item][parent::tei:list[@type = 'index'] or parent::*[local-name() = 'wrapper']]" priority="30" version="3.0">
    <xsl:param name="pb-en-tete" tunnel="yes" select="false()"/>
    <xsl:if test="$pb-en-tete and contains(@facs, 'gallica.bnf.fr')"><xsl:next-match/></xsl:if>
  </xsl:template>

  <!-- 2026-10-06 : index, typographie française. Espace insécable avant ; : ? ! (le texte
       de l'index imprimé, converti, n'en a pas : « Campus-Faunus; Campus-Folii »).
       À l'affichage seulement ; le TEI n'est pas touché. -->
  <xsl:template match="tei:item[parent::tei:list[@type = 'index'] or parent::*[local-name() = 'wrapper']]//text()" priority="25">
    <!-- Blanc final ôté quand le texte suivant (par-delà les commentaires de la conversion)
         commence par une ponctuation : « Jehan Berte <!-\- doublon -\-> ; » donnait « Berte  ; ». -->
    <!-- Le texte suivant, dans l'ordre du document et dans la même entrée : le blanc peut être
         au bout d'un élément (« <hi>Abbaye du Loir </hi>; »). -->
    <xsl:variable name="entree" select="ancestor::tei:item[1]"/>
    <xsl:variable name="suivi" select="exists((following::text()[normalize-space()])[1][ancestor::tei:item[1] is $entree][matches(., '^\s*[;:,.]')])"/>
    <xsl:if test="not($suivi and normalize-space(.) = '')">
      <xsl:call-template name="cartu-insecables"><xsl:with-param name="t" select="if ($suivi) then replace(., '\s+$', '') else string(.)"/></xsl:call-template>
    </xsl:if>
  </xsl:template>
  <!-- 2026-10-06 : <x> est un reste de la conversion, étranger au TEI (98 dans SMPA-AB-03, dans les
       actes comme dans l'index) : le HTEIML, qui ne le connaît pas, l'affichait avec ses balises
       (« <x>voir</x> », « Brice (De Ployart<x>)</x> »). Le contenu compte, la balise non. -->
  <xsl:template match="tei:x" priority="10"><xsl:apply-templates/></xsl:template>

  <!-- 2026-10-06 : « note N » et « n. dors. » de l'index (SMPA-AB-03 : 2 494 et 392 renvois).
       Le livre numérote ses notes PAR PAGE, tous actes confondus : « 278, note 3 », c'est la
       3e note chiffrée de la page 625, que le TEI appelle 278_7 et que l'acte affiche « 7 »
       (numérotation suivie, voir note-n). « n. dors. » : la mention portée au dos de l'acte,
       paragraphes « Au dos, d'une main… » (ancre cartu-dos, plus bas).
       - L'acte : le renvoi (ref) qui précède, ou, s'il n'y en a pas, celui que la conversion a mis
         en commentaire (« doublon meme acte »).
       - La page : le @n « acte-page » du renvoi ou de son commentaire (« 278-625 »). Si elle
         manque ou ne colle pas, la seule page de l'acte où la note N est bien dans cet acte.
       - Sinon (ambigu, ou aucun acte) : le texte reste tel quel.
       Un seul lien : « 278, note 7 » mène à la note (le numéro d'acte seul n'apprend rien de
       plus) ; la précision qui suit le même renvoi (« note 3, note 1 ») a son propre lien.
       L'index ne voit pas les actes : on lit le cartulaire entier, comme Montferrand
       (montferrand.xml) — posé à côté de la feuille une fois déployé, ../data/ dans le dépôt.
       Pas l'API : interblocage (voir comptes.xsl). -->
  <xsl:variable name="cartu-tome" version="3.0"
    select="if ($resource = '') then () else document((for $u in (concat($resource, '.xml'),
              concat('../data/', replace($resource, '-\d+$', ''), '/', $resource, '.xml'),
              concat('../data/', $resource, '.xml'))
            return resolve-uri($u, static-base-uri()))[doc-available(.)][1])"/>
  <!-- notes chiffrées (« acte_N ») par page imprimée, dans l'ordre du livre -->
  <xsl:key name="cartu-note-page" version="3.0"
    match="tei:note[matches(normalize-space(@n), '^[^_\s]+_\d+$')]"
    use="string(preceding::tei:pb[1]/@n)"/>

  <!-- précision de l'index : « note N » ou « n. dors. » -->
  <xsl:function name="cartu:precision" as="xs:boolean" version="3.0"
    xmlns:cartu="urn:cartu" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="e" as="node()?"/>
    <xsl:sequence select="exists($e[self::tei:hi[@rend = 'i'][matches(normalize-space(.), '^(note\s+\d+|n\.\s*dors\.)$')][ancestor::tei:item]])"/>
  </xsl:function>

  <!-- l'élément visé dans le tome (tei:note, ou tei:p « Au dos ») et son acte -->
  <xsl:function name="cartu:cible" as="element()*" version="3.0"
    xmlns:cartu="urn:cartu" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="hi" as="element()"/>
    <xsl:variable name="borne" select="$hi/preceding-sibling::*[not(cartu:precision(.))][1]"/>
    <xsl:variable name="ref" select="$borne[self::tei:ref[@target]]"/>
    <!-- commentaires entre la borne et la précision, le plus proche d'abord ; leurs <ref …> -->
    <xsl:variable name="refs-com" as="xs:string*"
      select="for $c in reverse($hi/preceding-sibling::comment()[empty($borne) or . &gt;&gt; $borne])
              return (for $r in tokenize(string($c), '&lt;ref ')[position() gt 1]
                      return substring-before(concat($r, '&gt;'), '&gt;'))"/>
    <xsl:variable name="cible-com" select="($refs-com[contains(., 'target=&quot;#')][matches(., 'n=&quot;')]
        [empty($ref) or contains(., concat('target=&quot;', $ref/@target, '&quot;'))])[1]"/>
    <!-- 2026-10-07 : l'acte vient d'un VRAI renvoi, jamais d'un commentaire « doublon » (le
         renvoi mis en commentaire peut désigner le mauvais acte : 13 cas prouvés, D1). Les
         commentaires ne servent plus qu'à lire la page imprimée du même acte. -->
    <xsl:variable name="acte" select="if ($ref) then substring-after($ref/@target, '#') else ''"/>
    <xsl:variable name="n-ref" select="if (matches($ref/@n, '^\d+-\S+$')) then string($ref/@n)
        else replace($cible-com, '^.*n=&quot;([^&quot;]+)&quot;.*$', '$1', 's')"/>
    <xsl:variable name="page" select="if (contains($n-ref, '-')) then substring-after($n-ref, '-') else ''"/>
    <xsl:variable name="texte-acte" select="if (exists($cartu-tome) and $acte != '') then id($acte, $cartu-tome) else ()"/>
    <xsl:variable name="brut" as="element()*">
    <xsl:choose>
      <xsl:when test="empty($texte-acte)"/>
      <xsl:when test="starts-with(normalize-space($hi), 'n.')">
        <xsl:sequence select="($texte-acte//tei:p[starts-with(normalize-space(tei:hi[1]), 'Au dos')])[1]"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="n" select="xs:integer(replace(normalize-space($hi), '\D', ''))"/>
        <xsl:variable name="sur-la-page" select="key('cartu-note-page', $page, $cartu-tome)[$n]"/>
        <xsl:choose>
          <xsl:when test="$page != '' and $sur-la-page/ancestor::tei:text[@xml:id][1]/@xml:id = $acte">
            <xsl:sequence select="$sur-la-page"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="dans-l-acte" select="$texte-acte//tei:note[matches(normalize-space(@n), '^[^_\s]+_\d+$')]"/>
            <xsl:variable name="candidates" select="for $p in distinct-values($dans-l-acte/string(preceding::tei:pb[1]/@n))
                return key('cartu-note-page', $p, $cartu-tome)[$n][ancestor::tei:text[@xml:id][1]/@xml:id = $acte]"/>
            <xsl:sequence select="if (count($candidates) = 1) then $candidates else ()"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
    </xsl:variable>
    <!-- 2026-10-07 : on ne lie que si la cible nomme l'entrée (un nom de la vedette ou de la
         sous-entrée qui porte la précision) ; sinon pas de lien vers la note : le numéro d'acte
         garde son lien vers l'acte, « note N » reste du texte, comme dans le livre. Sur SMPA-AB-03,
         ~150 liens sur ~1 900 visaient une note qui ne nomme pas l'entrée. -->
    <xsl:sequence select="$brut[cartu:nomme(., $hi)]"/>
  </xsl:function>

  <!-- texte aplati : minuscules, sans accents, apostrophes en blancs -->
  <xsl:function name="cartu:plat" as="xs:string" version="3.0"
    xmlns:cartu="urn:cartu" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="s" as="xs:string?"/>
    <xsl:sequence select="replace(replace(normalize-unicode(lower-case(string($s)), 'NFD'), '\p{Mn}', ''), '[’'']', ' ')"/>
  </xsl:function>
  <!-- la cible (note, ou mention au dos et ses paragraphes suivants) nomme-t-elle l'entrée ?
       Noms = mots à majuscule de 4 lettres et plus de la vedette et de la sous-entrée, comparés
       sur leurs 5 premières lettres (graphies : Jehanne / Jeanne). -->
  <xsl:function name="cartu:nomme" as="xs:boolean" version="3.0"
    xmlns:cartu="urn:cartu" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="c" as="element()"/>
    <xsl:param name="hi" as="element()"/>
    <xsl:variable name="item" select="$hi/ancestor::tei:item[1]"/>
    <xsl:variable name="vedette" select="string(($item/tei:rs, $item/node())[1])"/>
    <xsl:variable name="avant" select="string-join($hi/preceding-sibling::node()[not(self::comment())] ! string(.), '')"/>
    <xsl:variable name="sous" select="tokenize($avant, ';[\s&#160;]*—')[last()]"/>
    <xsl:variable name="vides" select="('saint', 'sainte', 'notre', 'paris', 'eglise', 'famille', 'voir', 'note', 'femme', 'veuve', 'fille', 'frere')"/>
    <xsl:variable name="mots" select="distinct-values(
        for $w in tokenize(concat($vedette, ' ', $sous), '[^\p{L}]+')[matches(., '^\p{Lu}')][string-length(.) ge 4]
        return substring(cartu:plat($w), 1, 5))[not(. = $vides)]"/>
    <xsl:variable name="texte" select="cartu:plat(string-join(($c, $c[self::tei:p]/following-sibling::tei:p) ! string(.), ' '))"/>
    <xsl:sequence select="some $m in $mots satisfies matches($texte, concat('(^|[^\p{L}])', $m))"/>
  </xsl:function>

  <!-- la précision qui suit immédiatement un renvoi visible (« 278, note 3 ») et qui se
       résout : le renvoi et elle ne font plus qu'un lien -->
  <xsl:function name="cartu:fondue" as="xs:boolean" version="3.0"
    xmlns:cartu="urn:cartu" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="hi" as="element()?"/>
    <xsl:sequence select="cartu:precision($hi)
      and exists($hi/preceding-sibling::*[1][self::tei:ref[@target]])
      and (every $t in $hi/preceding-sibling::text()[. &gt;&gt; $hi/preceding-sibling::*[1]] satisfies matches($t, '^[\s,]*$'))
      and exists(cartu:cible($hi))"/>
  </xsl:function>

  <xsl:template name="cartu-lien-precision" version="3.0" xmlns:cartu="urn:cartu" exclude-result-prefixes="cartu">
    <xsl:param name="hi" as="element()"/>
    <xsl:param name="numero" as="item()*"/>
    <xsl:variable name="c" select="cartu:cible($hi)"/>
    <xsl:variable name="texte-acte" select="$c/ancestor::tei:text[@xml:id][1]"/>
    <xsl:variable name="dos" select="exists($c/self::tei:p)"/>
    <!-- 2026-10-28 : numéro affiché dans l'acte = rang de la note chiffrée dans l'acte (pied de page : 1 à n,
         lettres à part, notes répétées comptées une fois), et non plus note-n -->
    <xsl:variable name="numero-en-ligne" select="if ($c[self::tei:note]) then 1 + count($c/preceding::tei:note[ancestor::tei:text[@xml:id][1] is $texte-acte][matches(normalize-space(@n), '^[^_\s]+_\d+$')][empty(cartu:note-premiere(.))]) else ''"/>
    <a class="cartu-renvoi{if ($dos) then ' cartu-renvoi-dos' else ' cartu-renvoi-note'}"
       href="{concat($document-base, $resource, '?refId=', $texte-acte/@xml:id, '#',
              if ($dos) then 'au-dos' else concat('note', normalize-space($c/@n)))}"
       title="{if ($dos) then concat('Acte ', $texte-acte/@n, ' : note dorsale (mention au dos de l’acte)')
               else concat('Acte ', $texte-acte/@n, ' — dans le livre : page ', $c/preceding::tei:pb[1]/@n, ', note ',
                 replace(normalize-space($hi), '\D', ''), ' (notes numérotées par page) ; ici : note ', $numero-en-ligne)}">
      <xsl:if test="exists($numero)">
        <span class="cartu-renvoi-acte"><xsl:sequence select="$numero"/></span>
        <xsl:text> </xsl:text>
      </xsl:if>
      <span class="cartu-renvoi-precision">
        <xsl:choose>
          <xsl:when test="$dos"><xsl:value-of select="normalize-space($hi)"/></xsl:when>
          <xsl:otherwise>
            <xsl:text>note&#160;</xsl:text>
            <xsl:value-of select="$numero-en-ligne"/>
          </xsl:otherwise>
        </xsl:choose>
      </span>
    </a>
  </xsl:template>

  <!-- renvoi suivi de sa précision : un seul lien -->
  <xsl:template match="tei:ref[@target][ancestor::tei:item][cartu:fondue(following-sibling::*[1])]"
    priority="30" version="3.0" xmlns:cartu="urn:cartu">
    <xsl:call-template name="cartu-lien-precision">
      <xsl:with-param name="hi" select="following-sibling::*[1]"/>
      <xsl:with-param name="numero"><xsl:apply-templates/></xsl:with-param>
    </xsl:call-template>
  </xsl:template>
  <!-- la virgule entre les deux disparaît avec eux -->
  <xsl:template match="text()[ancestor::tei:item][matches(., '^[\s,]*$')][preceding-sibling::*[1][self::tei:ref[@target]]][cartu:fondue(following-sibling::*[1])]"
    priority="30" version="3.0" xmlns:cartu="urn:cartu"/>
  <xsl:template match="tei:hi[cartu:precision(.)]" priority="26" version="3.0" xmlns:cartu="urn:cartu">
    <xsl:choose>
      <xsl:when test="cartu:fondue(.)"/>
      <xsl:when test="exists(cartu:cible(.))">
        <!-- sans renvoi visible devant (il n'existe qu'en commentaire, « doublon meme acte »),
             le lien porte le numéro de l'acte : « au dos » seul ne dirait pas où il mène -->
        <xsl:call-template name="cartu-lien-precision">
          <xsl:with-param name="hi" select="."/>
          <xsl:with-param name="numero" select="if (preceding-sibling::*[not(cartu:precision(.))][1][self::tei:ref[@target]]) then ()
              else string(cartu:cible(.)[1]/ancestor::tei:text[@xml:id][1]/@n)"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise><xsl:next-match/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- 2026-10-06 : renvois internes des notes d'actes (Saint-Magloire) : « voir plus haut, n° 153,
       p. 348, n. 6 », « n° 230, p. 509 ». Texte brut dans le TEI. Lien vers la note (la Z-ième
       note chiffrée de la page Y, comme pour l'index) ou, sans « n. Z » ou si la note ne se
       retrouve pas, vers l'acte. Un renvoi n'est lié que si l'acte X de CE tome couvre la page Y :
       les références bibliographiques (« Tuetey, n° 90, p. 6 », « op. cit., t. 2, n° 304,
       p. 444 ») restent du texte. SMPA-AB-03 : 140 notes + 427 actes ; SMPA-AB-01 : 179 actes. -->
  <xsl:key name="cartu-acte-n" match="tei:text[@xml:id][@n]" use="string(@n)" version="3.0"/>
  <xsl:variable name="cartu-renvoi-rx" select="'n°[\s&#160;]*(\d+)[\s&#160;]*,[\s&#160;]*pp?\.[\s&#160;]*(\d+)([\s&#160;]*[-–][\s&#160;]*\d+)?([\s&#160;]*,[\s&#160;]*n\.[\s&#160;]*(\d+))?'" version="3.0"/>
  <xsl:template match="text()[ancestor::tei:note][not(ancestor::tei:item)][matches(., 'n°[\s&#160;]*\d+[\s&#160;]*,[\s&#160;]*pp?\.[\s&#160;]*\d+')]" priority="22" version="3.0">
    <xsl:choose>
      <xsl:when test="empty($cartu-tome)"><xsl:value-of select="."/></xsl:when>
      <xsl:otherwise>
        <xsl:analyze-string select="." regex="{$cartu-renvoi-rx}">
          <xsl:matching-substring>
            <xsl:variable name="x" select="regex-group(1)"/>
            <xsl:variable name="y" select="regex-group(2)"/>
            <xsl:variable name="z" select="regex-group(5)"/>
            <xsl:variable name="acte" select="key('cartu-acte-n', $x, $cartu-tome)[1]"/>
            <xsl:variable name="pages" select="($acte/preceding::tei:pb[1]/@n, $acte//tei:pb/@n) ! string(.)"/>
            <xsl:choose>
              <xsl:when test="exists($acte) and $y = $pages">
                <xsl:variable name="note" select="if ($z != '') then key('cartu-note-page', $y, $cartu-tome)[xs:integer($z)][ancestor::tei:text[@xml:id][1] is $acte] else ()"
                  xmlns:xs="http://www.w3.org/2001/XMLSchema"/>
                <xsl:variable name="numero-en-ligne"><xsl:for-each select="$note"><xsl:call-template name="note-n"/></xsl:for-each></xsl:variable>
                <a class="cartu-renvoi-interne"
                   href="{concat($document-base, $resource, '?refId=', $acte/@xml:id, if ($note) then concat('#note', normalize-space($note/@n)) else '')}"
                   title="{if ($note) then concat('Acte ', $x, ' — dans le livre : page ', $y, ', note ', $z, ' (notes numérotées par page) ; ici : note ', $numero-en-ligne)
                           else concat('Acte ', $x)}">
                  <xsl:value-of select="."/>
                </a>
              </xsl:when>
              <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
            </xsl:choose>
          </xsl:matching-substring>
          <xsl:non-matching-substring><xsl:value-of select="."/></xsl:non-matching-substring>
        </xsl:analyze-string>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- 2026-10-06 : défauts de conversion des index (SMPA-AB-02 surtout), corrigés à l'affichage.
       1. Vedette collée à sa parenthèse : « Adam(Adam, Adan) », « Agathe(Agate) » (104). -->
  <xsl:template match="tei:item//text()[starts-with(., '(')][preceding-sibling::node()[1][self::tei:hi]]" priority="27" version="3.0">
    <xsl:text> </xsl:text>
    <xsl:next-match/>
  </xsl:template>
  <!-- 2. Point final pris dans le renvoi : « voir Lorteil. » soulignait le point avec le nom (729).
       Le point sort du lien. -->
  <xsl:template match="tei:ref[@type = 'see'][ancestor::tei:item][ends-with(normalize-space(.), '.')][not(following-sibling::node()[1][self::text()][matches(., '^[\s&#160;]*\.')])]" priority="27" version="3.0">
    <xsl:next-match/>
    <xsl:text>.</xsl:text>
  </xsl:template>
  <xsl:template match="tei:ref[@type = 'see'][ancestor::tei:item]//text()[ends-with(normalize-space(.), '.')]
      [. is (ancestor::tei:ref[@type = 'see'][1]//text()[normalize-space()])[last()]]" priority="27" version="3.0">
    <xsl:value-of select="replace(., '\.[\s&#160;]*$', '')"/>
  </xsl:template>

  <!-- ================================================================
       2026-10-07 : censier de l'Hôtel-Dieu (HDPAR-HD), notes et exposants, SANS compagnon.
       La conversion n'a pas balisé les notes du censier : l'appel est un chiffre en exposant
       Unicode dans le texte (« contigua¹ »), la note un paragraphe en bas de page imprimée
       (« ¹ Cart. n° 857. — ² Ibid. n° 168. » ou « Notes : ¹ … ² … »). Dans l'entrée servie :
       - un paragraphe de notes devient des notes séparées, avec retour ; « n° 857 » mène à l'acte ;
       - un appel dont la note est dans la même entrée (le premier paragraphe de notes qui suit et
         porte ce chiffre) devient un lien vers elle ; sinon (note en bas de page, dans l'entrée
         voisine) il reste un simple exposant ;
       - « ° » après un chiffre romain ou arabe (IIII°, m° cc°) : un o en exposant.
       Le rattachement complet (appel → note de l'entrée voisine) relève du TEI. -->
  <xsl:variable name="cartu-exposants" select="'¹²³⁴⁵⁶⁷⁸⁹'" version="3.0"/>
  <xsl:function name="cartu:est-notes" as="xs:boolean" version="3.0" xmlns:cartu="urn:cartu" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="p" as="element()?"/>
    <xsl:sequence select="exists($p) and matches(normalize-space($p), '^(Notes\s*:\s*)?[¹²³⁴⁵⁶⁷⁸⁹]')"/>
  </xsl:function>

  <!-- texte : appels et ° -->
  <xsl:template match="tei:p[not(cartu:est-notes(.))]//text()[matches(., '[¹²³⁴⁵⁶⁷⁸⁹]|[ivxlcdmIVXLCDM0-9]°')][$resource = 'HDPAR-HD']" priority="28" version="3.0" xmlns:cartu="urn:cartu" exclude-result-prefixes="cartu">
    <xsl:variable name="p" select="ancestor::tei:p[1]"/>
    <xsl:analyze-string select="." regex="[¹²³⁴⁵⁶⁷⁸⁹]|(([ivxlcdmIVXLCDM0-9])°)">
      <xsl:matching-substring>
        <xsl:choose>
          <xsl:when test="regex-group(1) != ''"><xsl:value-of select="regex-group(2)"/><sup class="cartu-o">o</sup></xsl:when>
          <xsl:otherwise>
            <xsl:variable name="n" select="string(string-length(substring-before($cartu-exposants, .)) + 1)"/>
            <xsl:variable name="np" select="$p/following::tei:p[cartu:est-notes(.)][contains(., current())][1]"/>
            <xsl:choose>
              <xsl:when test="$np">
                <a class="noteref" href="#cn{generate-id($np)}-{$n}" id="cn{generate-id($np)}-{$n}_"><sup><xsl:value-of select="$n"/></sup></a>
              </xsl:when>
              <xsl:otherwise><sup class="cartu-appel"><xsl:value-of select="$n"/></sup></xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:matching-substring>
      <xsl:non-matching-substring><xsl:value-of select="."/></xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>

  <!-- paragraphe de notes : des notes séparées -->
  <xsl:template match="tei:p[cartu:est-notes(.)][$resource = 'HDPAR-HD']" priority="28" version="3.0" xmlns:cartu="urn:cartu" exclude-result-prefixes="cartu">
    <xsl:variable name="np" select="."/>
    <div class="cartu-notes-page">
      <xsl:analyze-string select="replace(normalize-space(.), '^Notes\s*:\s*', '')" regex="([¹²³⁴⁵⁶⁷⁸⁹])\s*([^¹²³⁴⁵⁶⁷⁸⁹]*)">
        <xsl:matching-substring>
          <xsl:variable name="n" select="string(string-length(substring-before($cartu-exposants, regex-group(1))) + 1)"/>
          <!-- l'appel est-il dans cette entrée ? (un paragraphe qui précède et porte ce chiffre,
               dont ce paragraphe de notes est le premier à le porter ensuite) -->
          <xsl:variable name="appel" select="$np/preceding::tei:p[not(cartu:est-notes(.))][contains(., regex-group(1))][following::tei:p[cartu:est-notes(.)][contains(., regex-group(1))][1] is $np][1]"/>
          <div class="note" id="cn{generate-id($np)}-{$n}">
            <xsl:choose>
              <xsl:when test="$appel"><a class="noteback" href="#cn{generate-id($np)}-{$n}_"><xsl:value-of select="$n"/>. </a></xsl:when>
              <xsl:otherwise><span class="noteback"><xsl:value-of select="$n"/>. </span></xsl:otherwise>
            </xsl:choose>
            <!-- « n° 857, 860 » : chaque numéro mène à l'acte du cartulaire -->
            <xsl:analyze-string select="replace(regex-group(2), '\s*—\s*$', '')" regex="(n°\s*)((\d+)(\s*,\s*\d+)*)">
              <xsl:matching-substring>
                <xsl:value-of select="regex-group(1)"/>
                <xsl:analyze-string select="regex-group(2)" regex="\d+">
                  <xsl:matching-substring>
                    <a href="{concat($document-base, 'HDPAR-HD?refId=HDPAR-HD_', format-number(number(.), '0000'))}"><xsl:value-of select="."/></a>
                  </xsl:matching-substring>
                  <xsl:non-matching-substring><xsl:value-of select="."/></xsl:non-matching-substring>
                </xsl:analyze-string>
              </xsl:matching-substring>
              <xsl:non-matching-substring><xsl:value-of select="."/></xsl:non-matching-substring>
            </xsl:analyze-string>
          </div>
        </xsl:matching-substring>
      </xsl:analyze-string>
    </div>
  </xsl:template>

  <!-- acte : ancre de la mention au dos (premier paragraphe « Au dos… »), cible des « n. dors. » -->
  <xsl:template match="tei:p[starts-with(normalize-space(tei:hi[1]), 'Au dos')]
      [not(preceding::tei:p[starts-with(normalize-space(tei:hi[1]), 'Au dos')]
        [ancestor::*[self::tei:text[@xml:id] or local-name() = 'wrapper'][1] is current()/ancestor::*[self::tei:text[@xml:id] or local-name() = 'wrapper'][1]])]"
    priority="20" version="3.0">
    <!-- id simple : la page d'un acte n'en montre qu'un (dans le fragment servi, l'acte n'a plus
         son tei:text, donc plus son xml:id) -->
    <div class="cartu-dos" id="au-dos">
      <xsl:next-match/>
    </div>
  </xsl:template>

  <!-- 2026-10-06 (suite) : espacements de l'index converti, toujours à l'affichage seulement.
       1. une espace ordinaire collée à une insécable est fondue avec elle (« Campi  : ») ;
       2. « ( ?) » devient « (?) » ;
       3. pas de blanc avant une virgule ou un point (« 376 , 36 », « hybemagium . »), sauf
          devant des points de suspension (« Braya (..... de) ») ; XPath n'a pas de regard en
          avant, d'où le caractère suivant capturé ;
       4. typographie française (insécable avant ; : ? !) ;
       5. une sous-entrée par ligne : « ; — » devient « ; », un retour à la ligne, « — » ; la
          CSS met les lignes suivantes en retrait (« Berte (famille) … ; — (Florent) … »). Les
          « . — » de HDPAR-HD, qui séparent des formes du nom, restent sur la ligne. -->
  <xsl:template name="cartu-insecables" version="3.0">
    <xsl:param name="t"/>
    <xsl:variable name="e1" select="replace($t, '[ \t\r\n]*&#160;[ \t\r\n]*', '&#160;')"/>
    <xsl:variable name="e2" select="replace($e1, '\([\s&#160;]*\?[\s&#160;]*\)', '(?)')"/>
    <xsl:variable name="e3" select="replace(replace(replace(replace($e2, '([^\s&#160;])\s+,', '$1,'), '^\s+,', ','), '^[\s&#160;]+\.([^.]|$)', '.$1'), '([^\s&#160;.])\s+\.([^.]|$)', '$1.$2')"/>
    <xsl:variable name="e4" select="replace(replace($e3, '^\s*([;:?!])', '&#160;$1'), '([^\s&#160;(])\s*([;:?!])', '$1&#160;$2')"/>
    <xsl:analyze-string select="$e4" regex=";[\s&#160;]*—">
      <xsl:matching-substring><xsl:text>;</xsl:text><br class="cartu-sous"/><xsl:text>—</xsl:text></xsl:matching-substring>
      <xsl:non-matching-substring><xsl:value-of select="."/></xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>

  <!-- 2026-10-06 : index, séparateur entre deux numéros d'actes. L'index imprimé mettait
       « , » dans un même tome et « ; » au changement de tome (I. 170 ; II. 245) ; on n'affiche
       que le numéro d'acte, sans le tome : le « ; » paraissait arbitraire. Toujours « , » ici
       (le TEI garde « ; » et le tome dans ref/@n). Le « ; » entre les formes du nom reste. -->
  <!-- 2026-10-07 : sauf quand le « ; » sépare deux tomes (index de NDPA-EG-04 : « I, 249 ; III, 71 ») -->
  <xsl:template match="tei:item/text()[normalize-space(.) = ';'][preceding-sibling::*[1][self::tei:ref]][following-sibling::*[1][self::tei:ref]]
      [substring-before(substring-after(preceding-sibling::*[1]/@target, '#'), '_') = substring-before(substring-after(following-sibling::*[1]/@target, '#'), '_')]" priority="30">
    <xsl:text>, </xsl:text>
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

 <!-- Renvois dont la cible n'existe nulle part : rendus en TEXTE, pas en lien mort.
       Retablit le comportement du side-car cartulaires-refs.xml, supprime le
       2026-09-25, qui les laissait deliberement sans lien. Trois familles, toutes
       des sequelles de la conversion d'origine, 158 renvois au total :
         #NON_TROUVE                                      123  marqueur explicite
         #NDPA-EG-03_0365|_1095|_1096|_1722|_1723          28  numeros hors du tome 3 (635 unites)
         #page195|#page197|#page204|#page209                7  identifiants inexistants
       XSLT 1.0 : pas de sequence, on teste par concat/contains. -->
  <!-- 2026-10-07 : « voir » à plusieurs cibles (SMPA-AB-01 : 113, target="#a #b …", sans
       @corresp). Le lien unique était cassé (« ?refId=#…_rs_1370 #…_rs_2504 ») et couvrait toute
       la liste. Un lien par nom, vers LA cible dont la vedette porte ce nom ; s'il y a un doute
       (homonymes : « Simon » → 7 entrées) ou aucune cible, le nom reste du texte. La page d'index de la cible (refId) est sa
       liste, lue dans le tome (cartu-tome). -->
  <xsl:template match="tei:ref[@type = 'see'][normalize-space(@target)][contains(normalize-space(@target), ' ') or not(@corresp)][exists($cartu-tome)]" priority="31" version="3.0" xmlns:cartu="urn:cartu" exclude-result-prefixes="cartu">
    <xsl:variable name="cibles" select="for $t in tokenize(normalize-space(@target), ' ') return id(substring-after($t, '#'), $cartu-tome)"/>
    <xsl:variable name="texte" select="normalize-space(string(.))"/>
    <xsl:variable name="voir" select="if (matches($texte, '^[Vv]oir( aussi)?')) then replace($texte, '^([Vv]oir( aussi)?).*$', '$1', 's') else ''"/>
    <xsl:variable name="noms" select="tokenize(replace(substring($texte, string-length($voir) + 1), '^[\s:]+|[\s.]+$', ''), '\s*,\s*')[. != '']"/>
    <xsl:variable name="sc" select="exists(.//tei:hi[@rend = 'sc'])"/>
    <xsl:if test="$voir != ''">
      <i><xsl:value-of select="$voir"/></i>
      <xsl:text> </xsl:text>
    </xsl:if>
    <xsl:for-each select="$noms">
      <xsl:variable name="nom" select="."/>
      <!-- premier mot entier du nom (« saint-denis », pas « saint » : Saint-Denis et Saint-Laurent
           dans le même renvoi se confondraient) -->
      <xsl:variable name="cle" select="cartu:plat(tokenize($nom, '[\s(,]+')[. != ''][1])"/>
      <xsl:variable name="cle-rx" select="replace($cle, '([.\[\]()*+?^$|\\{}])', '\\$1')"/>
      <xsl:variable name="candidates" select="$cibles[matches(normalize-space(cartu:plat(string((tei:rs, .)[1]))), concat('^', $cle-rx, '([^\p{L}-]|$)'))]"/>
      <!-- une seule cible porte ce nom : lien ; plusieurs (homonymes) ou aucune : texte -->
      <xsl:variable name="cible" select="if (count($candidates) = 1) then $candidates else ()"/>
      <xsl:if test="position() gt 1"><xsl:text>, </xsl:text></xsl:if>
      <xsl:choose>
        <xsl:when test="$cible and $cle != ''">
          <!-- 2026-10-08 : la liste de LETTRE (la plus haute), pas une sous-liste rangée dans une entrée
               (SMPA-AB-01 : « IV. Personnel de l'Abbaye » dans l'entrée Saint-Magloire), qui n'est pas une page -->
          <xsl:variable name="liste" select="if ($resource = $cartu-listes-hors-nav) then cartu:unite-de($cible) else ($cible/ancestor::*[contains(@xml:id, '_liste')][not(ancestor::tei:item)])[last()]/@xml:id"/>
          <a href="{concat($document-base, $resource, '?refId=', $liste, '#', $cible/@xml:id)}">
            <xsl:choose>
              <xsl:when test="$sc"><span class="sc"><xsl:value-of select="$nom"/></span></xsl:when>
              <xsl:otherwise><xsl:value-of select="$nom"/></xsl:otherwise>
            </xsl:choose>
          </a>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="$nom"/></xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- 2026-10-07 : index de NDPA-EG-04 (cartulaire de Notre-Dame de Paris) : il renvoie aux
       quatre tomes (12 953 renvois vers les tomes 1-3). Le lien menait au bon tome, mais l'écran
       ne montrait que le numéro d'acte (« 336 ») : impossible de savoir dans quel tome. Le tome
       (celui que le lien ouvre, lu dans la cible : NDPA-EG-03 → III) précède le numéro quand il
       change dans l'entrée : « III, 336, 340 ; II, 605 ». -->
  <xsl:template match="tei:ref[@target][not(@type = 'see')][ancestor::tei:item][matches(@target, '^#NDPA-EG-0\d_')]" priority="29" version="3.0">
    <xsl:variable name="tome" select="substring(@target, 11, 1)"/>
    <xsl:variable name="avant" select="preceding-sibling::tei:ref[@target][not(@type = 'see')][1]"/>
    <xsl:if test="empty($avant) or substring($avant/@target, 11, 1) != $tome">
      <span class="cartu-tome">
        <xsl:value-of select="('I', 'II', 'III', 'IV')[xs:integer($tome)]" xmlns:xs="http://www.w3.org/2001/XMLSchema"/>
      </span>
      <xsl:text>, </xsl:text>
    </xsl:if>
    <xsl:next-match/>
  </xsl:template>

  <!-- 2026-10-07 : index de NDVC-AB (cartulaire des Vaux-de-Cernay) : le livre renvoie aux
       PAGES (« p. 77 »), la conversion a relié chaque page à son acte et affiche le numéro d'acte.
       Comme dans les autres cartulaires on montre le numéro d'acte (le lien), puis la page du livre,
       gardée dans @n : « 61 (p. 77) ». Le « p. » du livre est en commentaire dans le TEI.
       2026-10-28 (Maxime, NDVC-AB r5420590 : « juste afficher le numéro de l'acte, pas le numéro de la page ») :
       modèle retiré, la page reste dans @n du TEI. -->


  <xsl:template match="tei:ref[@target][contains(
        '|#NON_TROUVE|#NDPA-EG-03_0365|#NDPA-EG-03_1095|#NDPA-EG-03_1096|#NDPA-EG-03_1722|#NDPA-EG-03_1723|#page195|#page197|#page204|#page209|',
        concat('|', normalize-space(@target), '|'))]" priority="30">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- 2026-10-08 (chantier liens) : résolution des cibles internes ref/@target, sans appel à l'API
       (le TEI complet du cartulaire est lu par edt:compagnon, cartulaires-edition.xsl).
       - Ancre de page (tei:pb, ex. HDPAR-HD_censier_p483, SMPA-EG_censier_p236_c81_6) : une page n'est
         pas une unité de navigation. Le lien va à l'unité qui contient la page, puis #ancre (la page est
         rendue avec cet id).
       - Cible numérique sans « # » (INDEX-LIEUX, INDEX-PERSONNES : 190 cas) : pas de lien, le texte reste.
         (2026-10-09 : NDMT-AB porte désormais ses cibles vérifiées dans le TEI ; plus de calcul page → acte.)
       Résultat : () = non résolu (le lien existant est gardé) ; '' = pas de lien ; sinon l'adresse. -->
  <!-- 2026-10-20 : vide, les lettres de NDMT et STEP sont désormais des unités (liste de lettre = page, cas général) -->
  <xsl:variable name="cartu-listes-hors-nav" select="()" as="xs:string*"/>
  <!-- 2026-10-20 : index passés à une page par lettre dont le renvoi « voir » ne nomme pas la lettre (@corresp = la
       division, NDRC) : la lettre est lue dans le TEI complet, autour de la cible. -->
  <xsl:variable name="cartu-renvoi-lettre" select="('NDRC-AB', 'NDPR-AB', 'NDMT-AB', 'STEP-AB')" as="xs:string*"/>
  <xsl:function name="cartu:unite-de" as="xs:string?" version="3.0" xmlns:cartu="urn:cartu">
    <xsl:param name="e" as="element()?"/>
    <!-- unité = l'ancêtre-ou-soi le plus proche qui est un texte, une division ou un groupe porteur d'@xml:id -->
    <xsl:sequence select="$e/ancestor-or-self::*[self::tei:text or self::tei:div or self::tei:group][@xml:id][1]/@xml:id/string()"/>
  </xsl:function>
  <xsl:function name="cartu:cible-tei" as="element()?" version="3.0" xmlns:cartu="urn:cartu">
    <xsl:param name="id" as="xs:string"/>
    <xsl:sequence select="if ($resource = '' or $id = '') then () else (for $d in edt:compagnon() return id($id, $d))[1]"/>
  </xsl:function>
  <!-- 2026-10-28 : ressource d'une cible « #HDPAR-HD_censier_p484 » (index communs : la page mêle tous les
       cartulaires, $resource ne vaut que pour le premier identifiant de la page) ; son TEI complet. -->
  <xsl:function name="cartu:res-de" as="xs:string" version="3.0" xmlns:cartu="urn:cartu">
    <xsl:param name="id" as="xs:string"/>
    <xsl:sequence select="if (matches($id, '^[A-Z]{4,5}-[A-Z]{2}(-\d+)?_')) then replace($id, '^([A-Z]{4,5}-[A-Z]{2}(-\d+)?)_.*$', '$1') else $resource"/>
  </xsl:function>
  <xsl:function name="cartu:cible-tei-de" as="element()?" version="3.0" xmlns:cartu="urn:cartu">
    <xsl:param name="res" as="xs:string"/>
    <xsl:param name="id" as="xs:string"/>
    <xsl:variable name="base" select="replace($res, '-\d+$', '')"/>
    <xsl:variable name="cands" select="for $u in (concat('compagnons/', $res, '.xml'), concat('compagnons/', $base, '/', $res, '.xml'),
        concat('../data/', $res, '.xml'), concat('../data/', $base, '/', $res, '.xml')) return resolve-uri($u, static-base-uri())"/>
    <xsl:sequence select="if ($res = '' or $id = '') then () else (for $u in $cands[doc-available(.)][1] return id($id, document($u)))[1]"/>
  </xsl:function>
  <xsl:function name="cartu:href-cible" as="xs:string?" version="3.0" xmlns:cartu="urn:cartu">
    <xsl:param name="r" as="element()"/>
    <xsl:variable name="cible" select="normalize-space(string($r/@target))"/>
    <xsl:choose>
      <xsl:when test="starts-with($cible, '#') and cartu:res-de(substring($cible, 2)) != ''">
        <xsl:variable name="res" select="cartu:res-de(substring($cible, 2))"/>
        <xsl:variable name="el" select="cartu:cible-tei-de($res, substring($cible, 2))"/>
        <xsl:variable name="unite" select="cartu:unite-de($el)"/>
        <!-- 2026-10-29 : renvoi au censier qui vise l'article (@n = page, ex. SMPA-EG « 206 » -> SMPA-EG_censier_0041,
             article des p. 205-206) : ancre sur la page @n dans l'article, sinon on arrivait sur sa première page. -->
        <xsl:variable name="page" select="if ($r/@type = 'censier' and $el/self::tei:text) then ($el//tei:pb[normalize-space(@n) = normalize-space($r/@n)][@xml:id])[1] else ()"/>
        <xsl:sequence select="if ($el/self::tei:pb and exists($unite)) then concat($document-base, $res, '?refId=', $unite, '#', $el/@xml:id)
            else if (exists($page)) then concat($document-base, $res, '?refId=', $el/@xml:id, '#', $page/@xml:id) else ()"/>
      </xsl:when>
      <xsl:when test="$resource = ''"/>
      <xsl:when test="matches($cible, '^\d+$')">
        <xsl:sequence select="''"/>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>
  </xsl:function>

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
       <!-- 2026-10-08 : index sur une seule page (index-complet) : le renvoi vise la page de
            l'index, sur l'entrée, et non plus la page de la lettre (la redirection du front
            perdait l'ancre de l'entrée et arrivait en tête de lettre). -->
       <!-- 2026-10-08 (chantier liens) : NDMT-AB, STEP-AB : les listes de lettres ne sont pas des unités ;
            l'unité qui contient la cible (division de back) remplace le corresp. -->
       <xsl:variable name="unite-hors-nav" select="if ($resource = $cartu-listes-hors-nav) then cartu:unite-de(cartu:cible-tei(substring-after(normalize-space($target), '#')))
           else if ($resource = $cartu-renvoi-lettre) then (cartu:cible-tei(substring-after(normalize-space($target), '#'))/ancestor::*[contains(@xml:id, '_liste')][not(ancestor::tei:item)])[last()]/@xml:id/string()
           else ()"/>
       <xsl:variable name="refId" select="if ($idDoc = $cartu-renvoi-res) then $cartu-index-unite[index-of($cartu-renvoi-res, $idDoc)[1]] else if (exists($unite-hors-nav)) then $unite-hors-nav else translate(./@corresp, '#', '')"/>
       <xsl:variable name="url" select="concat($document-base, $idDoc, '?refId=', $refId, $target)"/>
      
       <a href="{$url}">
        <xsl:apply-templates/>
    </a>
   </xsl:when>
     <xsl:otherwise>
       <xsl:variable name="idActe" select="substring-after(@target, '#')"/>
    <xsl:variable name="idDoc"  select="substring-before($idActe, '_')"/>
    <xsl:variable name="url" select="concat($document-base, $idDoc, '?refId=', $idActe)"/>
    <!-- 2026-10-08 (chantier liens) : cible résolue (ancre de page -> unité#ancre ; numéro de page -> acte) -->
    <xsl:variable name="resolue" select="cartu:href-cible(.)"/>
    <xsl:choose>
      <xsl:when test="exists($resolue) and $resolue = ''"><xsl:apply-templates/></xsl:when>
      <xsl:when test="exists($resolue)">
        <a href="{$resolue}"><xsl:apply-templates/></a>
      </xsl:when>
      <xsl:otherwise>
        <a href="{$url}">
          <xsl:apply-templates/>
        </a>
      </xsl:otherwise>
    </xsl:choose>
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

  <xsl:template name="cartulaires-pb-label" version="3.0">
    <xsl:variable name="norm" select="normalize-space(@n)"/>
    <xsl:choose>
      <xsl:when test="starts-with(@ed, 'frantext')"/>
      <xsl:when test="$norm = ''"/>
      <xsl:when test="contains('[({', substring($norm, 1,1))">
        <xsl:value-of select="$norm"/>
      </xsl:when>
      <xsl:when test="@ana">[<xsl:value-of select="@ana"/>]</xsl:when>
      <xsl:when test="@ed">[<xsl:value-of select="@n"/>]</xsl:when>
      <!-- 2026-10-19 : notation tome + page (« 3_0101 », « t1_p067 », « I. 9 ») : « t. III, p. 101 », comme la colonne Page -->
      <xsl:when test="matches($norm, '^(t?\d+_p?\d+|[IVX]+\.\s*\d+)$')">{<xsl:value-of select="replace(edt:page-libelle(edt:tome-page($norm)), ' ', '&#160;')"/>}</xsl:when>
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
    <!-- 2026-10-29 : l'ancre de la page (#HDPAR-HD_censier_p484, renvois des index au censier) sur un span vide
         et non sur le lien : dots-vue remplace a.pb par sa vignette (PageBreak) et perdait l'id ; on arrivait
         en tête de l'article, sur la page précédente. -->
    <xsl:if test="$id != ''">
      <span class="pb-ancre" id="{$id}"/>
    </xsl:if>
    <a class="pb facs">
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
    <!-- 2026-10-28 : page de début absente du fragment (le <pb> précède l'acte, ex. NDPA-EG-01_0001) :
         on la reprend de la citation du témoin édité (« p. 3-7 ») et de sa première image. -->
    <xsl:variable name="temoin-page" select="(.//tei:witness[@ana = 'edited'][starts-with(normalize-space(@facs), 'http')])[1]"/>
    <xsl:variable name="page-debut" version="3.0"
      select="if ($temoin-page) then replace(normalize-space(string-join($temoin-page//text(), '')), '^.*[\s,]p\.\s*([IVX]+\.\s*)?(\d+)[^\d]*?(-.*)?$', '$2') else ''"/>
    <xsl:if test="../parent::dts:wrapper and not(../tei:pb[following-sibling::tei:front]) and matches($page-debut, '^\d+$')" version="3.0">
      <xsl:variable name="image" select="substring-before(concat(normalize-space($temoin-page/@facs), ' '), ' ')"/>
      <a class="pb facs" href="{$image}">
        <xsl:attribute name="data-source">
          <xsl:call-template name="cartulaires-image-source">
            <xsl:with-param name="source" select="$temoin-page/@source"/>
            <xsl:with-param name="image" select="$image"/>
          </xsl:call-template>
        </xsl:attribute>
        <xsl:if test="$temoin-page/@corresp">
          <xsl:attribute name="data-manifest" select="$temoin-page/@corresp"/>
        </xsl:if>
        <xsl:text>{p.&#160;</xsl:text>
        <xsl:value-of select="$page-debut"/>
        <xsl:text>}</xsl:text>
      </a>
    </xsl:if>
    <xsl:element name="{$el}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:call-template name="atts"/>
      <!-- 2026-10-28 : censier de l'Hôtel-Dieu, @n = rang (exigé par le schéma) absent de l'édition Brièle : pas affiché -->
      <xsl:if test="normalize-space(../@n) != '' and not(starts-with(../@xml:id, 'HDPAR-HD_censier_'))">
        <div class="docNum">
          <xsl:value-of select="normalize-space(../@n)"/>
        </div>
      </xsl:if>
      <xsl:apply-templates/>
      <!-- mention « D'apres <temoin edite> », comme chez hteiml -->
      <!-- 2026-10-19 : un seul « D'après » : le premier témoin suivi (B, puis l'édition a, SMPA-AB-03) -->
      <xsl:apply-templates select="(.//tei:witness[@ana='edited'])[1]" mode="according"/>
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

  <!-- ==== V5-PRESENTATION-FIN ==== -->
  <!-- 2026-10-07 : SSCO-AB, « Table du cartulaire » : la liste du livre (« 1o Privilegium … (1071)
       VI recto 1. ») devient un tableau N° | Pièce | Date | Folio | Page, en trois parties comme dans
       le livre (cartulaire, cens, appendice). Le folio et la page viennent de @n du renvoi
       (« VI recto 1 », « deest 14 ») ; la pièce et la page mènent à l'unité visée quand le TEI
       porte la cible, sinon pas de lien. -->

  <!-- 2026-10-19 : retirés, car morts (aucune page servie ne les produisait : le module Édition, de
       priorité 30, rend la page d'un groupe) et dépendants d'un tri en CSS par boutons radio et d'un
       filtre en JavaScript dans le HTML : le tableau « cartulaires-table-actes » (W1), ses gabarits
       cartulaires-date-libelle et cartulaires-acte-href, les accroches 1 à 3, le résumé de groupe et
       la variable cartu-filtre-js. La liste des actes est celle de la page Édition
       (cartulaires-edition.xsl, module commun tableau-filtrable). -->

  <!-- ==== 4. MÉCANISMES COMMUNS : liens vers les anciens sites ÉLEC (D5) ==== -->

  <!-- D5-DEBUT (autopilote 2026-09-12) : liens vers les anciens sites ELEC -->
  <!-- hteiml fait un lien de tout tei:idno commencant par « http » (tei2html.xsl l. 1805),
       du tei:title voisin d'un idno[@type='URI'] (l. 1796) et de tei:ref/@target (l. 1456).
       Les anciens sites ELEC ferment : le TEXTE affiche est conserve mot pour mot (c'est
       l'identifiant de la publication d'origine), seule la cible devient la route locale.
       Table et bloc produits par dots-autopilot/scripts/d5_legacy_links_fix.py. -->
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/NDPA-EG-01']" priority="14">
    <a class="idno d5-local" href="{$document-base}NDPA-EG-01"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/NDPA-EG-02']" priority="14">
    <a class="idno d5-local" href="{$document-base}NDPA-EG-02"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/NDPA-EG-03']" priority="14">
    <a class="idno d5-local" href="{$document-base}NDPA-EG-03"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/NDPA-EG-04']" priority="14">
    <a class="idno d5-local" href="{$document-base}NDPA-EG-04"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/SAPC-AB']" priority="14">
    <a class="idno d5-local" href="{$document-base}SAPC-AB"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/SMMI-AB']" priority="14">
    <a class="idno d5-local" href="{$document-base}SMMI-AB"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/SMPA-AB-02']" priority="14">
    <a class="idno d5-local" href="{$document-base}SMPA-AB-02"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/SMPA-AB-03']" priority="14">
    <a class="idno d5-local" href="{$document-base}SMPA-AB-03"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/VNDP-AB']" priority="14">
    <a class="idno d5-local" href="{$document-base}VNDP-AB"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/cartulaires/vauxcernay/']" priority="14">
    <a class="idno d5-local" href="{$document-base}NDVC-AB"><xsl:apply-templates/></a>
  </xsl:template>
  <!-- D5-FIN -->

  <!-- 2026-10-27 : « Liste des actes » (table type="actes" dans l'argument d'un groupe, données anciennes) :
       non rendue, la TOC de dots-vue donne déjà la liste des actes (décision de Maxime). -->
  <xsl:template match="tei:group/tei:argument/tei:table[@type = 'actes']" priority="40"/>
  <!-- ==== Pages Édition et tableaux des cartulaires (anciens modules réintégrés) ==== -->
  <!-- (ancien module cartulaires-edition.xsl, réintégré le 2026-10-20) 2026-10-08 : module « edition », inclus par cartulaires.xsl.
     PAGE ÉDITION (unité group) : titre et présentation du groupe ; la liste des actes est le sommaire
     de dots-vue (2026-10-20 : plus de tableau sur les pages de groupe, l'équipe n'en veut pas à la
     place du sommaire). Les fonctions edt: restantes servent aussi aux tableaux et aux pages. -->
  <xsl:template version="3.0" match="tei:group[parent::*[local-name() = 'wrapper']][.//tei:text]" priority="30">
    <div class="group">
      <xsl:if test="@xml:id"><xsl:attribute name="id" select="@xml:id"/></xsl:if>
      <xsl:if test="tei:head"><h1 class="head"><xsl:apply-templates select="tei:head/node()"/></h1></xsl:if>
      <xsl:apply-templates select="tei:argument"/>
      <!-- 2026-10-28 (Maxime, NDPA-EG-04_group-4 : « les deux pouillés sont vides ») : texte du groupe qui n'est pas
           une unité citable (text sans xml:id : pouillés de NDPA-EG-04) ; absent du sommaire, il s'affiche ici. -->
      <xsl:apply-templates select="tei:text[not(@xml:id)]"/>
    </div>
  </xsl:template>


  <!-- 2026-10-08 : TEI COMPLET du cartulaire servi. Localement, compagnons/ est une jonction vers
       cartulaires-todo\data (sous-dossiers MAUB-AB, NDPA-EG, SCCO-AB, SMPA-AB) ; dans le dépôt publié,
       ../data/. Pas d'appel à l'API (interblocage de BaseX). -->
  <xsl:function version="3.0" name="edt:compagnon" as="document-node()?">
    <xsl:variable name="base" select="replace($resource, '-\d+$', '')"/>
    <xsl:variable name="cands" select="for $u in (concat('compagnons/', $resource, '.xml'), concat('compagnons/', $base, '/', $resource, '.xml'),
        concat('../data/', $resource, '.xml'), concat('../data/', $base, '/', $resource, '.xml')) return resolve-uri($u, static-base-uri())"/>
    <xsl:sequence select="if ($resource = '') then () else (for $u in $cands[doc-available(.)][1] return document($u))"/>
  </xsl:function>
  <!-- clé de comparaison d'un titre : sans casse, accents, espaces ni ponctuation (le disque peut avoir
       des titres recassés pas encore réingérés : « LIBER NONUS.LITTERÆ » = « Liber nonus. Litteræ ») -->

  <!-- 2026-10-27 : les pages de regroupement servies sans leurs actes ne sont plus recomposées à partir du
       TEI complet (edt:compagnon) : rendu de base de ce que sert DoTS, et TOC de dots-vue (décision de Maxime). -->


  <!-- 2026-10-19 : page de l'édition, sous ses différentes notations (« 67 », « page 67 », « t1_p067 » NDCH,
       « 1_0003 » NDVC et SMCP, « I. 9 » NDPA-EG-01 et SGDP) → (tome en chiffres arabes ou '', page). -->
  <xsl:function version="3.0" name="edt:tome-page" as="xs:string*" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="n" as="xs:string"/>
    <xsl:variable name="romains" select="('I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X')"/>
    <xsl:analyze-string select="normalize-space($n)" regex="^(?:t?(\d+)_p?|([IVX]+)\.\s*|page\s+)?0*(\d+)$">
      <xsl:matching-substring>
        <xsl:sequence select="(if (regex-group(1) != '') then string(number(regex-group(1))) else if (regex-group(2) != '') then string(index-of($romains, regex-group(2))[1]) else '', regex-group(3))"/>
      </xsl:matching-substring>
      <xsl:non-matching-substring><xsl:sequence select="('', .)"/></xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:function>
  <xsl:function version="3.0" name="edt:page-libelle" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="tp" as="xs:string*"/>
    <xsl:variable name="romains" select="('I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X')"/>
    <xsl:sequence select="if ($tp[1] != '' and $tp[2] castable as xs:integer) then concat('t. ', $romains[xs:integer($tp[1])], ', p. ', $tp[2]) else if ($tp[2] castable as xs:integer) then concat('p. ', $tp[2]) else string($tp[2])"/>
  </xsl:function>

  <!-- (ancien module cartulaires-tableaux.xsl, réintégré le 2026-10-20) Module « tableaux » des cartulaires, inclus par cartulaires.xsl (2026-10-19 : refait sur le
     module commun tableau-filtrable.xsl, classes tf-*, comportement dans le JS générique de l'ÉLEC ;
     plus aucun onclick / oninput dans le HTML, que dots-vue retire).

     Décision de Maxime (19/10) : les lignes d'intertitre (parties, siècles, rubriques) deviennent une
     COLONNE filtrable ; le tri porte alors sur tout le tableau.

     Tableaux rendus :
       - Table de l'édition (page « Édition ») ............ cartulaires-edition.xsl, via cartu-tf
       - Table chronologique (back, SMPA-AB-02) ........... N° | Rang | Date | Analyse | Page
       - Appendice en inventaire (VNDP-AB) ................ N° | Rubrique | Lieu | Article
       - Annexes de SAPC-AB : abbesses ...................... N° | Abbesse | Dates
                              sceaux ........................ N° | Sigillant | Date | Rubrique | Lieu | Notice
       - Tableaux des introductions (répartition chronologique…) : lignes de titre en en-tête, lignes
         d'intertitre en colonne « Section » ; un intertitre qui porte un total (« XIIe siècle | 7 »)
         reste une ligne « Total », pour ne rien perdre. Un tableau à cellules fusionnées dans le corps
         (HDPAR-HD) ne peut pas être trié : il reste un tableau simple. -->

  <!-- ==================================================================================================
       Tableaux des introductions (hors des actes).
       ================================================================================================== -->
  <xsl:template match="tei:table[not(ancestor::tei:text[parent::tei:group])]" priority="5" version="3.0">
    <xsl:variable name="lignes" select="tei:row"/>
    <!-- ligne d'en-tête : ligne de titre en tête de tableau, sans cellule purement numérique (une ligne
         « XIIe siècle | 7 » est un intertitre qui porte un total, pas un en-tête) -->
    <xsl:variable name="tete" select="$lignes[@role = 'label'][not(preceding-sibling::tei:row[not(@role = 'label')])][not(tei:cell[matches(normalize-space(.), '^\d+$')])]"/>
    <xsl:variable name="corps" select="$lignes except $tete"/>
    <!-- 2026-10-20 : tous les tableaux des introductions sont rendus en tableau simple (non triable),
         comme le rendu de base de dots-vue ; plus de tableau filtrable (constructeur cartu-tf retiré
         des appels). -->
    <table class="cartu-tableau cartu-tableau-simple">
      <xsl:apply-templates select="tei:head"/>
      <xsl:if test="$tete">
        <thead><xsl:apply-templates select="$tete" mode="tableau-simple"/></thead>
      </xsl:if>
      <tbody>
        <xsl:apply-templates select="$corps | tei:pb" mode="tableau-simple">
          <xsl:with-param name="ncols" select="max((1, for $r in tei:row return sum(for $c in $r/tei:cell return if ($c/@cols) then xs:integer($c/@cols) else 1)))" tunnel="yes"/>
        </xsl:apply-templates>
      </tbody>
    </table>
  </xsl:template>

  <!-- Tableau simple (non triable) : lignes et cellules, fusions comprises ; lignes de titre en th. -->



  <xsl:template version="3.0" match="tei:row" mode="tableau-simple">
    <tr>
      <xsl:if test="@role = 'label' and preceding-sibling::tei:row[not(@role = 'label')]">
        <xsl:attribute name="class">cartu-tm-partie</xsl:attribute>
      </xsl:if>
      <xsl:for-each select="tei:cell">
        <xsl:element name="{if (../@role = 'label' or @role = 'label') then 'th' else 'td'}" namespace="http://www.w3.org/1999/xhtml">
          <xsl:if test="@rows &gt; 1"><xsl:attribute name="rowspan" select="@rows"/></xsl:if>
          <xsl:if test="@cols &gt; 1"><xsl:attribute name="colspan" select="@cols"/></xsl:if>
          <!-- 2026-10-28 (Maxime, SMPA-AB-02_back-1 : « on peut pas tout lire sur le tableau ») : seules les
               cellules courtes (numéros, sigles, cotes) restent sur une ligne ; la CSS supposait que les trois
               premières colonnes étaient des numéros, et l'analyse de SMPA-AB-02 ne revenait plus à la ligne. -->
          <xsl:if test="not(@cols &gt; 1) and string-length(normalize-space(.)) le 14"><xsl:attribute name="class">cartu-court</xsl:attribute></xsl:if>
          <xsl:apply-templates/>
        </xsl:element>
      </xsl:for-each>
    </tr>
  </xsl:template>
  <!-- saut de page posé entre deux lignes : une ligne discrète, pleine largeur (vignette, repère) -->
  <xsl:template version="3.0" match="tei:pb" mode="tableau-simple">
    <xsl:param name="ncols" as="xs:integer" tunnel="yes" select="1"/>
    <tr class="cartu-tm-pb">
      <td colspan="{$ncols}"><xsl:apply-templates select="." mode="#default"/></td>
    </tr>
  </xsl:template>



  <!-- date de tri AAAA-MM-JJ : année (premier nombre de 3 ou 4 chiffres) ; mois et jour seulement s'ils suivent
       immédiatement « année, [jour] mois » ; date incomplète = 1er janvier ou 1er du mois de l'année ;
       « xive s. » = 1301-01-01 ; aucune année = '' (fin du tri). « (n. st.) » ignoré. -->

  <!-- ==================================================================================================
       Appendice en inventaire (VNDP-AB_back : rubriques « I. Iste sunt vinee… », articles « apud
       Joyacum, i. arpentum… », « item, … ») : N° | Rubrique | Lieu | Article. Le lieu vient de « apud X, »
       et passe aux « item » qui suivent. Servi entier (div) ou seul (dts:wrapper).
       ================================================================================================== -->
  <xsl:template match="(tei:div[@type = 'appendice'] | *[local-name() = 'wrapper'][not(tei:teiHeader)][matches(normalize-space(tei:head[1]), '^appendice', 'i')])
      [tei:div][every $d in tei:div satisfies empty($d/*[not(self::tei:head or self::tei:p or self::tei:pb)])]" priority="27" version="3.0">
    <xsl:variable name="articles" select="tei:div/tei:p[normalize-space()]"/>
    <section class="cartu-appendice">
      <xsl:if test="self::tei:div/@xml:id"><xsl:attribute name="id" select="@xml:id"/></xsl:if>
      <h1 class="head"><xsl:apply-templates select="tei:head[1]/node()[not(self::tei:pb)]"/></h1>
        <xsl:apply-templates select="tei:div"/>
    </section>
  </xsl:template>

  <!-- lieu d'un article : « apud X, » ; un article « item » reprend le lieu de l'article précédent -->
  <xsl:function version="3.0" name="cartu-app:lieu" as="xs:string">
    <xsl:param name="p" as="element()"/>
    <xsl:variable name="t" select="normalize-space(string-join($p//text()[not(ancestor::tei:note)], ''))"/>
    <xsl:sequence select="if (matches($t, '^(apud|juxta|in)\s+[^,;]+', 'i')) then replace(replace($t, '^(apud|juxta|in)\s+([^,;]+).*$', '$2', 'i'), '[\s&#160;]+$', '')
        else if (matches($t, '^item([\s,.;:]|$)', 'i') and $p/preceding-sibling::tei:p) then cartu-app:lieu($p/preceding-sibling::tei:p[1])
        else ''"/>
  </xsl:function>


  <!-- ==================================================================================================
       ANNEXES de SAPC-AB (back-1) : liste des abbesses et corpus des sceaux. La sous-rubrique d'un sceau
       (« A. Sceaux… · b) Archevêchés », avec ses mentions qui précèdent le premier sceau, sauf le lieu,
       qui a sa colonne) passe dans la colonne Rubrique. Le TEI n'est pas modifié.
       ================================================================================================== -->
  <xsl:template match="tei:div[@type = 'annexes'][.//tei:div/tei:head[matches(normalize-space(.), 'SCEAUX', 'i')]]" priority="28" version="3.0">
    <section class="cartu-annexes">
      <xsl:if test="@xml:id"><xsl:attribute name="id" select="@xml:id"/></xsl:if>
      <h1 class="head"><xsl:apply-templates select="tei:head[1]/node()"/></h1>
      <xsl:for-each select="tei:div">
        <xsl:choose>
          <xsl:when test="not(tei:div) and tei:p[chr:liste-num(.)]">
            <xsl:call-template name="chr:annexes-liste"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="chr:annexes-sceaux"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </section>
  </xsl:template>



  <xsl:template version="3.0" name="chr:annexes-liste">
    <section class="cartu-appendice cartu-annexes-liste">
      <h2 class="head"><xsl:apply-templates select="tei:head[1]/node()"/></h2>
      <xsl:apply-templates select="tei:p"/>
    </section>
  </xsl:template>

  <xsl:template version="3.0" name="chr:annexes-sceaux">
    <section class="cartu-appendice cartu-annexes-sceaux">
      <h2 class="head"><xsl:apply-templates select="tei:head[1]/node()"/></h2>
      <xsl:apply-templates select="tei:p"/>
      <xsl:apply-templates select="tei:div"/>
    </section>
  </xsl:template>






  <!-- abbesse : « 6 Jeanne 1ère, 1253-1254.. » -->
  <xsl:function version="3.0" name="chr:liste-num" as="xs:boolean">
    <xsl:param name="p" as="element()"/>
    <xsl:sequence select="matches(normalize-space(string($p)), '^\d+\s+.+,\s*\d{3,4}\s*[–-]\s*\d{3,4}\.*$')"/>
  </xsl:function>


  <!-- Titre (group ou dts:wrapper) portant une note hors de tout tei:text : la collecte des notes de
       hteiml ne la voit pas ; le bloc de notes du titre est ajouté après le rendu, s'il n'y est pas déjà
       (SMCP-PR group-3-2-6, NDPA-EG-01 group-2-9, NDPA-EG-03 group-3-2). -->
  <xsl:template match="(tei:group[parent::*[local-name() = 'wrapper']] | *[local-name() = 'wrapper'])[tei:head//tei:note]" priority="31" version="3.0">
    <xsl:variable name="rendu">
      <xsl:next-match/>
    </xsl:variable>
    <xsl:copy-of select="$rendu"/>
    <xsl:if test="not($rendu//*[@class = 'footnotes'])">
      <section class="footnotes">
        <xsl:for-each select="tei:head//tei:note">
          <xsl:call-template name="note"/>
        </xsl:for-each>
      </section>
    </xsl:if>
  </xsl:template>

</xsl:transform>
