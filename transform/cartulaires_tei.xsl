<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tei">

  <xsl:output method="xml" encoding="UTF-8"/>

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
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

  <xsl:template match="tei:pb[not(@facs)]">
    <xsl:variable name="firstPbId" select="generate-id(ancestor::tei:text[1]//tei:pb[1])"/>
    <xsl:variable name="graphicUrl" select="ancestor::tei:text[1]/tei:body//tei:graphic[@url][1]/@url"/>
    <xsl:variable name="graphicSource" select="ancestor::tei:text[1]/tei:body//tei:graphic[@source][1]/@source"/>
    <xsl:variable name="witnessFacs" select="ancestor::tei:text[1]/tei:front//tei:witness[@facs][1]/@facs"/>
    <xsl:variable name="witnessSource" select="ancestor::tei:text[1]/tei:front//tei:witness[@source][1]/@source"/>
    <xsl:variable name="firstWitnessFacs" select="substring-before(concat(normalize-space($witnessFacs), ' '), ' ')"/>
    <xsl:variable name="image">
      <xsl:choose>
        <xsl:when test="$graphicUrl != ''"><xsl:value-of select="$graphicUrl"/></xsl:when>
        <xsl:when test="starts-with($firstWitnessFacs, 'http')"><xsl:value-of select="$firstWitnessFacs"/></xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="src">
      <xsl:choose>
        <xsl:when test="$graphicSource != ''"><xsl:value-of select="$graphicSource"/></xsl:when>
        <xsl:otherwise><xsl:value-of select="$witnessSource"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:copy>
      <xsl:apply-templates select="@*[local-name() != 'source' and local-name() != 'facs']"/>
      <xsl:if test="generate-id(.) = $firstPbId and $image != ''">
        <xsl:attribute name="source">
          <xsl:choose>
            <xsl:when test="@source"><xsl:value-of select="@source"/></xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="cartulaires-image-source">
                <xsl:with-param name="source" select="$src"/>
                <xsl:with-param name="image" select="$image"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
        <xsl:attribute name="facs"><xsl:value-of select="$image"/></xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="tei:div[@type='transcription']/tei:figure[count(*) = 1 and tei:graphic[@source and @url and (contains(@source, 'nakala.fr') or contains(@url, 'nakala.fr'))]]">
    <xsl:variable name="previousGraphic" select="preceding-sibling::tei:figure[tei:graphic[@source and @url and (contains(@source, 'nakala.fr') or contains(@url, 'nakala.fr'))]]"/>
    <xsl:if test="not($previousGraphic) and not(ancestor::tei:text[1]//tei:pb)">
      <pb xmlns="http://www.tei-c.org/ns/1.0">
        <xsl:attribute name="source"><xsl:value-of select="tei:graphic[1]/@source"/></xsl:attribute>
        <xsl:attribute name="n">manuscrit</xsl:attribute>
        <xsl:attribute name="facs"><xsl:value-of select="tei:graphic[1]/@url"/></xsl:attribute>
      </pb>
    </xsl:if>
  </xsl:template>

</xsl:transform>
