<?xml version="1.0" encoding="UTF-8"?>
<!--
  SeeAlso service display and test page.
  Version 0.8

  Usage: Put this file (showservice.xsl) in a directory together with 
  seealso.js, xmlverbatim.xsl, xmlverbatim.css, and favicon.ico (optional)
  and let your SeeAlso service point to it in the unAPI format list file.

  Copyright 2008 Jakob Voss

  Licensed under the Apache License, Version 2.0 (the "License"); 
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software distributed
  under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR 
  CONDITIONS OF ANY KIND, either express or implied. See the License for the
  specific language governing permissions and limitations under the License.

  Alternatively, this software may be used under the terms of the 
  GNU Lesser General Public License (LGPL).
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:osd="http://a9.com/-/spec/opensearch/1.1/" 
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:dcterms="http://purl.org/dc/terms/"
  xmlns:so="http://ws.gbv.de/seealso/schema/"
>
  <xsl:import href="xmlverbatim.xsl"/>
  <xsl:output method="html" encoding="UTF-8" indent="yes"/>

  <!-- explicit query base -->
  <xsl:param name="seealso-query-base" select="/processing-instruction('seealso-query-base')"/>

  <!-- try to get the Open Search description document -->
  <xsl:param name="osdurl">
    <xsl:value-of select="$seealso-query-base"/>
    <xsl:choose>
      <xsl:when test="not($seealso-query-base)">?</xsl:when>
      <xsl:when test="contains($seealso-query-base,'?')">&amp;</xsl:when>
      <xsl:otherwise>?</xsl:otherwise>
    </xsl:choose>
    <xsl:text>format=opensearchdescription</xsl:text>
  </xsl:param>

  <xsl:variable name="osd" select="document($osdurl)"/>

  <!-- locate the other files -->
  <xsl:variable name="xsltpi" select="/processing-instruction('xml-stylesheet')"/>
  <xsl:variable name="clientbase">
    <xsl:call-template name="basepath">
      <xsl:with-param name="string" select="substring-before(substring-after($xsltpi,'href=&quot;'),'&quot;')"/>
    </xsl:call-template>
  </xsl:variable >

  <!-- favicon in the client directory (comment out to skip) -->
  <xsl:param name="favicon"><xsl:value-of select="$clientbase"/>favicon.ico</xsl:param>

  <!-- metadata elements to display in the about-section (TODO: more) -->
  <so:MetadataFields>
    <osd:ShortName/>
    <osd:Description/>
  </so:MetadataFields>

  <!-- root -->
  <xsl:template match="/">
    <xsl:apply-templates select="formats"/>
  </xsl:template>
  <xsl:template match="/formats">
    <xsl:variable name="fullservice" select="namespace-uri($osd/*[1]) = 'http://a9.com/-/spec/opensearch/1.1/'"/>
    <xsl:variable name="name">
       <xsl:apply-templates select="$osd/osd:OpenSearchDescription" mode="name"/>
    </xsl:variable>
    <html>
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <title>SeeAlso service : <xsl:value-of select="$name"/></title>
        <link rel="stylesheet" type="text/css" href="{$clientbase}xmlverbatim.css" />
        <xsl:if test="$favicon">
          <link rel="shortcut icon" type="image/x-icon" href="{$favicon}" />
        </xsl:if>
        <script src="{$clientbase}seealso.js" type="text/javascript" ></script>
        <style type="text/css">
          body, h1, h2, th, td { font-family: sans-serif; }
          table { border-collapse:collapse; }
          td, th { border: 1px solid #666; padding: 4px; }
          th { text-align: left; background: #96c458; }
          h2 { color: #96c458; margin: 1em 0em 0.5em 0em; } 
          h1 { color: #96c458; border-bottom: 1px solid #96c458; }
          td { background: #c3ff72; }
          p { padding-bottom: 0.5em; }
          pre, .code { 
          background: #ddd; 
          border: 1px solid #666;
          padding: 4px;
          }
          table, .code, p { margin: 0em 0.5em 0em; }
          #display {
          background: #fff;
          padding: 4px;
          }
          .footer {
            border-top: 1px solid #96c458;
            font-size: small;
            color: #666;
            margin-top: 1em;
            padding: 0.5em;
          }
        </style>
        <script type="text/javascript">
          function lookup() {
            var identifier = document.getElementById('identifier').value;
            var service = new SeeAlsoService("<xsl:value-of select="$seealso-query-base"/>");
            var view = new SeeAlsoUL();
            var url = service.url + "?format=seealso&amp;id=" + identifier;
            var a = document.getElementById('query-url');
            a.setAttribute("href",url);
            a.innerHTML = "";
            a.appendChild(document.createTextNode(url));
            url += "&amp;callback=?";
            var displayElement = document.getElementById('display');
            service.query(identifier, function(response) {
              var json = response.toJSON();
              var r = document.getElementById('response');
              r.innerHTML = "";
              r.appendChild(document.createTextNode(json));
              view.display(displayElement,response);
            });
          }  
         </script> 
      </head>
      <body onload="lookup();">
        <h1>
          <xsl:choose>
            <xsl:when test="string-length($name) &gt; 0"><xsl:value-of select="$name"/></xsl:when>
            <xsl:otherwise>SeeAlso service</xsl:otherwise>
          </xsl:choose>
        </h1>
        <p>
          This is the base URL of a 
          <b>
            <xsl:choose>
              <xsl:when test="$fullservice">SeeAlso Full</xsl:when>
              <xsl:otherwise>SeeAlso Simple</xsl:otherwise>
            </xsl:choose>
          </b>
          web service. It delivers an <a href="http://unapi.info">unAPI</a> format list that 
          includes the 'seealso' response format 
          (<a href="http://www.gbv.de/wikis/cls/SeeAlso_Simple_Specification">SeeAlso Simple</a>). 
        </p>
        <xsl:choose>
          <xsl:when test="$fullservice">
            <xsl:call-template name="about">
              <xsl:with-param name="baseurl" select="$seealso-query-base"/>
              <xsl:with-param name="osd" select="$osd/osd:OpenSearchDescription"/>
              <xsl:with-param name="fields" select="document('')/*/so:MetadataFields/*"/>
            </xsl:call-template>
            <xsl:call-template name="demo">
              <xsl:with-param name="osd" select="$osd/osd:OpenSearchDescription"/>
            </xsl:call-template>
            <h2>OpenSearch description document</h2>
            <div class="code">
              <xsl:apply-templates select="$osd" mode="xmlverb" />
            </div>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="demo"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="name(/*[1]) = 'formats'">
        <h2>unAPI format list</h2>
        <div class="code">
          <xsl:apply-templates select="/" mode="xmlverb" />
        </div>
        </xsl:if>
        <div class="footer">This document has automatically been generated based 
        on the services' <a href="{$osdurl}">OpenSearch description document</a>.</div>
        <!-- TODO: Show version number of the SeeAlso JavaScript library -->
      </body>
    </html>
  </xsl:template>
  <xsl:template match="osd:OpenSearchDescription" mode="name">
    <xsl:choose>
      <xsl:when test="osd:ShortName">
        <xsl:value-of select="osd:ShortName"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>no name found!</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

<!-- Show BaseURL, URL template and additional metadata in the OpenSearch description document -->
<xsl:template name="about">
  <xsl:param name="baseurl"/>
  <xsl:param name="osd"/>
  <xsl:param name="fields"/>
  <h2>About</h2>
  <table>
     <xsl:for-each select="$fields">
      <xsl:variable name="localname" select="local-name(.)"/>
      <xsl:variable name="fullname" select="name(.)"/>
      <xsl:variable name="namespace" select="namespace-uri(.)"/>
      <xsl:for-each select="$osd/*[name()=$localname and namespace-uri()=$namespace]">
      <tr>
        <th><xsl:value-of select="$localname"/></th>
        <td><xsl:value-of select="normalize-space(.)"/></td>
      </tr>
      </xsl:for-each>
    </xsl:for-each>
    <tr>
      <th>BaseURL</th><td><tt><xsl:value-of select="$baseurl"/></tt></td>
    </tr>
    <tr>
      <th>URL template</th>
      <td><tt><xsl:value-of select="$osd/osd:Url[@type='text/javascript'][1]/@template"/></tt></td>
    </tr>
  </table>  
</xsl:template>

<xsl:template name="demo">
  <xsl:param name="osd"/>
  <xsl:param name="json.js"/>
  <!--xsl:variable name="examples" select="$osd/so:example"/-->
  <h2>Live demo</h2>
  <form>
    <table id='demo'>
      <tr>
        <th>query</th>
        <td>
          <input type="text" id="identifier" onkeyup="lookup();" size="40" value="{/formats/@id}"/>
          <!-- show the first 3 examples -->
          <xsl:if test="$osd and $osd/so:example">
            <xsl:text> (for instance </xsl:text>
            <xsl:for-each select="$osd/so:example">
              <xsl:if test="position() &gt; 1 and position() &lt; 4">, </xsl:if>
              <xsl:if test="position() &lt; 4"><tt><xsl:value-of select="so:query"/></tt></xsl:if>
              <xsl:if test="position() = 4"> ...</xsl:if>
            </xsl:for-each>
            <xsl:text>)</xsl:text>
          </xsl:if>
        </td>
      </tr>
      <tr></tr>
      <tr>
        <th>query URL</th>
        <td><a id='query-url' href=''></a></td>
      </tr>
      <tr>
        <th>response</th>
        <td><pre id='response'></pre></td>
        <!-- TODO: check the result if it was one of the examples -->
      </tr>
      <tr>
        <th>display</th>
        <td><div id='display'></div></td>
      </tr>
    </table>
  </form>
</xsl:template>

<!-- reusable replace-string function -->
<xsl:template name="replace-string">
  <xsl:param name="text"/>
  <xsl:param name="from"/>
  <xsl:param name="to"/>  
  <xsl:choose>
    <xsl:when test="contains($text, $from)">
      <xsl:variable name="before" select="substring-before($text, $from)"/>
      <xsl:variable name="after" select="substring-after($text, $from)"/>
      <xsl:variable name="prefix" select="concat($before, $to)"/>
      <xsl:value-of select="$before"/>
      <xsl:value-of select="$to"/>
      <xsl:call-template name="replace-string">
        <xsl:with-param name="text" select="$after"/>
        <xsl:with-param name="from" select="$from"/>
        <xsl:with-param name="to" select="$to"/>
      </xsl:call-template>
    </xsl:when> 
    <xsl:otherwise>
      <xsl:value-of select="$text"/>  
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- will work as long as this script is not served via an URL with '/' in the query part -->
<xsl:template name="basepath">
  <xsl:param name="string"/>
  <xsl:param name="pos" select="1"/>
  <xsl:choose>
    <xsl:when test="contains(substring($string,$pos),'/')">
      <xsl:call-template name="basepath">
        <xsl:with-param name="string" select="$string"/>
        <xsl:with-param name="pos" select="$pos + 1"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="$pos &gt; 1">
      <xsl:value-of select="substring($string,1,$pos - 1)"/>
    </xsl:when>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>
