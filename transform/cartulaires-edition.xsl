<?xml version="1.0" encoding="UTF-8"?>
<!-- 2026-10-08 : module « edition », inclus par cartulaires.xsl.
     PAGE ÉDITION (unité group servie entière : « part » dans editByCiteType) : la liste des actes
     prend la forme de la « Table du cartulaire » de SSCO-AB (r7987684, modèle validé par Maxime) :
     mêmes classes (table.cartu-table-matieres), mêmes colonnes N° | Pièce | Date | Folio | Page,
     une ligne d'intertitre par partie (sous-groupe). Ajout demandé : le tri, par N° ou par date,
     au clic sur l'en-tête de colonne (attribut onclick ; DoTS-vue n'exécute pas les <script>).
     Folio : premier pb portant @ed (témoin manuscrit) ; Page : page de l'édition où l'acte
     commence. Une colonne vide pour tous les actes n'est pas affichée.
     Version précédente (filtre, 50 premiers actes) : scratchpad\chantier\edition\*.avant_ssco. -->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:dts="https://w3id.org/dts/api#"
  xmlns:edt="urn:cartu-edition"
  exclude-result-prefixes="tei dts edt">

  <!-- tri : ordre du livre (data-ord) ; une colonne de texte (th[data-texte], ex. Lieu des appendices) se trie par ordre alphabétique ; / numéro (data-num) / date (data-date, AAAA-MM-JJ ; sans date = fin).
       Trié par date, les intertitres de parties n'ont plus de sens : masqués ; retour à l'ordre du
       livre en recliquant sur N°. -->
  <xsl:variable name="edt-tri-js">var t=this.closest('table'),b=t.tBodies[0],k=this.getAttribute('data-cle'),tx=this.hasAttribute('data-texte'),s=this.getAttribute('aria-sort')==='ascending'?-1:1;t.querySelectorAll('th[data-cle]').forEach(function(h){h.removeAttribute('aria-sort');});this.setAttribute('aria-sort',s===1?'ascending':'descending');var r=Array.prototype.slice.call(b.rows),v=function(x){var a=x.getAttribute('data-'+k)||'';return k==='date'?(a||(s===1?'9999':'0000')):parseFloat(a)||0;};r.sort(function(x,y){if(k==='num'&amp;&amp;s===1){return (parseFloat(x.getAttribute('data-ord'))||0)-(parseFloat(y.getAttribute('data-ord'))||0);}if(tx){var ea=!(x.getAttribute('data-'+k)),eb=!(y.getAttribute('data-'+k));if(ea!==eb){return ea?1:-1;}return (x.getAttribute('data-'+k)||'').localeCompare(y.getAttribute('data-'+k)||'','fr',{sensitivity:'base'})*s||(parseFloat(x.getAttribute('data-ord'))-parseFloat(y.getAttribute('data-ord')));}var p=v(x),q=v(y);return (p&lt;q?-1:p&gt;q?1:0)*s;});r.forEach(function(x){b.appendChild(x);});b.querySelectorAll('tr.cartu-tm-partie').forEach(function(x){x.hidden=!(k==='num'&amp;&amp;s===1);});</xsl:variable>

  <xsl:template match="tei:group[parent::*[local-name() = 'wrapper']][.//tei:text]" priority="30">
    <div class="group">
      <xsl:if test="@xml:id"><xsl:attribute name="id" select="@xml:id"/></xsl:if>
      <xsl:if test="tei:head"><h1 class="head"><xsl:apply-templates select="tei:head/node()"/></h1></xsl:if>
      <xsl:apply-templates select="tei:argument"/>
      <!-- 2026-10-08 : SSCO-AB a sa propre « Table du cartulaire » (back, div[@type='table'], avec les
           folios du manuscrit) : c'est elle qui sert de tableau à la page Édition (Maxime : « réutiliser
           la table du cartulaire au niveau édition, supprimer le doublon »). Le fragment du groupe ne
           contient pas le back : on lit le TEI complet posé dans compagnons/ (pas l'API). -->
      <xsl:variable name="table-propre" select="edt:table-propre()"/>
      <xsl:choose>
        <xsl:when test="exists($table-propre)">
          <xsl:apply-templates select="$table-propre"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="edt-tableau"/>
        </xsl:otherwise>
      </xsl:choose>
    </div>
  </xsl:template>

  <xsl:function name="edt:table-propre" as="element()*">
    <xsl:sequence select="if ($resource = 'SSCO-AB') then edt:compagnon()//tei:back//tei:div[@type = 'table']//tei:list[@type = 'gloss'] else ()"/>
  </xsl:function>

  <!-- 2026-10-08 : TEI COMPLET du cartulaire servi. Localement, compagnons/ est une jonction vers
       cartulaires-todo\data (sous-dossiers MAUB-AB, NDPA-EG, SCCO-AB, SMPA-AB) ; dans le dépôt publié,
       ../data/. Pas d'appel à l'API (interblocage de BaseX). -->
  <xsl:function name="edt:compagnon" as="document-node()?">
    <xsl:variable name="base" select="replace($resource, '-\d+$', '')"/>
    <xsl:variable name="cands" select="for $u in (concat('compagnons/', $resource, '.xml'), concat('compagnons/', $base, '/', $resource, '.xml'),
        concat('../data/', $resource, '.xml'), concat('../data/', $base, '/', $resource, '.xml')) return resolve-uri($u, static-base-uri())"/>
    <xsl:sequence select="if ($resource = '') then () else (for $u in $cands[doc-available(.)][1] return document($u))"/>
  </xsl:function>
  <xsl:function name="edt:titre" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="e" as="element()?"/>
    <xsl:sequence select="normalize-space(string-join($e/tei:head[1]//text()[not(ancestor::tei:note)], ''))"/>
  </xsl:function>
  <!-- clé de comparaison d'un titre : sans casse, accents, espaces ni ponctuation (le disque peut avoir
       des titres recassés pas encore réingérés : « LIBER NONUS.LITTERÆ » = « Liber nonus. Litteræ ») -->
  <xsl:function name="edt:cle" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="e" as="element()?"/>
    <xsl:sequence select="replace(replace(lower-case(normalize-unicode(edt:titre($e), 'NFD')), '\p{M}', ''), '[^\p{L}\p{N}]', '')"/>
  </xsl:function>

  <!-- 2026-10-08 : page Édition servie SANS ses actes (excludeFragments=true : « part » n'est plus dans
       editByCiteType, pour que chaque acte garde sa page). Le groupe est retrouvé dans le TEI complet par
       son titre ; le tableau est fait à partir de lui. Toute autre page sans acte (chapitre d'introduction)
       n'a pas de groupe de ce titre : next-match, rendu inchangé. -->
  <xsl:template match="*[local-name() = 'wrapper'][not(.//tei:text)][tei:head]" priority="26">
    <xsl:variable name="h" select="edt:cle(.)"/>
    <xsl:variable name="g" select="(edt:compagnon()//tei:group[tei:head][.//tei:text[@xml:id]][edt:cle(.) = $h])[1]"/>
    <xsl:choose>
      <xsl:when test="exists($g)">
        <div class="group">
          <xsl:if test="$g/@xml:id"><xsl:attribute name="id" select="$g/@xml:id"/></xsl:if>
          <h1 class="head"><xsl:apply-templates select="tei:head[1]/node()"/></h1>
          <xsl:apply-templates select="$g/tei:argument"/>
          <xsl:variable name="table-propre" select="edt:table-propre()"/>
          <xsl:choose>
            <xsl:when test="exists($table-propre)"><xsl:apply-templates select="$table-propre"/></xsl:when>
            <xsl:otherwise><xsl:for-each select="$g"><xsl:call-template name="edt-tableau"/></xsl:for-each></xsl:otherwise>
          </xsl:choose>
        </div>
      </xsl:when>
      <xsl:otherwise><xsl:next-match/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="edt-tableau">
      <xsl:variable name="actes" select=".//tei:text[@xml:id]"/>
      <xsl:variable name="avec-folio" select="exists($actes[edt:folio(.) != ''])"/>
      <xsl:variable name="avec-page" select="exists($actes[edt:page(.) != ''])"/>
      <xsl:variable name="nb-col" select="3 + (if ($avec-folio) then 1 else 0) + (if ($avec-page) then 1 else 0)"/>
      <table class="cartu-table-matieres cartu-edition">
        <thead>
          <tr>
            <th scope="col" class="cartu-tm-n cartu-tri-col" data-cle="num" aria-sort="ascending" title="Trier par numéro" onclick="{$edt-tri-js}">N<sup>o</sup></th>
            <th scope="col">Pièce</th>
            <th scope="col" class="cartu-tm-date cartu-tri-col" data-cle="date" title="Trier par date" onclick="{$edt-tri-js}">Date</th>
            <xsl:if test="$avec-folio"><th scope="col" class="cartu-tm-fol">Folio</th></xsl:if>
            <xsl:if test="$avec-page"><th scope="col" class="cartu-tm-p">Page</th></xsl:if>
          </tr>
        </thead>
        <tbody>
          <xsl:for-each select="descendant-or-self::tei:group[tei:text[@xml:id]]">
            <xsl:if test="not(. is current()) and tei:head">
              <tr class="cartu-tm-partie" data-ord="{count(preceding::tei:text) + 0.5}">
                <th colspan="{$nb-col}" scope="rowgroup"><xsl:apply-templates select="tei:head/node()"/></th>
              </tr>
            </xsl:if>
            <xsl:for-each select="tei:text[@xml:id]">
              <xsl:variable name="href" select="concat($document-base, $resource, '?refId=', @xml:id)"/>
              <tr data-ord="{count(preceding::tei:text) + 1}" data-num="{edt:num(.)}" data-date="{edt:date-tri(.)}">
                <td class="cartu-tm-n"><xsl:value-of select="@n"/></td>
                <td class="cartu-tm-titre"><xsl:variable name="piece" select="edt:piece(.)"/><a href="{$href}"><xsl:if test="string-length($piece) gt 120"><xsl:attribute name="title" select="$piece"/></xsl:if><xsl:value-of select="edt:piece-courte($piece)"/></a></td>
                <td class="cartu-tm-date"><xsl:value-of select="edt:date(.)"/></td>
                <xsl:if test="$avec-folio"><td class="cartu-tm-fol"><xsl:value-of select="edt:folio(.)"/></td></xsl:if>
                <xsl:if test="$avec-page"><td class="cartu-tm-p"><xsl:if test="edt:page(.) != ''"><a href="{$href}"><xsl:value-of select="edt:page(.)"/></a></xsl:if></td></xsl:if>
              </tr>
            </xsl:for-each>
          </xsl:for-each>
        </tbody>
      </table>
  </xsl:template>

  <!-- texte visible d'un élément, sans les notes -->
  <xsl:function name="edt:txt" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="e" as="node()*"/>
    <!-- un <lb/> sépare deux mots (« DOYEN<lb/>DE ») : compté comme une espace -->
    <xsl:sequence select="normalize-space(string-join($e//(text() | tei:lb)[not(ancestor::tei:note)] ! (if (self::tei:lb) then ' ' else string(.)), ''))"/>
  </xsl:function>
  <!-- Pièce : titre de l'acte, sinon son analyse, sinon le début du texte -->
  <xsl:function name="edt:piece" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="t" as="element()"/>
    <!-- un titre qui n'est que le numéro de l'acte (« III. », VNDP-AB) n'est pas un titre de pièce -->
    <xsl:variable name="cands" select="(edt:txt(($t/tei:front/tei:head, $t/tei:body/tei:head)[1]), edt:txt($t/tei:front/tei:argument[1]), edt:txt($t/tei:front/tei:div[@type = 'analyse'][1]))[. != ''][not(matches(., '^[\s\[\(]*(N[°o]\s*)?[IVXLCDM0-9]+[a-z]?(\s*bis|\s*ter)?[\s.\]\)]*$', 'i'))]"/>
    <xsl:variable name="p" select="if (exists($cands)) then $cands[1] else edt:txt($t/tei:body)"/>
    <xsl:sequence select="$p"/>
  </xsl:function>
  <!-- Pièce affichée : coupée vers 110 caractères, sur une fin de mot, avec « … » (les analyses de
       SMPA-AB-03 font plusieurs lignes) ; le texte complet reste dans l'attribut title du lien. -->
  <xsl:function name="edt:piece-courte" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="p" as="xs:string"/>
    <xsl:sequence select="if (string-length($p) le 120) then $p else concat(replace(substring($p, 1, 110), '[\s,;:.(«“-]+[^\s]*$', ''), ' …')"/>
  </xsl:function>
  <xsl:function name="edt:date" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="t" as="element()"/>
    <!-- la date seule (comme la table de SSCO) : docDate contient souvent aussi le lieu (« Compiègne ») -->
    <xsl:variable name="d" select="($t/tei:front/tei:docDate[1]//tei:date[edt:txt(.) != ''])[1]"/>
    <xsl:sequence select="replace(if ($d) then edt:txt($d) else edt:txt($t/tei:front/tei:docDate[1]), '[\s.,;]+$', '')"/>
  </xsl:function>
  <xsl:function name="edt:date-tri" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="t" as="element()"/>
    <xsl:variable name="d" select="($t/tei:front/tei:docDate//tei:date/(@when, @notBefore, @from)[matches(., '^\d{3,4}')])[1]"/>
    <xsl:sequence select="if ($d) then format-number(number(substring-before(concat($d, '-'), '-')), '0000') || substring($d, string-length(substring-before(concat($d, '-'), '-')) + 1) else ''"/>
  </xsl:function>
  <xsl:function name="edt:num" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="t" as="element()"/>
    <xsl:variable name="d" select="replace(string($t/@xml:id), '^.*_0*(\d+)[^_]*$', '$1')"/>
    <xsl:sequence select="if (matches($d, '^\d+$')) then $d else string(count($t/preceding::tei:text) + 1)"/>
  </xsl:function>
  <xsl:function name="edt:folio" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="t" as="element()"/>
    <xsl:sequence select="normalize-space(($t//tei:pb[@ed][normalize-space(@n)])[1]/@n)"/>
  </xsl:function>
  <!-- page de l'édition où l'acte commence : dernier pb (sans @ed) avant l'acte, sinon le premier dedans -->
  <xsl:function name="edt:page" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="t" as="element()"/>
    <xsl:sequence select="normalize-space(($t/preceding::tei:pb[not(@ed)][normalize-space(@n)][1], ($t//tei:pb[not(@ed)][normalize-space(@n)])[1])[1]/@n)"/>
  </xsl:function>
</xsl:stylesheet>
