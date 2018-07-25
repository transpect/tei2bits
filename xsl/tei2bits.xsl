<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:tei="http://www.tei-c.org/ns/1.0" 
  xmlns:tei2bits="http://transpect.io/tei2bits" 
  xmlns:saxon="http://saxon.sf.net/"
  xmlns:hub2htm="http://transpect.io/hub2htm"
  xmlns:xlink="http://www.w3.org/1999/xlink" 
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:tr="http://transpect.io"
  xmlns:mml="MathML Namespace Declaration"
  xpath-default-namespace="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tr hub2htm saxon tei2bits tei xsl xs" 
  version="2.0">
  
  <!-- This module expects a TEI document -->
  <xsl:import href="http://transpect.io/hub2html/xsl/css-atts2wrap.xsl"/>
  
  <xsl:param name="debug" select="'yes'"/>
  <xsl:param name="debug-dir-uri" select="'debug'"/>
  
  <xsl:variable name="root" select="/" as="document-node()"/>
  
  <xsl:key name="rule-by-name" match="css:rule" use="@name"/>
  <xsl:key name="by-id" match="*[@id | @xml:id]" use="@id | @xml:id"/>
  <xsl:key name="link-by-anchor" match="ref" use="@target"/>
  
  <!-- identity template -->
  <xsl:template match="* | @*" mode="tei2bits clean-up resort" priority="-0.5">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*" mode="class-att"/>

  <xsl:template match="@rend" mode="tei2bits">
    <xsl:attribute name="{if (..[self::hi | self::seg]) then 'style-type' else 'content-type'}" select="."/>
  </xsl:template>
  
  <xsl:template match="*" mode="tei2bits" priority="-0.25">
    <xsl:message>tei2bits: unhandled: <xsl:apply-templates select="." mode="css:unhandled"/> </xsl:message>
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:param name="css:wrap-namespace" as="xs:string" select="''"/> 
  
  <xsl:function name="css:other-atts" as="attribute(*)*">
    <xsl:param name="context" as="element(*)"/>
    <xsl:sequence select="$context/@*[not(css:map-att-to-elt(., ..))]"/> 
  </xsl:function>

  <xsl:template name="css:remaining-atts">
    <xsl:param name="remaining-atts" as="attribute(*)*"/>
    <xsl:apply-templates select="$remaining-atts" mode="#current"/>
  </xsl:template>

  <xsl:template match="@*" mode="hub2htm:css-style-overrides">
    <xsl:copy/>
  </xsl:template>
  
  <xsl:variable name="css:italic-elt-name" as="xs:string?" select="'italic'"/>
  <xsl:variable name="css:bold-elt-name" as="xs:string?" select="'bold'"/>
  <xsl:variable name="css:underline-elt-name" as="xs:string?" select="'underline'"/>
  <xsl:variable name="css:smallcaps-elt-name" as="xs:string?" select="'sc'"/>
  
  <xsl:template match="@css:text-decoration-line[. = ('underline')]" mode="css:map-att-to-elt" as="xs:string?">
    <xsl:param name="context" as="element(*)?"/>
    <xsl:sequence select="$css:underline-elt-name"/>
  </xsl:template>
  
  <xsl:template match="@css:font-variant[matches(., 'small-caps')]" mode="css:map-att-to-elt" as="xs:string?">
    <xsl:param name="context" as="element(*)?"/>
    <xsl:sequence select="$css:smallcaps-elt-name"/>
  </xsl:template>
  
  <xsl:template match="@srcpath| @css:version" mode="tei2bits">
    <xsl:copy/>
  </xsl:template>

  <xsl:template match="@xml:id" mode="tei2bits">
    <xsl:attribute name="id" select="."/>
  </xsl:template>

  <xsl:template match="@css:rule-selection-attribute" mode="tei2bits">
    <xsl:attribute name="{name()}" select="'content-type style-type'"/>
  </xsl:template>
  
  <xsl:template match="@*" mode="tei2bits" priority="-1.5">
    <xsl:message>tei2bits: unhandled attr: <xsl:apply-templates select="." mode="css:unhandled"/>
    </xsl:message>
  </xsl:template>
  
  <xsl:template match="@rendition" mode="tei2bits">
    <xsl:attribute name="specific-use" select="."/>
  </xsl:template>
  
  <xsl:template match="/*/@*[name() = ('source-dir-uri', 'xml:base')]" mode="jats2html">
    <xsl:copy/>
  </xsl:template>
  
  <xsl:template match="@xml:lang | @lang" mode="tei2bits">
    <xsl:copy/>
  </xsl:template>
  
  <xsl:template match="/*/@*[name() = ('version')]" mode="tei2bits">
    <xsl:attribute name="dtd-version" select="'2.0'" />
  </xsl:template>
  
  <xsl:template match="/TEI" mode="tei2bits">
    <book>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:call-template name="book-meta"/>
      <xsl:call-template name="front-matter"/>
      <xsl:call-template name="book-body"/>
      <xsl:call-template name="book-back"/>
    </book>
  </xsl:template>
  
  <xsl:template name="book-meta">
    <book-meta>
      <xsl:apply-templates select="teiHeader" mode="#current"/>
      <xsl:apply-templates select="//*[local-name() = $metadata-elements-in-content]" mode="#current">
        <xsl:with-param name="in-metadata" select="true()" as="xs:boolean" tunnel="yes"/>
      </xsl:apply-templates>
    </book-meta>
  </xsl:template>
  
  <xsl:variable name="metadata-elements-in-content" select="('docTitle', 'docAuthor', 'docDate', 'docEdition', 'docImprint')" as="xs:string*"/>
  
  <xsl:template name="front-matter">
    <xsl:if test="text/front">
      <front-matter>
        <xsl:apply-templates select="text/front" mode="#current"/>
      </front-matter>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="book-body">
    <book-body>
      <xsl:apply-templates select="text/body" mode="#current"/>
    </book-body>
  </xsl:template>
  
  <xsl:template name="book-back">
    <xsl:if test="text/back">
      <book-back>
        <xsl:apply-templates select="text/back" mode="#current"/>
      </book-back>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="bibl" mode="tei2bits">
    <ref>
      <xsl:apply-templates select="@*" mode="#current"/>
      <mixed-citation>
        <xsl:apply-templates select="node()" mode="#current"/>
      </mixed-citation>
    </ref>
  </xsl:template>
  
  <xsl:template match="biblFull" mode="tei2bits">
    <ref>
      <xsl:apply-templates select="@*" mode="#current"/>
      <element-citation>
        <xsl:apply-templates select="node()" mode="#current"/>
      </element-citation>
    </ref>
  </xsl:template>
  
  <xsl:template match="*[self::bibl | self::biblFull]//ref[matches(., 'DOI', 'i')]" mode="tei2bits">
    <pub-id>
      <xsl:attribute name="pub-id-type" select="'doi'"/>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </pub-id>
  </xsl:template>
 
  <xsl:function name="tei2bits:is-ref-list" as="xs:boolean">
    <xsl:param name="elt" as="element(div)"/>
    <xsl:sequence select="exists($elt[self::div[every $elt in * satisfies ($elt[self::listBibl[not(head)] or self::head])]])"/>
  </xsl:function>

  <xsl:template match="div[tei2bits:is-ref-list(.)]" mode="tei2bits" priority="2">
    <ref-list>
      <xsl:apply-templates select="@*, node()" mode="#current">
        <xsl:with-param name="dissolve-listBibl" as="xs:boolean?" tunnel="yes" select="true()"/>
      </xsl:apply-templates>
    </ref-list>
  </xsl:template>

  <xsl:template match="listBibl" mode="tei2bits" priority="2">
    <xsl:param name="dissolve-listBibl" as="xs:boolean?" tunnel="yes"/>
    <!-- if ancestor div is the ref-list aready-->
    <xsl:choose>
      <xsl:when test="$dissolve-listBibl">
         <xsl:apply-templates select="node()" mode="#current"/>
      </xsl:when>
      <xsl:otherwise>
        <ref-list>
          <xsl:apply-templates select="@*, node()" mode="#current"/>
        </ref-list>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="table/@rendition[matches(., '\.(png|jpe?g)$', 'i')]" mode="tei2bits">
    <alternatives>
      <xsl:for-each select="tokenize(., ' ')">
        <graphic xlink:href="{.}"/>
      </xsl:for-each>
    </alternatives>
  </xsl:template>
  
  <xsl:template match="table" mode="tei2bits">
    <table-wrap>
      <xsl:if test="head or note">
        <caption>
          <xsl:apply-templates select="head, note" mode="#current"/>
        </caption>
      </xsl:if>
      <table>
        <xsl:apply-templates select="@* except (@rend, @rendition)" mode="#current"/>
        <xsl:apply-templates select="@rendition" mode="#current"/>
        <xsl:apply-templates select="node() except (head, note, postscript)" mode="#current"/>
      </table>
      <xsl:apply-templates select="postscript" mode="#current"/>
    </table-wrap>
  </xsl:template>
  
  <xsl:template match="table/@rend[. = 'hub:right-tab']" mode="tei2bits" priority="2">
    <xsl:attribute name="content-type" select="'right-tab'"/>
  </xsl:template>
  
  <xsl:template match="teiHeader | text | fileDesc | seriesStmt | publicationStmt | encodingDesc | editionStmt/p | text/front | text/body | text/back | opener[idno]" mode="tei2bits">
    <xsl:apply-templates select="node()" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="textClass" mode="tei2bits">
    <xsl:apply-templates select="node() except keywords[@corresp]" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="profileDesc" mode="tei2bits">
    <xsl:apply-templates select="node() except abstract[@corresp]" mode="#current"/>
  </xsl:template>

  <xsl:template match="editionStmt" mode="tei2bits">
    <edition>
      <xsl:apply-templates select="node()" mode="#current"/>
    </edition>
  </xsl:template>

  <xsl:template match="seriesStmt/biblScope[@unit = 'volume']" mode="tei2bits">
    <book-volume-number>
      <xsl:apply-templates select="node()" mode="#current"/>
    </book-volume-number>
  </xsl:template>

  <xsl:template match="seriesStmt/idno[@type = 'issn']" mode="tei2bits">
    <issn>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </issn>
  </xsl:template>

  <xsl:template match="seriesStmt/idno[@type = ('doi', 'poi', 'isbn')]" mode="tei2bits">
    <book-id book-id-type="{@type}">
      <xsl:apply-templates select="node()" mode="#current"/>
    </book-id>
  </xsl:template>

  <xsl:template match="publicationStmt/idno" mode="tei2bits">
    <xsl:if test="normalize-space()">
      <book-id book-id-type="doi">
        <xsl:apply-templates select="node()" mode="#current"/>
      </book-id>
    </xsl:if>
  </xsl:template>

  <xsl:template match="persName[@type = 'author']/roleName" mode="tei2bits" priority="3">
    <xsl:element name="{if (matches(., '(Dr|Prof)\.')) then 'prefix' else 'role'}">
        <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="*:contrib[*:name[*:role]]" mode="clean-up">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
      <role><xsl:value-of select="*:name/*:role"/></role>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*:contrib/*:name/*:role | *:contrib/*:name/*:styled-content" mode="clean-up"/>

  <xsl:template match="publicationStmt/date[normalize-space()]" mode="tei2bits">
    <pub-date>
      <string-date>
        <xsl:apply-templates select="node()" mode="#current"/>
      </string-date>
    </pub-date>
  </xsl:template>

  <xsl:template match="publicationStmt/publisher | titlePage/docImprint" mode="tei2bits">
    <publisher>
      <publisher-name>
        <xsl:apply-templates select="@*, node()" mode="#current"/>
      </publisher-name>
      <xsl:if test="..[normalize-space(pubPlace[1])]">
        <publisher-loc>
          <xsl:value-of select="normalize-space(../pubPlace[1])"/>
        </publisher-loc>
      </xsl:if>
    </publisher>
  </xsl:template>

  <xsl:template match="titleStmt" mode="tei2bits">
    <xsl:if test="editor">
      <contrib-group>
        <xsl:apply-templates select="editor" mode="#current"/>
      </contrib-group>
    </xsl:if>
    <xsl:if test="title[@type = 'main']">
      <book-title-group>
        <book-title>
          <xsl:value-of select="title[@type = 'main']"/>
        </book-title>
        <xsl:if test="title[@type = 'sub']">
          <subtitle>
            <xsl:value-of select="title[@type = 'sub']"/>
          </subtitle>
        </xsl:if>
        <xsl:if test="title[@type = 'issue-title']">
          <subtitle content-type="issue-title">
            <xsl:value-of select="title[@type = 'issue-title']"/>
          </subtitle>
        </xsl:if>
      </book-title-group>
    </xsl:if>
    <!-- needed for metadata. other information is retrieved differently -->
  </xsl:template>

  <xsl:template match="seriesStmt/idno/@subtype" mode="tei2bits">
    <xsl:attribute name="content-type" select="."/>
  </xsl:template>


  <xsl:template match="publicationStmt/distributor |  publicationStmt/pubPlace | sourceDesc | styleDefDecl | langUsage" mode="tei2bits">
    <!-- perhaps later -->
  </xsl:template>
  
  <xsl:template match="keywords" mode="tei2bits">
    <xsl:choose>
      <xsl:when test="term[@xml:lang]">
        <xsl:for-each-group select="term" group-by="@xml:lang">
          <kwd-group kwd-group-type="keyword">
            <xsl:attribute name="xml:lang" select="current-grouping-key()"/>
            <xsl:for-each select="current-group()">
              <kwd>
                <xsl:apply-templates select="@id, @key" mode="#current"/>
                <xsl:value-of select="."/>
              </kwd>
            </xsl:for-each>
          </kwd-group>
        </xsl:for-each-group>
      </xsl:when>
      <xsl:otherwise>
        <kwd-group>
          <xsl:apply-templates select="term[1]/@xml:lang" mode="#current"/>
          <xsl:for-each select="term">
            <kwd>
              <xsl:apply-templates select="@id, @key" mode="#current"/>
              <xsl:value-of select="."/>
            </kwd>
          </xsl:for-each>
        </kwd-group>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="keywords/term/@key" mode="tei2bits">
    <xsl:attribute name="content-type" select="."/>
  </xsl:template>

  <xsl:template match="css:rules" mode="tei2bits">
    <custom-meta-group>
      <xsl:copy>
        <xsl:apply-templates select="node()" mode="#current"/>
      </xsl:copy>
    </custom-meta-group>
  </xsl:template>
  
  <xsl:template match="css:rule" mode="tei2bits">
    <xsl:call-template name="css:move-to-attic">
      <xsl:with-param name="atts" select="@*[css:map-att-to-elt(., current())]"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="*:tabs | *:tabs/*:tab | css:attic" mode="tei2bits" priority="2">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="titlePage" mode="tei2bits">
    <front-matter-part book-part-type="title-page">
      <named-book-part-body>
        <xsl:apply-templates select="@*, node()" mode="#current"/>
      </named-book-part-body>
    </front-matter-part>
  </xsl:template>
  
  <xsl:variable name="frontmatter-parts" as="xs:string+"
    select="('title-page', 'copyright-page', 'about-contrib', 'about-book', 'series', 'additional-info', 'motto', 'preface')"/>
  
  <xsl:template match="div[@type = $frontmatter-parts]" mode="tei2bits" priority="2">
    <front-matter-part book-part-type="{@type}">
      <xsl:call-template name="named-book-part-meta"/>
      <xsl:call-template name="named-book-part-body"/>
      <xsl:call-template name="book-part-back"/>
    </front-matter-part>
  </xsl:template>
  
  <xsl:template match="div[@type = 'dedication']" mode="tei2bits">
    <dedication book-part-type="{@type}">
      <xsl:call-template name="named-book-part-meta"/>
      <xsl:call-template name="named-book-part-body"/>
      <xsl:call-template name="book-part-back"/>
    </dedication>
  </xsl:template>
  
  <xsl:template match="docTitle" mode="tei2bits">
    <xsl:param name="in-metadata" as="xs:boolean?" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="$in-metadata">
        <xsl:if test="not(/TEI/teiHeader/fileDesc/titleStmt/title[@type = 'main'])">
          
          <book-title-group>
            <xsl:apply-templates select="@*, node()" mode="#current"/>
          </book-title-group>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates mode="#current"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="editor | author" mode="tei2bits" priority="2">
    <xsl:element name="contrib">
      <xsl:attribute name="contrib-type" select="local-name()"/>
      <xsl:apply-templates select="@* except @role, node(), @role" mode="#current"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="editor/@role | author/@role" mode="tei2bits" priority="2">
    <role>
      <xsl:value-of select="."/>
    </role>
  </xsl:template>

  <xsl:template match="byline/location" mode="tei2bits" priority="2">
    <xsl:choose>
      <xsl:when test="address">
        <xsl:apply-templates select="node()" mode="#current"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="address">
          <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="byline/ref" mode="tei2bits" priority="2">
    <xsl:element name="ext-link">
      <xsl:attribute name="href" select="@target"/>
      <xsl:attribute name="ext-link-type" select="if (matches(@target, 'mail|@')) then 'email' else 'uri'"/>
      <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="docTitle/titlePart[not(@type) or @type = 'main']" mode="tei2bits" priority="2">
    <xsl:param name="in-metadata" as="xs:boolean?" tunnel="yes"/>
    <xsl:element name="{if ($in-metadata) then 'book-title' else 'p'}">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="docTitle/titlePart[@type]" mode="tei2bits">
    <xsl:param name="in-metadata" as="xs:boolean?" tunnel="yes"/>
    <xsl:element name="{if ($in-metadata) then 'subtitle' else 'p'}">
      <xsl:call-template name="css:content">
        <xsl:with-param name="root" select="$root" tunnel="yes" as="document-node()"/>
      </xsl:call-template>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="docAuthor" mode="tei2bits">
    <xsl:choose>
      <xsl:when test="ancestor::*[self::title-page]">
        <p>
          <xsl:apply-templates select="@*, node()" mode="#current"/>
        </p>
      </xsl:when>
      <xsl:otherwise>
        <contrib>
          <xsl:apply-templates select="@*" mode="#current"/>
           <xsl:if test="persName[@type]">
              <xsl:attribute name="contrib-type" select="persName/@type"/>
          </xsl:if>
          <xsl:choose>
            <xsl:when test="every $n in node() satisfies $n[self::text()]">
              <string-name>
                <xsl:apply-templates mode="#current"/>
              </string-name>
            </xsl:when>
            <xsl:otherwise>
              <!-- assuming tagged names-->
              <xsl:apply-templates mode="#current"/>
            </xsl:otherwise>
          </xsl:choose>
        </contrib>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="byline/@rend" mode="tei2bits">
    <!-- perhaps extract contrib-type from style name -->
  </xsl:template>

  <xsl:template match="byline" mode="tei2bits">
    <xsl:choose>
      <xsl:when test="not(persName)">
        <contrib contrib-type="author">
          <xsl:apply-templates select="@*, node()" mode="#current"/>
        </contrib>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each-group select="node()" group-starting-with="persName[not(preceding-sibling::*[1][self::graphic])] | graphic[following-sibling::*[1][self::parsName]]">
          <xsl:for-each-group select="current-group()" group-adjacent="boolean(.[self::persName | self::location | self::graphic])">
            <xsl:choose>
              <xsl:when test="current-grouping-key()">
                <contrib contrib-type="{(current-group()[self::persName]/@type, 'author')[1]}">
                  <xsl:apply-templates select="current-group()" mode="#current"/>
                </contrib>
              </xsl:when>
              <xsl:when test="current-group()[self::text()]"/>
              <xsl:otherwise>
                <xsl:apply-templates select="current-group()" mode="#current"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each-group>
        </xsl:for-each-group>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="byline/graphic" mode="tei2bits" priority="3">
    <!-- TO DO: has to be further specified-->
    <bio>
      <graphic>
        <xsl:apply-templates select="@*, node()" mode="#current"/>
      </graphic>
    </bio>
  </xsl:template>

  <xsl:template match="divGen[@type = 'toc']" mode="tei2bits">
    <toc>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:if test="head">
        <toc-title-group>
          <xsl:apply-templates select="head" mode="#current"/>
        </toc-title-group>
      </xsl:if>
      <xsl:apply-templates select="node() except head" mode="#current"/>
      <xsl:if test="every $elt in * satisfies ($elt[self::head])">
        <toc-entry/>
      </xsl:if>
    </toc>
  </xsl:template>
  
  <xsl:template match="preface" mode="tei2bits">
    <foreword book-part-type="foreword">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:call-template name="named-book-part-meta"/>
      <xsl:call-template name="named-book-part-body"/>
    </foreword>
  </xsl:template>
  
  <xsl:template name="named-book-part-body">
    <xsl:element name="named-book-part-body">
      <xsl:apply-templates select="node() except (head, byline, opener, p[@rend = 'artpagenums'])" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template name="named-book-part-meta">
    <xsl:if test="head or byline">
      <xsl:element name="book-part-meta">
        <xsl:element name="title-group">
          <xsl:apply-templates select="head" mode="#current"/>
        </xsl:element>
          <xsl:apply-templates select="byline" mode="#current"/>
      </xsl:element>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="add | emph | orig | date |  unclear| orgName | placeName | state" mode="tei2bits">
    <xsl:element name="named-content">
      <xsl:call-template name="css:content">
        <xsl:with-param name="root" select="$root" tunnel="yes" as="document-node()"/>
      </xsl:call-template>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="@rendition[. = ('subscript', 'superscript')]" mode="tei2bits"/>
  
  <xsl:template match="seg | hi" mode="tei2bits">
    <styled-content>
      <xsl:call-template name="css:content">
        <xsl:with-param name="root" select="$root" tunnel="yes" as="document-node()"/>
      </xsl:call-template>
    </styled-content>
  </xsl:template>
  
  <xsl:template match="underline" mode="tei2bits">
    <u>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </u>
  </xsl:template>
  
  <xsl:template match="emph" mode="tei2bits">
    <italic>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </italic>
  </xsl:template>
  
  <xsl:template match="hi[@specific-use = ('superscript', 'subscript')] | hi[key('rule-by-name', @rend, $root)[@css:vertical-align = ('sub', 'super')]]" mode="tei2bits" priority="2">
    <xsl:element name="{if (@specific-use = 'superscript' or key('rule-by-name', @rend, $root)[@css:vertical-align = 'super']) then 'sup' else 'sub'}">
      <xsl:apply-templates select="@* except @rend, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="persName[surname and forename]" mode="tei2bits" priority="2">
    <name>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates select="surname, forename, node() except (text()[1], surname, forename)" mode="#current"/>
      <xsl:if test="node()[1][self::text()[matches(., '\S')]]">
        <prefix>
          <xsl:value-of select="normalize-space(text()[1])"/>
        </prefix>
      </xsl:if>
    </name>
  </xsl:template>
  
  <xsl:template match="name | persName[not(surname) and not(forename)]" mode="tei2bits" priority="2">
    <string-name>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </string-name>
  </xsl:template>
  
  <xsl:template match="surname" mode="tei2bits">
    <surname>
      <xsl:apply-templates select="@* except @rend" mode="#current"/>
      <xsl:value-of select="normalize-space(replace(text(), '(^|\p{Zs})(de|von|van)([^\p{L}]|$)', '$3', 'i'))"/>
    </surname>
    <xsl:if test="matches(text(), '(^|\p{Zs})(de|von|van)([^\p{L}]|$)', 'i')">
      <suffix content-type="particle">
        <xsl:value-of select="normalize-space(replace(text(), '(^|\p{Zs})(de|von|van)(\p{Zs}(de|von|van))*([^\p{L}].*$|$)', '$1$2', 'i'))"/>
      </suffix>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="forename" mode="tei2bits">
    <given-names>
      <xsl:apply-templates select="@* except @rend" mode="#current"/>
      <xsl:value-of select="normalize-space(replace(text(), '\p{Zs}(de|von|van)', '', 'i'))"/>
    </given-names>
    <xsl:if test="matches(text(), '\p{Zs}(de|von|van)', 'i')">
      <suffix content-type="particle">
        <xsl:value-of select="normalize-space(replace(text(), '^.+?\p{Zs}(de|von|van)(\p{Zs}(de|von|van)))*([\P{L}].*$|$)', '$1$2', 'i'))"/>
      </suffix>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="*:name" mode="resort">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, *:surname, *:given-names, *:prefix, *:suffix" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="ref[starts-with(@target, '#')] | ptr[starts-with(@target, '#')] " mode="tei2bits" priority="5">
    <xref>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xref>
  </xsl:template>
  
  <xsl:template match="ref[starts-with(., 'mailto:')]" mode="tei2bits" priority="7">
    <email>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </email>
  </xsl:template>

  <xsl:template match="ref[starts-with(@target, '#')]/@target" mode="tei2bits" priority="2">
    <xsl:attribute name="rid" select="."/>
  </xsl:template>
  
  <xsl:template match="ref | ptr " mode="tei2bits">
    <ext-link>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </ext-link>
  </xsl:template>
  
  <xsl:template match="ref/@target" mode="tei2bits">
    <xsl:attribute name="xlink:href" select="."/>
  </xsl:template>
  
  <xsl:template match="formula/@n" mode="tei2bits"/>
  
  <xsl:template match="formula" mode="tei2bits">
    <xsl:element name="{if (@rend = 'inline') then 'inline-formula' else 'disp-formula'}">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="floatingText" mode="tei2bits">
    <boxed-text>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </boxed-text>
  </xsl:template>
  
  <xsl:template match="floatingText/front | floatingText/back" mode="tei2bits">
    <sec content-type="{local-name()}">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </sec>
  </xsl:template>
  
  <xsl:template match="floatingText/body" mode="tei2bits">
    <xsl:apply-templates select="node()" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="floatingText/body/*[local-name() = ('div1', 'div2', 'div3', 'div4', 'div5')]" mode="tei2bits" priority="2">
    <sec>
      <xsl:apply-templates select="node()" mode="#current"/>
    </sec>
  </xsl:template>
  
  <xsl:template match="abstract" mode="tei2bits">
    <abstract>
      <xsl:apply-templates select="@* except @corresp, node()" mode="#current"/>
    </abstract>
  </xsl:template>

  <xsl:template match="abstract[@xml:lang ne /*/@xml:lang] | argument[@xml:lang ne /*/@xml:lang]" mode="tei2bits" priority="2">
    <trans-abstract>
      <xsl:apply-templates select="@* except @corresp, node()" mode="#current"/>
    </trans-abstract>
  </xsl:template>
  
  <xsl:variable name="structural-containers" as="xs:string+" select="('dedication', 'marginal', 'motto', 'part', 'article', 'chapter')"/>
  <xsl:variable name="main-structural-containers" as="xs:string+" select="('part', 'article', 'book-review', 'chapter')"/>

  <!-- document structure -->
  <xsl:template mode="tei2bits" match="div[not(@type = $structural-containers)] | *[matches(local-name(), 'div[1-9]')]">
    <sec>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:call-template name="sec-meta"/>
      <xsl:call-template name="sec-body"/>
    </sec>
  </xsl:template>
  
  <xsl:template name="sec-meta">
    <xsl:if test="byline or abstract or keywords or argument or opener[idno] or p[@rend = 'artpagenums']">
      <sec-meta>
        <xsl:apply-templates select="byline, opener[idno], abstract, argument, keywords, p[@rend = 'artpagenums']" mode="#current"/>
      </sec-meta>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="sec-body">
    <xsl:apply-templates select="node() except (opener[idno], byline, abstract, argument, keywords, p[@rend = 'artpagenums'])" mode="#current"/>
  </xsl:template>
  
  <xsl:template mode="tei2bits" priority="2" match="*[self::div[not(@type = ($structural-containers, 'bibliography'))] | *[matches(local-name(), 'div[1-9]')]]/@rend">
    <xsl:attribute name="sec-type" select="."/>
  </xsl:template>

  <xsl:template match="div[@type = $main-structural-containers]" mode="tei2bits" priority="3">
    <book-part>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:call-template name="book-part-meta"/>
      <xsl:call-template name="book-part-front-matter"/>
      <xsl:call-template name="book-part-body"/>
      <xsl:call-template name="book-part-back"/>
    </book-part>
  </xsl:template>

  <xsl:template match="div[@type = $main-structural-containers]/@rend" mode="tei2bits" priority="3"/>
  <xsl:key name="tei2bits:corresp-meta" match="/TEI/teiHeader/profileDesc/textClass/keywords | /TEI/teiHeader/profileDesc/abstract" use="@corresp"/>

  <xsl:template name="book-part-meta">
    <book-part-meta>
      <xsl:apply-templates select="opener[idno]" mode="#current"/>
      <title-group>
        <xsl:apply-templates select="head" mode="#current"/>
      </title-group>
      <xsl:apply-templates select="byline, dateline, abstract, argument, key('tei2bits:corresp-meta', concat('#', current()/@xml:id))[self::abstract], keywords, key('tei2bits:corresp-meta', concat('#', current()/@xml:id))[self::keywords], p[@rend = 'artpagenums']" mode="#current"/>
    </book-part-meta>
  </xsl:template>
  
  <xsl:template name="book-part-front-matter">
    <xsl:if test="divGen[@type = 'toc'] or div[@type = 'dedication']">
      <front-matter>
        <xsl:apply-templates select="*[self::divGen[@type = 'toc'] | div[@type = 'dedication']]" mode="#current"/>
      </front-matter>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="book-part-body">
    <body>
      <xsl:apply-templates select="node() except (opener[idno], byline, head, dateline, abstract, argument, keywords, p[@rend = 'artpagenums'], div[@type = ('dedication', 'index', 'app', 'appendix', 'bibliography')], div[tei2bits:is-ref-list(.)], divGen[@type = ('toc', 'index')], listBibl)" mode="#current"/>
    </body>
  </xsl:template>
  
  <xsl:template name="book-part-back">
    <xsl:if test="some $elt in * satisfies $elt[self::div[@type = ('index', 'app', 'appendix', 'bibliography')] | self::divGen[@type = 'index'] | self::listBibl | self::div[tei2bits:is-ref-list(.)]]">
      <back>
        <xsl:apply-templates select="*[self::div[@type = ('index', 'app', 'appendix', 'bibliography')] | self::div[tei2bits:is-ref-list(.)] | self::divGen[@type = 'index'] | self::listBibl]" mode="#current"/>
      </back>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="@type" mode="tei2bits" priority="2"/>
  
  <xsl:template match="div[@type = $main-structural-containers]/@subtype" mode="tei2bits" priority="3">
    <xsl:attribute name="book-part-type" select="."/>
  </xsl:template>

  <xsl:template match="div[@type = $main-structural-containers]/opener[every $n in node()[normalize-space()] satisfies $n[self::idno]]/idno" mode="tei2bits">
    <book-part-id>
       <xsl:apply-templates select="@*, node()" mode="#current"/>
    </book-part-id>
  </xsl:template>

  <xsl:template match="div[@type = $main-structural-containers]/opener[every $n in node()[normalize-space()] satisfies $n[self::idno]]/idno/@type" mode="tei2bits" priority="4">
    <xsl:attribute name="book-part-id-type" select="lower-case(.)"/>
  </xsl:template>

  <xsl:template match="argument" mode="tei2bits">
    <abstract>
      <xsl:call-template name="css:content"/>
    </abstract>
  </xsl:template>

  <xsl:template match="p[@rend = 'artpagenums']" mode="tei2bits">
    <xsl:choose>
      <xsl:when test="matches(., '\d+\p{Zs}*[-–]\p{Zs}*\d+')">
        <fpage>
          <xsl:value-of select="replace(., '^[^\d]*(\d+)\p{Zs}*[-–]\p{Zs}*\d+.*$', '$1')"/>
        </fpage>
        <lpage>
          <xsl:value-of select="replace(., '^[^\d]*\d+\p{Zs}*[-–]\p{Zs}*(\d+).*$', '$1')"/>
        </lpage>
      </xsl:when>
      <xsl:when test="matches(., '^\d+$')">
        <fpage>
          <xsl:value-of select="."/>
        </fpage>
        <lpage>
          <xsl:value-of select="."/>
        </lpage>
      </xsl:when>
      <xsl:otherwise>
        <notes>
          <product><page-range><xsl:apply-templates select="node()" mode="#current"/></page-range></product>
        </notes>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Not handled yet or no equivalent elements determined yet-->
  <!--
    
    <xsl:template match="postscript" mode="tei2bits_UNHANDLED">
    <div>
    <xsl:call-template name="css:content"/>
    </div>
    </xsl:template>
    
  -->
  
  <xsl:template match="epigraph" mode="tei2bits">
    <disp-quote>
      <xsl:attribute name="content-type" select="'epigraph'"/>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </disp-quote>
  </xsl:template>

  <xsl:template match="state/label" mode="tei2bits" priority="2">
    <xsl:apply-templates select="node()" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="head/label | p/label" mode="tei2bits">
    <label>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </label>
  </xsl:template>

  <xsl:template match="pb" mode="tei2bits">
    <xsl:processing-instruction name="pagebreak"/>
  </xsl:template>
  
  <xsl:template match="dateline" mode="tei2bits">
    <date>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </date>
  </xsl:template>
  
  <!-- lists -->
  
  <xsl:template match="list[@type eq 'gloss']" mode="tei2bits">
    <def-list>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="node()" group-starting-with="*[self::label]">
        <xsl:choose>
          <xsl:when test="current-group()[1][self::label]">
            <def-item>
              <xsl:apply-templates select="current-group()" mode="#current"/>
            </def-item>
          </xsl:when>
          <xsl:otherwise>
             <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>  
      </xsl:for-each-group>
    </def-list>
    <!-- example -->
    <!--<list type="gloss" rend="def_table">
      <label rend="p_term"></label>
      <item rend="varlistentry"><gloss rend="p_definition"></gloss></item>
      </list>-->
  </xsl:template>
  
  <xsl:template match="list[@type eq 'gloss']/item[preceding-sibling::*[1][self::label]] | item[tei2bits:is-varlistentry(.)]" mode="tei2bits">
    <def>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </def>
  </xsl:template>
  
  <!--  <xsl:template match="list[@type eq 'gloss']/gloss[label]" mode="tei2bits">
    <def-item>
    <xsl:apply-templates select="@*, label" mode="#current"/>
    <def>
    <xsl:apply-templates select="node() except label" mode="#current"/>
    </def>
    </def-item>
    </xsl:template>-->
  
  <xsl:template match="list[@type eq 'gloss']/label | label[tei2bits:is-varlistentry(following-sibling::*[1][self::item])] | list[@type eq 'gloss']/item/label" mode="tei2bits">
    <term>
      <xsl:apply-templates select="@* except @rend, node()" mode="#current"/>
    </term>
  </xsl:template>
  
  <xsl:function name="tei2bits:is-varlistentry" as="xs:boolean">
    <xsl:param name="item" as="element(item)?"/>
    <xsl:sequence select="$item/parent::list[@type eq 'gloss'] or $item/@rend = 'varlistentry'"/>
  </xsl:function>
  
  <xsl:template match="item[tei2bits:is-varlistentry(.)]/gloss" mode="tei2bits">
    <p>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </p>
  </xsl:template>
  
  <xsl:template match="list" mode="tei2bits">
    <list>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </list>
  </xsl:template>
  
  <xsl:template match="list/@type" mode="tei2bits" priority="3">
    <xsl:attribute name="list-type" select="../@style"/>
  </xsl:template>
  
  <xsl:template match="item[not(tei2bits:is-varlistentry(.))]" mode="tei2bits">
    <list-item>
      <xsl:apply-templates select="@* except @n" mode="#current"/>
      <xsl:if test="@n">
        <label><xsl:value-of select="@n"/></label>
      </xsl:if>
      <xsl:apply-templates select="node()" mode="#current"/>
    </list-item>
  </xsl:template>
  
  <xsl:template match="item/@n | list/@style | list/item/@rend" mode="tei2bits"/>

    <xsl:template match="*:fn/*:p[1]/*:label" mode="clean-up"/>

  <xsl:template match="anchor" mode="tei2bits" priority="2">
    <target>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </target>
  </xsl:template>
  
  <xsl:template match="quote" mode="tei2bits">
    <disp-quote>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </disp-quote>
  </xsl:template>
  
  <xsl:template match="note" mode="tei2bits">
    <fn>
      <xsl:apply-templates select="@* except @n, @n" mode="#current"/>
      <xsl:if test="not(@n)">
        <xsl:apply-templates select="p[1]/label" mode="#current"/>
      </xsl:if>
      <xsl:apply-templates select="node()" mode="#current"/>
    </fn>
  </xsl:template>
  
  <xsl:template match="note[@type = 'footnote']/@n" mode="tei2bits">
    <label><xsl:value-of select="."/></label>
  </xsl:template>

  <xsl:template match="note[not(@type = 'footnote')]/p" mode="tei2bits" priority="2">
    <p>
      <xsl:call-template name="css:content">
        <xsl:with-param name="root" select="$root" tunnel="yes" as="document-node()"/>
      </xsl:call-template>
    </p>
  </xsl:template>
  
  <xsl:template match="p" mode="tei2bits">
    <p>
      <xsl:call-template name="css:content"/>
    </p>
  </xsl:template>
  
  <xsl:template match="lb" mode="tei2bits">
    <xsl:choose>
      <xsl:when test="parent::*[not(self::p) and not(self::hi) and not(self::seg)]">
        <break/>
      </xsl:when>
      <xsl:otherwise>
        <named-content content-type="break"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="figure" mode="tei2bits">
    <fig>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:if test="head or note">
        <caption>
          <xsl:apply-templates select="head, note" mode="#current"/>
        </caption>
      </xsl:if>
      <xsl:apply-templates select="node() except (head, note, bibl[@type = 'copyright'])" mode="#current"/>
      <xsl:if test="bibl[@type = 'copyright']">
        <permissions>
          <xsl:apply-templates select="bibl[@type = 'copyright']" mode="#current"/>
        </permissions>
      </xsl:if>
    </fig>
  </xsl:template>
  
  <xsl:template match="figure/bibl[@type = 'copyright']" mode="tei2bits">
    <copyright-statement>
      <xsl:apply-templates select="@* except @type, node()" mode="#current"/>
    </copyright-statement>
  </xsl:template>

  <xsl:template match="graphic/@rend" mode="tei2bits"/>
  
  <xsl:template match="graphic/@url" mode="tei2bits">
    <xsl:attribute name="xlink:href" select="."/>
  </xsl:template>
  
  <xsl:template match="index" mode="tei2bits">
    <index-term>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </index-term>
  </xsl:template>
  
  <xsl:template match="term | see | see-also | graphic[parent::*[self::figure]] | preformat | address | country" mode="tei2bits">
    <xsl:element name="{local-name()}" exclude-result-prefixes="#all">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="graphic/desc" mode="tei2bits">
    <alt-text>
      <xsl:apply-templates select="node()" mode="#current"/>
    </alt-text>
  </xsl:template>

  <xsl:template match="addrLine" mode="tei2bits">
    <xsl:element name="addr-line" exclude-result-prefixes="#all">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="postCode" mode="tei2bits">
    <xsl:element name="postal-code" exclude-result-prefixes="#all">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="settlement[@type = 'city']" mode="tei2bits">
    <xsl:element name="{@type}" exclude-result-prefixes="#all">
      <xsl:apply-templates select="@* except @type, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="graphic[not(parent::*[self::figure])]" mode="tei2bits">
    <inline-graphic>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </inline-graphic>
  </xsl:template>

  <xsl:template match="@preformat-type" mode="tei2bits">
    <xsl:attribute name="{name()}" select="."/>
  </xsl:template>
  
  <xsl:template match="tbody | thead | tfoot | th | tr | td | colgroup | col" mode="tei2bits">
    <xsl:element name="{local-name()}" exclude-result-prefixes="#all">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="lg" mode="tei2bits">
    <verse-group>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </verse-group>
  </xsl:template>
  
  <xsl:template match="lg/l" mode="tei2bits">
    <verse-line>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </verse-line>
  </xsl:template>
  
  <xsl:template match="spGrp" mode="tei2bits">
    <xsl:apply-templates select="node()" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="sp" mode="tei2bits">
    <speech>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </speech>
  </xsl:template>
  
  <xsl:template match="stage" mode="tei2bits">
    <p>
      <xsl:call-template name="css:content">
        <xsl:with-param name="root" select="$root" tunnel="yes" as="document-node()"/>
      </xsl:call-template>
    </p>
  </xsl:template>
  
  <xsl:template match="speaker" mode="tei2bits">
    <speaker>
      <xsl:call-template name="css:content">
        <xsl:with-param name="root" select="$root" tunnel="yes" as="document-node()"/>
      </xsl:call-template>
    </speaker>
  </xsl:template>
  
  <xsl:template match="sp/l" mode="tei2bits">
    <p>
      <xsl:call-template name="css:content">
        <xsl:with-param name="root" select="$root" tunnel="yes" as="document-node()"/>
      </xsl:call-template>
    </p>
  </xsl:template>
  
  <!-- TO DO: label handling-->
  <xsl:template match="head[not(parent::*[self::table | self::figure])]" mode="tei2bits">
    <title>
      <xsl:call-template name="css:content">
        <xsl:with-param name="root" select="$root" tunnel="yes" as="document-node()"/>
      </xsl:call-template>
    </title>
  </xsl:template>
  
  <xsl:template match="head[parent::*[self::table | self::figure]]" mode="tei2bits">
      <title>
        <xsl:call-template name="css:content">
          <xsl:with-param name="root" select="$root" tunnel="yes" as="document-node()"/>
        </xsl:call-template>
      </title>
  </xsl:template>

  <xsl:template match="head[@type = 'sub']" mode="tei2bits" priority="2">
    <subtitle>
      <xsl:call-template name="css:content">
        <xsl:with-param name="root" select="$root" tunnel="yes" as="document-node()"/>
      </xsl:call-template>
    </subtitle>
  </xsl:template>
  
  <xsl:template match="caption" mode="tei2bits">
    <caption>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </caption>
  </xsl:template>
  
  <xsl:template match="*[*:contrib][not(self::*:contrib-group)]" mode="clean-up" priority="3">
      <xsl:copy copy-namespaces="no">
        <xsl:variable name="context" select="." as="element(*)"/>
        <xsl:for-each-group select="node()" group-by="local-name()">
          <xsl:choose>
            <xsl:when test="current-grouping-key() = 'contrib'">
              <xsl:element name="contrib-group">
                <xsl:for-each select="current-group()">
                  <xsl:apply-templates select="." mode="#current"/>
                  <xsl:if test="not(*:bio) and not(ancestor::*[self::*:front-matter-part[@book-part-type='editorial']]) and *:name">
                    <xsl:call-template name="contrib-bio"/>
                  </xsl:if>
                </xsl:for-each>
              </xsl:element>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="current-group()" mode="#current"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each-group>
      </xsl:copy>
  </xsl:template>

  <xsl:template match="div[@type = 'contrib-bio' or @rend = 'contrib-bio']" mode="tei2bits" priority="5">
    <bio>
      <xsl:apply-templates select="node()" mode="#current"/>
    </bio>
  </xsl:template>

  <!-- clean up mode -->

  <xsl:template match="*:bio" mode="clean-up" priority="2">
    <xsl:param name="render-bio" as="xs:boolean?" tunnel="yes"/>
    <xsl:if test="$render-bio or parent::*[self::*:contrib]">
      <xsl:next-match/>
    </xsl:if>
  </xsl:template>

  <xsl:key name="tei2bits:bio-by-name" match="*:bio" use="normalize-space(replace(string-join(*:p[1]/*[1]//text(), ''), '^(.+?)[:,]\p{Zs}*$', '$1'))"/>

  <xsl:template name="contrib-bio">
  <!-- mehrere Artikelautoren hier nicht berücksichtigt. Müsste dann pro contrib aufgerufen werden!-->
    <xsl:apply-templates select="key('tei2bits:bio-by-name', normalize-space(string-join((.//*:given-names/text(), .//*:suffix/text(), .//*:surname/text()),  ' ')))[1]" mode="#current">
      <xsl:with-param name="render-bio" select="true()" as="xs:boolean" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="*:contrib/*:bio[every $elt in * satisfies ($elt[self::*:graphic])]" mode="clean-up">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="key('tei2bits:bio-by-name', normalize-space(string-join((../*:name/*:given-names/text(), ../*:name/*:surname/text()),  ' ')))[1]/node()" mode="#current">
        <xsl:with-param name="render-bio" select="true()" as="xs:boolean" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*:book-meta" mode="resort" priority="2">
    <xsl:copy  copy-namespaces="no">
    <!-- bringing the meta elements into the correct order -->
      <xsl:apply-templates select="@*, *:book-id, *:subj-group, *:book-title-group, *:contrib-group, *:aff, *:aff-affiliates, 
        *:author-notes, *:pub-date, *:book-volume-number, *:book-volume-id, *:issn, *:issn-l, *:isbn, *:publisher, *:edition, 
         *:supplementary-material, *:pub-history, *:permissions, *:self-uri, *:related-article, *:related-object, *:abstract, 
        *:trans-abstract, *:kwd-group, *:funding-group, *:conference, *:counts, *:custom-meta-group, *:notes" mode="#current">
            <xsl:with-param name="render-bio" select="true()" as="xs:boolean" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*:book-part-meta" mode="resort" priority="2">
    <xsl:copy  copy-namespaces="no">
    <!-- bringing the meta elements into the correct order -->
      <xsl:apply-templates select="@*, *:book-part-id, *:subj-group, *:title-group, *:contrib-group, *:aff, *:aff-affiliates, 
        *:author-notes, *:pub-date, *:edition, *:issn, *:issn-l, *:isbn, *:publisher, *:fpage, *:lpage, 
        *:elocation-id, *:supplementary-material, *:pub-history, *:permissions, *:self-uri, *:related-article, *:related-object, *:abstract, 
        *:trans-abstract, *:kwd-group, *:funding-group, *:conference, *:counts, *:custom-meta-group, *:notes" mode="#current">
            <xsl:with-param name="render-bio" select="true()" as="xs:boolean" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>


  <xsl:template match="*:title[*:label] | *:subtitle[*:label]" mode="clean-up" priority="2">
    <xsl:apply-templates select="*:label" mode="#current"/>
    <xsl:copy  copy-namespaces="no">
    <!-- bringing the meta elements into the correct order -->
      <xsl:apply-templates select="@*, node() except *:label" mode="#current"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>