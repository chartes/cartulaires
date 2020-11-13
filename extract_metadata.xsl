<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:output method="text"/>
    
    <xsl:param name="sourceFolder">
        <xsl:value-of select="tokenize(base-uri(), '/')[position() &lt; last()]" separator="/"/>
        <xsl:text>/?select=*.xml</xsl:text>
    </xsl:param>
    
    <xsl:variable name="myCollection" select="collection($sourceFolder)"/>
    
    
    <xsl:variable name="myTypes" select="distinct-values($myCollection/descendant::tei:term[@type='nature']/@key)"/>
    
    
    <xsl:template match="/">

        <!--
        <xsl:for-each select="$myCollection">
            <xsl:value-of select="tei:TEI/@xml:id"/>
        </xsl:for-each>-->
        
        <xsl:result-document href="doc_types.csv">
            <xsl:text>ID</xsl:text>
            <xsl:text>&#9;</xsl:text>
            <xsl:for-each select="$myTypes">
                <xsl:sort/>
                <xsl:value-of select="."/>
                <xsl:if test="position() != last()">
                    <xsl:text>&#9;</xsl:text>
                </xsl:if>
            </xsl:for-each>
            <xsl:text>&#xA;</xsl:text>
            
            <xsl:apply-templates select="$myCollection/descendant::tei:TEI"/>
            
        </xsl:result-document>
        
        <xsl:result-document href="n_entites.csv">
            <xsl:text>ID</xsl:text>
            <xsl:text>&#9;</xsl:text>
            <xsl:text>placeName</xsl:text>
            <xsl:text>&#9;</xsl:text>
            <xsl:text>persName</xsl:text>
            <xsl:text>&#9;</xsl:text>
            <xsl:text>rs place</xsl:text>
            <xsl:text>&#9;</xsl:text>
            <xsl:text>rs pers</xsl:text>
            <xsl:text>&#9;</xsl:text>
            <xsl:text>rs autre</xsl:text>
            <xsl:text>&#xA;</xsl:text>
            
            <xsl:apply-templates select="$myCollection/descendant::tei:TEI" mode="countNames"/>
            
        </xsl:result-document>
        
        
    </xsl:template>
    
    
    
    <xsl:template match="tei:TEI">
        <xsl:value-of select="@xml:id"/>
        <xsl:variable name="myDoc" select="."/>
        <xsl:text>&#9;</xsl:text>
        <xsl:for-each select="$myTypes">
            <xsl:sort/>
            <xsl:variable name="currentType" select="."/>
            <xsl:value-of select="count($myDoc/descendant::tei:term[@type='nature' and @key = $currentType])"/>
            <xsl:if test="position() != last()">
                <xsl:text>&#9;</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text>&#xA;</xsl:text>
    </xsl:template>
    
    <xsl:template match="tei:TEI" mode="countNames">
        <xsl:value-of select="@xml:id"/>
        <xsl:text>&#9;</xsl:text>
        <xsl:value-of select="count(descendant::tei:placeName)"/>
        <xsl:text>&#9;</xsl:text>
        <xsl:value-of select="count(descendant::tei:persName)"/>
        <xsl:text>&#9;</xsl:text>
        <xsl:value-of select="count(descendant::tei:rs[@type='place'])"/>
        <xsl:text>&#9;</xsl:text>
        <xsl:value-of select="count(descendant::tei:rs[@type='person'])"/>
        <xsl:text>&#9;</xsl:text>
        <xsl:value-of select="count(descendant::tei:rs[not(@type=('person', 'place'))])"/>
        <xsl:text>&#xA;</xsl:text>
    </xsl:template>
    
    
</xsl:stylesheet>