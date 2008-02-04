<?xml version="1.0" encoding="UTF-8"?>
<!--
  SeeAlso service display and test page
  Version 0.5
  
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
  <xsl:import href="xmlverbatim.xsl" />
  <xsl:output method="html" encoding="UTF-8" indent="yes"/>
  
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
  
  <!-- 
  You probably have to change this according to your server settings
  TODO: make it simpler!
  -->
  <xsl:param name="jscssbase">
    <xsl:choose>
      <xsl:when test="$seealso-query-base and substring($seealso-query-base,string-length($seealso-query-base)) = '/'">../</xsl:when>
      <xsl:otherwise></xsl:otherwise>
    </xsl:choose>  
  </xsl:param>
  <xsl:param name="xmlverbatim.css"><xsl:value-of select="$jscssbase"/>client/xmlverbatim.css</xsl:param>
  <xsl:param name="jquery.js"><xsl:value-of select="$jscssbase"/>javascript-client/jquery.js</xsl:param>
  <xsl:param name="json.js"><xsl:value-of select="$jscssbase"/>javascript-client/json.js</xsl:param>
  <xsl:param name="seealso.js"><xsl:value-of select="$jscssbase"/>javascript-client/seealso.js</xsl:param>
  
  <xsl:variable name="osd" select="document($osdurl)"/>
  
  <!-- metadata elements to display in the about-section -->
  <so:MetadataFields>
    <osd:ShortName/>
    <osd:Description/>
    <!-- TODO: more fields -->
  </so:MetadataFields>
  
  <!-- root -->
  <xsl:template match="/">   
    <xsl:apply-templates select="formats"/>
  </xsl:template>
  <xsl:template match="/formats">
    <xsl:variable name="name">
      <xsl:apply-templates select="$osd/osd:OpenSearchDescription" mode="name"/>
    </xsl:variable>
    <xsl:variable name="url" select="$osd/osd:OpenSearchDescription/osd:Url[@type='text/javascript'][1]/@template"/>
    
    <!-- this will only work in controlled cases because search and replace in XSLT sucks -->    
    <xsl:variable name="baseurl">
      <xsl:call-template name="replace-string">
        <xsl:with-param name="text" select="$url"/>
        <xsl:with-param name="from" select="'?id=&#x7B;searchTerms&#x7D;&amp;format=seealso&amp;callback=&#x7B;callback&#x7D;'"/>
        <xsl:with-param name="to" select="''"/>
      </xsl:call-template>
    </xsl:variable>
    
    <html>
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <title>SeeAlso service : <xsl:value-of select="$name"/></title>
        <link rel="stylesheet" type="text/css" href="{$xmlverbatim.css}" />
        <script src="{$jquery.js}" type="text/javascript" ></script>
        <xsl:if test="$json.js">
          <script src="{$json.js}" type="text/javascript" ></script>
        </xsl:if>
        <script src="{$seealso.js}" type="text/javascript" ></script>
        <style type="text/css">
          body, h1, h2, th, td { font-family: sans-serif; }
          table { border-collapse:collapse; }
          td, th { border: 1px solid #666; padding: 4px; }
          th { text-align: left; background: #96c458; }
          h2 { color: #96c458; margin: 1em 0em 0.5em 0em; } 
          h1 { color: #96c458; border-bottom: 1px solid #96c458; }
          td { background: #c3ff72; }
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
            var identifier = $('#identifier').val();
            var service = new SeeAlsoService("<xsl:value-of select="$baseurl"/>");
            var view = new SeeAlsoUL();
            var url = service.url + "?format=seealso&amp;id=" + identifier;
            var a = document.getElementById('query-url');
            a.setAttribute("href",url);
            $(a).text(url);
            url += "&amp;callback=?";
            var element = $('#display');
            <!-- TODO: if xsl:if test="$json.js" -->
            $.getJSON(url, function(data) {
            var json = $.toJSON(data);
              $('#response').text(json);
              view.display(element,data);
            });           
          }  
         </script> 
      </head>
      <body>
        <xsl:choose>
          <xsl:when test="namespace-uri($osd/*[1]) = 'http://a9.com/-/spec/opensearch/1.1/'">          
            <h1><xsl:value-of select="$name"/></h1>
            <p>
              This is the base URL of a <a href="http://ws.gbv.de/seealso/">SeeAlso Full</a> web service.
              It delivers an <a href="http://unapi.info">unAPI</a> format list that points to a 
              <a href="http://www.gbv.de/wikis/cls/SeeAlso_Simple_Specification">SeeAlso Simple</a> service. 
            </p>
            <xsl:call-template name="about">
              <xsl:with-param name="baseurl" select="$baseurl"/>
              <xsl:with-param name="osd" select="$osd/osd:OpenSearchDescription"/>
              <xsl:with-param name="fields" select="document('')/*/so:MetadataFields/*"/>
            </xsl:call-template>
            <xsl:call-template name="demo">
              <xsl:with-param name="osd" select="$osd/osd:OpenSearchDescription"/>
              <xsl:with-param name="json.js" select="$json.js"/>
            </xsl:call-template>
            <h2>OpenSearch description document</h2>
            <div class="code">
              <xsl:apply-templates select="$osd" mode="xmlverb" />
            </div>
            
          </xsl:when>
          <xsl:otherwise>
            <p style='color:#ff0000;'><b>The OpenSearch Description document for this SeeAlso service could not be found!</b></p>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="name(/*[1]) = 'formats'">
        <h2>unAPI format list</h2>        
        <div class="code">
          <xsl:apply-templates select="/" mode="xmlverb" />
        </div>
        </xsl:if>
        <div class="footer">This document has automatically been generated based on the services' <a href="{$osdurl}">OpenSearch Description Document</a>.</div>
        <!-- TODO: show version of this XSLT script -->
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
    <tr>
      <th>URL template</th>            
      <td><tt><xsl:value-of select="$osd/osd:Url[@type='text/javascript'][1]/@template"/></tt></td>
    </tr>
    <tr>
      <th>BaseURL</th><td><tt><xsl:value-of select="$baseurl"/></tt></td>
    </tr>
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
  </table>  
</xsl:template>

<xsl:template name="demo">
  <xsl:param name="osd"/>
  <xsl:param name="json.js"/>
  <xsl:variable name="examples" select="$osd/so:example"/>
  <h2>Live demo</h2>
  <form>
    <table id='demo'>
      <tr>
        <th>query</th>            
        <td><input type="value" id="identifier" onkeyup="lookup();" size="40"/>
          <xsl:if test="$examples">
            <xsl:text> (for instance </xsl:text>
            <xsl:for-each select="$examples">
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
      <xsl:if test="$json.js">
        <tr>
          <th>response</th>
          <td><pre id='response'></pre></td>
          <!-- TODO: test whether it was an example query and test the result -->
        </tr>
      </xsl:if>
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
</xsl:stylesheet>
