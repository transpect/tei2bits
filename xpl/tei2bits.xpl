<?xml version="1.0" encoding="utf-8"?>
<p:declare-step 
  xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:tr="http://transpect.io"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:tei2bits="http://transpect.io/tei2bits"  
  version="1.0"
  name="tei2bits"
  type="tei2bits:tei2bits"
  >
	<p:documentation>This step converts TEI to BITS. You can define the used modes by overriding the default fallback pipeline in your project's adaptations.</p:documentation>
  <p:option name="srcpaths" required="false" select="'no'"/>
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="'debug'"/>
  <p:option name="status-dir-uri" select="'status'"/>
	<p:option name="filename-driver" required="false" select="'tei2bits/tei2bits-driver'"/>
	
  <p:input port="source" primary="true" />
  <p:input port="additional-inputs" sequence="true">
    <p:empty/>
  </p:input>
  <p:input port="paths" kind="parameter" primary="true"/>
	
  <p:output port="result" primary="true" />
  <p:serialization port="result" 
    omit-xml-declaration="false"
    doctype-public="-//NLM//DTD BITS Book Interchange DTD v2.0 20151225//EN"
    doctype-system="https://jats.nlm.nih.gov/extensions/bits/2.0/BITS-book2.dtd" />

  <p:output port="report" sequence="true">
    <p:pipe port="report" step="dtp"/>
  </p:output>
  
	<p:import href="http://transpect.io/cascade/xpl/dynamic-transformation-pipeline.xpl"/>
  <p:import href="http://transpect.io/xproc-util/simple-progress-msg/xpl/simple-progress-msg.xpl"/>
  
<!--  <p:variable name="status-dir-uri" select="concat($debug-dir-uri, '/status')"/>-->
  
  <tr:simple-progress-msg name="start-msg" file="tei2bits-start.txt">
    <p:input port="msgs">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">Starting TEI to BITS conversion</c:message>
          <c:message xml:lang="de">Beginne Konvertierung von TEI nach BITS</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>
  
  <tr:dynamic-transformation-pipeline name="dtp"
    fallback-xsl="http://transpect.io/tei2bits/xsl/tei2bits.xsl"
    fallback-xpl="http://transpect.io/tei2bits/xpl/tei2bits_default.xpl">
    <p:with-option name="load" select="$filename-driver"/>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:input port="additional-inputs">
      <p:pipe port="additional-inputs" step="tei2bits"/>
    </p:input>
    <p:input port="options"><p:empty/></p:input>
  </tr:dynamic-transformation-pipeline>
  
  <tr:simple-progress-msg name="success-msg" file="tei2bits-success.txt">
    <p:input port="msgs">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">Successfully finished TEI to BITS conversion</c:message>
          <c:message xml:lang="de">Konvertierung von TEI nach BITS erfolgreich abgeschlossen</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>
  
</p:declare-step>