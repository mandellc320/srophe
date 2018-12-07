<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:saxon="http://saxon.sf.net/" xmlns:local="http://syriaca.org/ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:x="http://www.w3.org/1999/xhtml" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs t x saxon local" version="2.0">

 <!-- ================================================================== 
       Copyright 2013 New York University  
       
       This file is part of the Syriac Reference Portal Places Application.
       
       The Syriac Reference Portal Places Application is free software: 
       you can redistribute it and/or modify it under the terms of the GNU 
       General Public License as published by the Free Software Foundation, 
       either version 3 of the License, or (at your option) any later 
       version.
       
       The Syriac Reference Portal Places Application is distributed in 
       the hope that it will be useful, but WITHOUT ANY WARRANTY; without 
       even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
       PARTICULAR PURPOSE.  See the GNU General Public License for more 
       details.
       
       You should have received a copy of the GNU General Public License
       along with the Syriac Reference Portal Places Application.  If not,
       see (http://www.gnu.org/licenses/).
       
       ================================================================== --> 
 
 <!-- ================================================================== 
       tei2html.xsl
       
       This XSLT transforms tei.xml to html.
       
       parameters:
            
        
       code by: 
        + Winona Salesky (wsalesky@gmail.com)
          for use with eXist-db
        + Tom Elliott (http://www.paregorios.org) 
          for the Institute for the Study of the Ancient World, New York
          University, under contract to Vanderbilt University for the
          NEH-funded Syriac Reference Portal project.
          
       funding provided by:
        + National Endowment for the Humanities (http://www.neh.gov). Any 
          views, findings, conclusions, or recommendations expressed in 
          this code do not necessarily reflect those of the National 
          Endowment for the Humanities.
       
       ================================================================== -->
 <!-- =================================================================== -->
 <!-- import component stylesheets for HTML page portions -->
 <!-- =================================================================== -->
    <xsl:import href="citation.xsl"/>
    <xsl:import href="bibliography.xsl"/>
    <!-- Calls Srophe specific display XSLT, you can add your own or edit this one. -->
    <xsl:import href="core.xsl"/>
    <!-- Helper functions and templates -->
    <xsl:import href="helper-functions.xsl"/>
    <xsl:import href="collations.xsl"/>
    
 <!-- =================================================================== -->
 <!-- set output so we get (mostly) indented HTML -->
 <!-- =================================================================== -->
    <xsl:output name="html" encoding="UTF-8" method="xhtml" indent="no" omit-xml-declaration="yes"/>

 <!-- =================================================================== -->
 <!--  initialize top-level variables and transform parameters -->
 <!-- =================================================================== -->
    
    <!-- Parameters passed from global.xqm (set in config.xml) default values if params are empty -->
    <xsl:param name="data-root" select="'/db/apps/srophe-data'"/>
    <!-- eXist app root for app deployment-->
    <xsl:param name="app-root" select="'/db/apps/srophe'"/>
    <!-- Root of app for building dynamic links. Default is eXist app root -->
    <xsl:param name="nav-base" select="'/exist/apps/srophe'"/>
    <!-- Base URI for identifiers in app data -->
    <xsl:param name="base-uri" select="'http://syriaca.org'"/>
    <!-- Hard coded values-->
    <xsl:param name="normalization">NFKC</xsl:param>
    <!-- Resource id -->
    <xsl:variable name="resource-id">
        <xsl:choose>
            <xsl:when test="string(/*/@id)">
                <xsl:value-of select="string(/*/@id)"/>
            </xsl:when>
            <xsl:when test="//t:publicationStmt/t:idno[@type='URI'][starts-with(.,$base-uri)]">
                <xsl:value-of select="replace(replace(//t:publicationStmt/t:idno[@type='URI'][starts-with(.,$base-uri)][1],'/tei',''),'/source','')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat($base-uri,'/0000')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Resource title -->
    <xsl:variable name="resource-title">
        <xsl:apply-templates select="/descendant-or-self::t:titleStmt/t:title[1]"/>
    </xsl:variable>
 
    <!-- =================================================================== -->
    <!-- Templates -->
    <!-- =================================================================== -->
    <!-- Root -->
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- Customizations here -->
    <!-- =======================================================
	   front templates -->

	<xsl:template match="tei:front">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="tei:titlePage">
		<section class="titlePage">
			<xsl:apply-templates/>
		</section>
	</xsl:template>

	<xsl:template match="tei:titlePart">
		<h2 class="tp">
			<xsl:apply-templates/>
		</h2>
	</xsl:template>

	<xsl:template match="tei:docAuthor">
		<h3 class="tp">
			<xsl:apply-templates/>
		</h3>
	</xsl:template>

	<xsl:template match="tei:docDate">
		<h4 class="tp">
			<xsl:apply-templates/>
		</h4>
	</xsl:template>

	<xsl:template match="tei:docImprint">
		<p class="pnoindent">
			<xsl:text>London: </xsl:text>
			<xsl:apply-templates select="tei:publisher"/>
			<xsl:text>, </xsl:text>
			<xsl:apply-templates select="tei:date"/>
		</p>
	</xsl:template>

	<xsl:template match="tei:docEdition">
		<xsl:choose>
			<xsl:when test="tei:bibl/tei:biblScope/@unit">
				<p>
					<xsl:text>Vol. </xsl:text>
					<xsl:value-of select="tei:bibl/tei:biblScope[@unit = 'volume']"/>
					<xsl:text>, </xsl:text>
					<xsl:text>pp. </xsl:text>
					<xsl:value-of select="tei:bibl/tei:biblScope[@unit = 'page']"/>
				</p>
			</xsl:when>
			<xsl:otherwise>
				<p class="tp">
					<xsl:apply-templates/>
				</p>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<!-- =======================================================
	         body templates used by all types of documents -->

	<xsl:template match="tei:text">
		<main>
			<!--<img src="http://iiif.dh.tamu.edu/iiif/2/poetess/bijou/010.tif/200,360,1550,180/960,/0/gray.jpg" class="partHead" alt="The Bijou"/>-->
			<xsl:apply-templates/>
			<xsl:if test="//tei:note">
				<section class="notes">
					<header>Notes</header>
					<xsl:apply-templates select="//tei:note" mode="end"/>
				</section>
			</xsl:if>
		</main>
	</xsl:template>

	<xsl:template match="tei:div">
		<xsl:variable name="nbrPB">
			<xsl:value-of select="count(descendant::tei:pb)"/>
		</xsl:variable>
		<xsl:variable name="pages">
			<xsl:choose>
				<xsl:when test="$nbrPB &gt; 1">
					<xsl:value-of select="concat('pp. ', descendant::tei:pb[1]/@n, '-', descendant::tei:pb[last()]/@n)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat('p. ', descendant::tei:pb/@n)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="URL" select="concat($base-uri, 'XML/bijou1828.', @type, @xml:id, '.xml')"/>
		<!--needs to be switched to local tei file link -->
		<xsl:choose>
			<xsl:when test=".[@type = 'poem'] |.[@type='drama'] | .[@type='scene']">
				<xsl:choose>
					<xsl:when test="following-sibling::tei:div | preceding-sibling::tei:div">
						<section id="{@xml:id}">
							<xsl:attribute name="class" select="@type"/>
							<xsl:apply-templates/>
						</section>
					</xsl:when>
					<xsl:otherwise>
						<section id="@xml:id">
							<xsl:attribute name="class" select="@type"/>
							<table class="tei">
								<tr>
									<td class="a">
										<h5>from <a href="http://www.poetessarchive.org/bijou/HTML/bijou1828-p5.html">
                                                <em>The Bijou</em>, 1828</a>, <xsl:value-of select="$pages"/>
                                        </h5>
									</td>
									<td class="b">
										<!--<a>
											<xsl:attribute name="href">
												<xsl:value-of select="concat($base-uri, 'XML/bijou1828.', @type, @xml:id, '.xml')"/>
											</xsl:attribute>
											<img class="tei" src="download.png" alt="TEI-encoded version"/>
										</a>-->
									</td>
									<!--tei image needs to be local -->
								</tr>
							</table>
							<xsl:apply-templates select="tei:head"/>
							
								<xsl:apply-templates/>
						</section>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="@type = 'index'">
				<xsl:choose>
					<xsl:when test="following-sibling::tei:div | preceding-sibling::tei:div">
						<section id="{@xml:id}">
							<xsl:attribute name="class" select="@type"/>
							<xsl:apply-templates select="tei:head"/>
							<br/>
							<table>
								<xsl:attribute name="class" select="@type"/>
								<xsl:apply-templates select="tei:bibl"/>
							</table>
						</section>
					</xsl:when>
					<xsl:otherwise>
						<section id="@xml:id">
							<xsl:attribute name="class" select="@type"/>
							<table class="tei">
								<tr>
									<td class="a">
										<h5>from <a href="http://www.poetessarchive.org/bijou/HTML/bijou1828-p5.html">
                                                <em>The Bijou</em>, 1828</a>, <xsl:value-of select="$pages"/>
                                        </h5>
									</td>
									<td class="b">
										<!--<a>
											<xsl:attribute name="href">
												<xsl:value-of select="concat($base-uri, 'XML/bijou1828.', @type, @xml:id, '.xml')"/>
											</xsl:attribute>
											<img class="tei" src="download.png" alt="TEI-encoded version"/>
										</a>-->
									</td>
									<!--tei image needs to be local -->
								</tr>
							</table>
							<xsl:apply-templates select="tei:head"/>
							<br/>
							<table>
								<xsl:attribute name="class" select="@type"/>
								<xsl:apply-templates select="tei:bibl"/>
							</table>
						</section>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="following-sibling::tei:div | preceding-sibling::tei:div">
						<section id="{@xml:id}">
							<xsl:attribute name="class" select="@type"/>
							<xsl:apply-templates/>
						</section>
					</xsl:when>
					<xsl:otherwise>
						<section id="{@xml:id}">
							<xsl:attribute name="class" select="@type"/>
							<table class="tei">
								<tr>
									<td class="a">
										<h5>from <a href="http://www.poetessarchive.org/bijou/HTML/bijou1828-p5.html">
                                                <em>The Bijou</em>, 1828</a>, <xsl:value-of select="$pages"/>
                                        </h5>
									</td>
									<td class="b">
										<!--<a>
											<xsl:attribute name="href">
												<xsl:value-of select="concat($base-uri, 'XML/bijou1828.', @type, @xml:id, '.xml')"/>
											</xsl:attribute>
											<img class="tei" src="download.png" alt="TEI-encoded version"/>
										</a>-->
									</td>
									<!--tei image needs to be local -->
								</tr>
							</table>
							<xsl:apply-templates/>
						</section>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="tei:head">
		<xsl:choose>
			<xsl:when test="tei:bibl">
				<xsl:apply-templates/>
			</xsl:when>
			<xsl:when test="parent::tei:figure">
				<br/>
				<xsl:apply-templates/>
			</xsl:when>
			<xsl:otherwise>
				<header>
					<xsl:apply-templates/>
				</header>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="@rendition">
		<xsl:value-of select="substring-after(., '#')"/>
	</xsl:template>

	<xsl:template match="tei:title">
		<xsl:choose>
			<xsl:when test="preceding-sibling::tei:title">
				<xsl:text>, </xsl:text>
				<span>
					<xsl:attribute name="class">
						<xsl:apply-templates select="@rend | @rendition"/>
					</xsl:attribute>
					<xsl:apply-templates/>
				</span>
			</xsl:when>
			<xsl:otherwise>
				<span>
					<xsl:attribute name="class">
						<xsl:apply-templates select="@rend | @rendition"/>
					</xsl:attribute>
					<xsl:apply-templates/>
				</span>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="tei:figure/tei:head">
		<br/>
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="tei:graphic">
		<xsl:variable name="imageNbr" select="substring-after(parent::tei:figure/@xml:id, 'image')"/>
		<xsl:variable name="imageURL">
			<xsl:value-of select="concat('http://iiif.dh.tamu.edu/iiif/2/poetess/bijou/', $imageNbr, '.tif/full/full/0/default.jpg')"/>
		</xsl:variable>
		<a href="{$imageURL}">
			<img src="{@url}" alt="a picture of {parent::tei:figure/parent::tei:div[@type='picture']/tei:head}"/>
		</a>
	</xsl:template>

	<xsl:template match="tei:figDesc">
		<br/>
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="tei:lg">
		<xsl:choose>
			<xsl:when test="parent::tei:div[@type = 'poem']">
				<table>
					<xsl:attribute name="class" select="parent::tei:div/@type"/>
					<xsl:apply-templates/>
				</table>
			</xsl:when>
			<xsl:when test="parent::tei:sp/parent::tei:div[@type='scene']">
				<table>
					<xsl:attribute name="class" select="parent::tei:sp/parent::tei:div/@type"/>
					<xsl:apply-templates/>
				</table>
			</xsl:when>
			<xsl:otherwise>
				<table>
					<xsl:apply-templates/>
				</table>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="tei:epigraph">
		<xsl:choose>
			<xsl:when test="tei:l">
				<table class="epigraph">
					<xsl:apply-templates select="tei:l"/>
					<xsl:apply-templates select="tei:bibl"/>
				</table>
			</xsl:when>
			<xsl:otherwise>
				<section class="epigraph">
			<xsl:apply-templates/>
				</section>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="tei:q">
		<xsl:text>"</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>"</xsl:text>
	</xsl:template>

	<xsl:template match="tei:quote">
		<xsl:choose>
			<xsl:when test="parent::tei:p | parent::tei:note">
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;/p&gt;]]></xsl:text>
				<blockquote>
					<xsl:choose>
						<xsl:when test="tei:p">
							<xsl:apply-templates/>
						</xsl:when>
						<xsl:when test="tei:lg">
							<xsl:apply-templates/>
						</xsl:when>
						<xsl:otherwise>
							<p class="pnoindent">
								<xsl:apply-templates/>
							</p>
						</xsl:otherwise>
					</xsl:choose>
				</blockquote>
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;p class="pnoindent"&gt;]]></xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<blockquote>
					<xsl:choose>
						<xsl:when test="tei:p">
							<xsl:apply-templates/>
						</xsl:when>
						<xsl:when test="tei:lg">
							<xsl:apply-templates/>
						</xsl:when>
						<xsl:otherwise>
							<p class="pnoindent">
								<xsl:apply-templates/>
							</p>
						</xsl:otherwise>
					</xsl:choose>
				</blockquote>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="tei:bibl">
		<xsl:choose>
			<xsl:when test="parent::tei:head/parent::tei:div[@type = 'essay']">
				<header class="headBibl">
					<xsl:apply-templates select="tei:author"/>
				</header>
				<header class="headBibl">
					<xsl:apply-templates select="tei:title"/>
				</header>
			</xsl:when>
			<xsl:when test="parent::tei:epigraph">
				<xsl:choose>
					<xsl:when test="preceding-sibling::tei:l">
						<tr>
                            <td class="epigCite">
                                <xsl:apply-templates/>
                            </td>
                        </tr>
					</xsl:when>
					<xsl:otherwise>
						<span class="epigCite">
					<xsl:apply-templates/>
						</span>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="parent::tei:div[@type = 'index']">
				<tr class="index">
					<td class="index">
						<xsl:apply-templates select="tei:author"/>
					</td>
					<td class="index">
						<xsl:apply-templates select="tei:title"/>
					</td>
				</tr>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="tei:l">
		<xsl:variable name="nbr">
			<xsl:number from="tei:div" level="any"/>
		</xsl:variable>
		<xsl:variable name="epigNbr" select="count(parent::tei:lg/parent::tei:div/tei:epigraph/tei:l)"/>
		<xsl:choose>
			<xsl:when test="parent::tei:lg/parent::tei:div[@type = 'poem'] | parent::tei:lg/parent::tei:sp/parent::tei:div[@type='scene']">
				<tr>
					<td class="a">
						<span>
							<xsl:attribute name="class">
								<xsl:choose>
									<xsl:when test="@rendition">
										<xsl:apply-templates select="@rendition"/>
									</xsl:when>
									<xsl:when test="@rend">
										<xsl:value-of select="@rend"/>
									</xsl:when>
									<xsl:when test="@type">
										<xsl:value-of select="@type"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:text>l</xsl:text>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:attribute>
							<xsl:apply-templates/>
						</span>
					</td>
					<td class="b">
						<xsl:value-of select="number($nbr) - number($epigNbr)"/>
					</td>
				</tr>
			</xsl:when>
			<xsl:when test="parent::tei:lg">
				<tr>
					<td>
						<span>
							<xsl:attribute name="class">
								<xsl:choose>
									<xsl:when test="@rendition">
										<xsl:apply-templates select="@rendition"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:text>l</xsl:text>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:attribute>
							<xsl:apply-templates/>
						</span>
					</td>
				</tr>
			</xsl:when>
			<xsl:when test="parent::tei:epigraph">
				<tr>
					<td class="epigLines">
						<xsl:apply-templates/>
					</td>
				</tr>
			</xsl:when>
			<xsl:otherwise>
				<span>
					<xsl:attribute name="class">
						<xsl:choose>
							<xsl:when test="@rendition">
								<xsl:apply-templates select="@rendition"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text>l</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					<xsl:apply-templates/>
				</span>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="tei:p">
		<xsl:choose>
			<xsl:when test="parent::tei:stage">
				<p class="stage">
				<xsl:apply-templates/>
				</p>
			</xsl:when>
			<xsl:when test="parent::tei:epigraph">
				<p class="epigPara">
					<xsl:apply-templates/>
				</p>
			</xsl:when>
			<xsl:otherwise>
		<p>
			<xsl:choose>
				<xsl:when test="@rendition | @rend">
					<xsl:attribute name="class">
						<xsl:apply-templates select="@rendition | @rend"/>
					</xsl:attribute>
				</xsl:when>
				<xsl:when test="@type">
					<xsl:attribute name="class" select="@type"/>
				</xsl:when>
			</xsl:choose>
			<xsl:apply-templates/>
		</p>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="tei:lb">
		<br/>
	</xsl:template>

	<xsl:template match="tei:hi">
		<span>
			<xsl:attribute name="class">
				<xsl:apply-templates select="@rendition | @rend"/>
			</xsl:attribute>
			<xsl:apply-templates/>
		</span>
	</xsl:template>

	<xsl:template match="tei:emph">
		<em>
			<xsl:value-of select="."/>
		</em>
	</xsl:template>

	<xsl:template match="tei:ref">
		<a href="{@target}">
			<xsl:apply-templates/>
		</a>
	</xsl:template>

	<xsl:template match="tei:list">
		<xsl:choose>
			<xsl:when test="@type = 'gloss'">
				<dl>
					<xsl:apply-templates/>
				</dl>
			</xsl:when>
			<xsl:otherwise>
				<ul>
					<xsl:apply-templates/>
				</ul>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="tei:item">
		<xsl:choose>
			<xsl:when test="parent::tei:list[@type = 'gloss']">
				<xsl:apply-templates/>
			</xsl:when>
			<xsl:otherwise>
				<li>
					<xsl:apply-templates/>
				</li>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="tei:term">
		<dt>
			<xsl:apply-templates/>
		</dt>
	</xsl:template>

	<xsl:template match="tei:gloss">
		<dd>
			<xsl:apply-templates/>
		</dd>
	</xsl:template>

	<xsl:template match="tei:stage">
		<xsl:choose>
			<xsl:when test="parent::tei:l">
				<span>
					<xsl:attribute name="class" select="@type"/>
					<xsl:apply-templates/>
				</span>
			</xsl:when>
			<xsl:when test=".[@type='exit'] | .[@type='entrance']">
				<p>
					<xsl:attribute name="class" select="@type"/>
					<xsl:apply-templates/>
				</p>
			</xsl:when>
			<xsl:when test="@type='delivery'">
				<xsl:choose>
					<xsl:when test="parent::tei:lg | parent::tei:p">
				<span class="delivery">
					<xsl:apply-templates/>
				</span>
					</xsl:when>
					<xsl:otherwise>
						<p class="delivery">
							<xsl:apply-templates/>
						</p>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="tei:p">
						<xsl:apply-templates/>
					</xsl:when>
					<xsl:otherwise>
						<p>
							<xsl:attribute name="class">
								<xsl:choose>
									<xsl:when test="@type">
										<xsl:value-of select="@type"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:text>stage</xsl:text>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:attribute>
							<xsl:apply-templates/>
						</p>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:speaker">
		<p class="speaker">
			<xsl:apply-templates/>
		</p>
	</xsl:template>

	<xsl:template match="tei:salute | tei:signed">
		<p>
			<xsl:if test="@rend">
				<xsl:attribute name="class">
					<xsl:value-of select="@rend"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates/>
		</p>
	</xsl:template>
	
	<xsl:template name="pageNandI">
		<xsl:param name="img"/>
		<xsl:param name="nbr"/>
		<xsl:variable name="imgNbr">
			<xsl:value-of select="substring-after($img, 'image')"/>
		</xsl:variable>
		<xsl:variable name="URL">
			<xsl:value-of select="concat('http://iiif.dh.tamu.edu/iiif/2/poetess/bijou/', $imgNbr, '.tif/full/full/0/default.jpg')"/>
		</xsl:variable>
		<table class="pageNumber" id="{$imgNbr}">
			<tr>
                <td class="a">
			<xsl:text>[Page </xsl:text>
			<xsl:value-of select="@n"/>
			<xsl:text>]</xsl:text>
			</td>
				<td class="b">
                    <a href="#{$imgNbr}">
					<xsl:attribute name="onclick">
						<xsl:text disable-output-escaping="yes"><![CDATA[window.open(']]></xsl:text>
                            <xsl:value-of select="$URL"/>
                            <xsl:text disable-output-escaping="yes"><![CDATA[', 'newwindow', 'width=600, height=900')]]></xsl:text>
					</xsl:attribute>
					<img class="pageImage" alt="page image and link" src="http://iiif.dh.tamu.edu/iiif/2/poetess/bijou/{$imgNbr}.tif/full/,70/0/default.jpg'"/>
				</a>
                </td>
			</tr>
		</table>
	</xsl:template>

	<xsl:template match="tei:pb">
		<xsl:choose>
			<xsl:when test="parent::tei:div[@type='scene']">
				<hr/>
				<xsl:call-template name="pageNandI">
					<xsl:with-param name="img" select="@xml:id"/>
					<xsl:with-param name="nbr" select="@n"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="parent::tei:div[@type='picture']">
				<hr/>
				<xsl:choose>
					<xsl:when test="@n">
						<table class="pageNumber">
							<tr>
                                <td class="a">
								<xsl:text>[Page </xsl:text>
								<xsl:value-of select="@n"/>
								<xsl:text>]</xsl:text>
							</td>
								<td class="b"> </td>
							</tr>
						</table>
					</xsl:when>
					<xsl:otherwise>
						<table class="pageNumber">
							<tr>
                                <td class="a">
								<xsl:text>[np]</xsl:text>
							</td>
								<td class="b"> </td>
							</tr>
						</table>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="parent::tei:quote">
				<xsl:choose>
					<xsl:when test="parent::tei:quote/parent::tei:p">
						<xsl:text disable-output-escaping="yes"><![CDATA[&lt;/blockquote&gt;&lt;/p&gt;]]></xsl:text>
						<hr/>
						<xsl:call-template name="pageNandI">
							<xsl:with-param name="img" select="@xml:id"/>
							<xsl:with-param name="nbr" select="@n"/>
						</xsl:call-template>
						<xsl:text disable-output-escaping="yes"><![CDATA[&lt;p class="pnoindent"&gt;&lt;blockquote&gt;]]></xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text disable-output-escaping="yes"><![CDATA[&lt;/blockquote&gt;]]></xsl:text>
						<hr/>
						<xsl:call-template name="pageNandI">
							<xsl:with-param name="img" select="@xml:id"/>
							<xsl:with-param name="nbr" select="@n"/>
						</xsl:call-template>
						<xsl:text disable-output-escaping="yes"><![CDATA[&lt;blockquote&gt;]]></xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="parent::tei:p">
				<xsl:choose>
					<xsl:when test="parent::tei:p/parent::tei:quote">
						<xsl:text disable-output-escaping="yes"><![CDATA[&lt;/p&gt;&lt;/blockquote&gt;]]></xsl:text>
						<hr/>
						<xsl:call-template name="pageNandI">
							<xsl:with-param name="img" select="@xml:id"/>
							<xsl:with-param name="nbr" select="@n"/>
						</xsl:call-template>
						<xsl:text disable-output-escaping="yes"><![CDATA[&lt;blockquote&gt;&lt;p class="pnoindent"&gt;]]></xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text disable-output-escaping="yes"><![CDATA[&lt;/p&gt;]]></xsl:text>
						<hr/>
						<xsl:call-template name="pageNandI">
							<xsl:with-param name="img" select="@xml:id"/>
							<xsl:with-param name="nbr" select="@n"/>
						</xsl:call-template>
						<xsl:text disable-output-escaping="yes"><![CDATA[&lt;p class="pnoindent"&gt;]]></xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="parent::tei:lg/parent::tei:quote">
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;/table&gt;&lt;/blockquote&gt;]]></xsl:text>
				<hr/>
				<xsl:call-template name="pageNandI">
					<xsl:with-param name="img" select="@xml:id"/>
					<xsl:with-param name="nbr" select="@n"/>
				</xsl:call-template>
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;blockquote&gt;&lt;table class="poem"&gt;]]></xsl:text>
			</xsl:when>
			<xsl:when test="parent::tei:lg/parent::sp/parent::tei:div[@type='scene']">
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;/table&gt;]]></xsl:text>
				<hr/>
				<xsl:call-template name="pageNandI">
					<xsl:with-param name="img" select="@xml:id"/>
						<xsl:with-param name="nbr" select="@n"/>
				</xsl:call-template>
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;table class="scene"&gt;]]></xsl:text>
			</xsl:when>
			<xsl:when test="parent::tei:lg">
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;/table&gt;]]></xsl:text>
				<hr/>
				<xsl:call-template name="pageNandI">
					<xsl:with-param name="img" select="@xml:id"/>
					<xsl:with-param name="nbr" select="@n"/>
				</xsl:call-template>
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;table class="poem"&gt;]]></xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="pageNandI">
					<xsl:with-param name="img" select="@xml:id"/>
					<xsl:with-param name="nbr" select="@n"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="tei:milestone">
		<xsl:choose>
			<xsl:when test="preceding-sibling::tei:fw[1]"/>
			<xsl:when test="parent::tei:p/parent::tei:quote">
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;/p&gt;&lt;/blockquote&gt;]]></xsl:text>
				<table class="milestone">
					<tr>
						<td>
							<xsl:value-of select="@n"/>
						</td>
					</tr>
				</table>
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;blockquote&gt;&lt;p class="pnoindent"&gt;]]></xsl:text>
			</xsl:when>
			<xsl:when test="parent::tei:p">
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;/p&gt;]]></xsl:text>
				<table class="milestone">
					<tr>
						<td>
							<xsl:value-of select="@n"/>
						</td>
					</tr>
				</table>
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;p class="pnoindent"&gt;]]></xsl:text>
			</xsl:when>
			<xsl:when test="parent::tei:lg/parent::tei:quote">
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;/table&gt;&lt;/blockquote&gt;]]></xsl:text>
				<table class="milestone">
					<tr>
						<td>
							<xsl:value-of select="@n"/>
						</td>
					</tr>
				</table>
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;blockquote&gt;&lt;table&gt;]]></xsl:text>
			</xsl:when>
			<xsl:when test="parent::tei:lg">
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;/table&gt;]]></xsl:text>
				<table class="milestone">
					<tr>
						<td>
							<xsl:value-of select="@n"/>
						</td>
					</tr>
				</table>
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;table&gt;]]></xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<table class="milestone">
					<tr>
						<td>
							<xsl:value-of select="@n"/>
						</td>
					</tr>
				</table>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="tei:fw">
		<xsl:choose>
			<xsl:when test="parent::tei:quote">
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;/blockquote&gt;]]></xsl:text>
				<xsl:call-template name="fwTable"/>
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;blockquote&gt;]]></xsl:text>
			</xsl:when>
			<xsl:when test="parent::tei:p/parent::tei:quote">
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;/p&gt;&lt;/blockquote&gt;]]></xsl:text>
				<xsl:call-template name="fwTable"/>
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;blockquote&gt;&lt;p class="pnoindent"&gt;]]></xsl:text>
			</xsl:when>
			<xsl:when test="parent::tei:p">
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;/p&gt;]]></xsl:text>
				<xsl:call-template name="fwTable"/>
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;p class="pnoindent"&gt;]]></xsl:text>
			</xsl:when>
			<xsl:when test="parent::tei:lg/parent::tei:quote">
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;/table&gt;&lt;/blockquote&gt;]]></xsl:text>
				<xsl:call-template name="fwTable"/>
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;blockquote&gt;&lt;table&gt;]]></xsl:text>
			</xsl:when>
			<xsl:when test="parent::tei:lg">
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;/table&gt;]]></xsl:text>
				<xsl:call-template name="fwTable"/>
				<xsl:text disable-output-escaping="yes"><![CDATA[&lt;table&gt;]]></xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="fwTable"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="fwTable">
		<table style="width:100%" class="fw">
			<xsl:choose>
				<xsl:when test="following-sibling::tei:milestone[1]">
					<tr>
						<td class="mlst1">
							<p>
								<xsl:if test="@rendition">
									<xsl:attribute name="class">
										<xsl:apply-templates select="@rendition"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:apply-templates/>
							</p>
						</td>
						<td class="mlst2">
							<xsl:value-of select="following-sibling::tei:milestone[1]/@n"/>
						</td>
						<td class="mlst3">
							<xsl:text> </xsl:text>
						</td>
					</tr>
				</xsl:when>
				<xsl:otherwise>
					<tr>
						<td>
							<p>
								<xsl:if test="@rendition">
									<xsl:attribute name="class">
										<xsl:apply-templates select="@rendition"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:apply-templates/>
							</p>
						</td>
					</tr>
				</xsl:otherwise>
			</xsl:choose>
		</table>
	</xsl:template>

	<xsl:template match="tei:salute | tei:signed">
		<p>
			<xsl:if test="@rend">
				<xsl:attribute name="class">
					<xsl:value-of select="@rend"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates/>
		</p>
	</xsl:template>

	<xsl:template match="tei:imprint">
		<xsl:text>, Vol. </xsl:text>
		<xsl:value-of select="tei:biblScope[@unit = 'volume']"/>
		<xsl:text> (</xsl:text>
		<xsl:value-of select="tei:date"/>
		<xsl:text>), </xsl:text>
		<xsl:text>pp. </xsl:text>
		<xsl:value-of select="tei:biblScope[@unit = 'page']"/>
	</xsl:template>

	<xsl:template match="tei:binaryObject">
		<p>
			<xsl:value-of select="."/>
		</p>
	</xsl:template>


	<!-- =======================================================
	   notes -->

	<xsl:template match="tei:note">
		<xsl:variable name="noteNBR">
			<xsl:number select="." level="any"/>
		</xsl:variable>
		<a>
			<xsl:attribute name="href">
				<xsl:text>#</xsl:text>
				<xsl:value-of select="$noteNBR"/>
			</xsl:attribute>
			<xsl:attribute name="id" select="concat('back', $noteNBR)"/>
			<sup>
				<xsl:value-of select="$noteNBR"/>
			</sup>
		</a>
		<xsl:text> </xsl:text>
	</xsl:template>

	<xsl:template match="tei:note" mode="end">
		<xsl:variable name="noteNBR">
			<xsl:number select="." level="any"/>
		</xsl:variable>
		<p id="{$noteNBR}">
            <xsl:value-of select="$noteNBR"/>. <xsl:apply-templates/>
			<xsl:text> </xsl:text>
			<a>
				<xsl:attribute name="href">
                    <xsl:text>#back</xsl:text>
                    <xsl:value-of select="$noteNBR"/>
                </xsl:attribute>
				<xsl:text>Back</xsl:text>
			</a>
		</p>
	</xsl:template>

</xsl:stylesheet>