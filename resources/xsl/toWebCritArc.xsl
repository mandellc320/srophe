<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns="http://www.w3.org/1999/xhtml" exclude-result-prefixes="xs tei" version="2.0">
	
	<!-- script for converting XML-TEI to HTML. 		
	Laura Mandell on 05/27/18 
	00-began with fork from /xslt/masters/HTMLtransform.xsl
	01-filled master with needed code
	02-revised plays, simplified by eliminating TOC
	03-created for CritArchive
-->

	<!-- Here is the document declaration necessary for an HTML5 (web) page -->

	<xsl:output method="html" doctype-system="about:legacy-compat"
		omit-xml-declaration="yes" indent="yes" encoding="UTF-8"/>
	<xsl:strip-space elements="*"/>
	
	<!-- to run multiple files 
	<xsl:template match="list">
		<xsl:for-each select="item">
			<xsl:apply-templates select="document(@code)/tei:TEI"/>
		</xsl:for-each>
	</xsl:template>  -->
	
	<!-- to run single files 
	<xsl:template match="/">
		<xsl:apply-templates/>
	</xsl:template>  -->
	
	<!-- for Srophe
	<xsl:template match="tei:TEI">
		<body>
			<xsl:apply-templates select="tei:text"/>
			<section class="noteSpace"/>
		</body>
	</xsl:template> -->
	
	<!--structuring the document-->

	<xsl:template match="tei:TEI">
		<!-- comment out for Srophe everything besides body 
		<xsl:variable name="filename" select="tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno"/>
		<xsl:result-document href="../HTML/{$filename}.html">
		<html>
			<head><title><xsl:value-of select="tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1]"/></title>
				<link rel="stylesheet" type="text/css" href="critarchive.css"/>
			</head> -->
				<body>
					<xsl:apply-templates select="tei:text"/>
					<section class="noteSpace"/>
				</body>
		<!-- </html>
		</xsl:result-document> -->
	</xsl:template>
	
	<!-- =======================================================
	   front templates -->
	
	<xsl:template match="tei:front">
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
			<xsl:apply-templates select="tei:publisher"/>
			<xsl:if test="tei:date">
				<xsl:text>, </xsl:text>
				<xsl:apply-templates select="tei:date"/>
			</xsl:if>
		</p>
	</xsl:template>
	
	<xsl:template match="tei:docEdition">
		<xsl:choose>
			<xsl:when test="tei:bibl/tei:biblScope/@unit">
		<p><xsl:text>Vol. </xsl:text>
			<xsl:value-of select="tei:bibl/tei:biblScope[@unit='volume']"/>
			<xsl:text>, </xsl:text>
			<xsl:text>pp. </xsl:text><xsl:value-of select="tei:bibl/tei:biblScope[@unit='page']"/>
		</p>
			</xsl:when>
			<xsl:otherwise>
				<p class="tp"><xsl:apply-templates/></p>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	

	<!-- =======================================================
	         body templates used by all types of documents -->

	<xsl:template match="tei:text">
				<xsl:apply-templates/>
		<xsl:if test="//tei:note">
				<section class="notes">
					<header>Notes</header>
				<xsl:apply-templates select="//tei:note" mode="end"/>
				</section>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="tei:div">
		<xsl:choose>
			<xsl:when test="@type='essay'">
				<main>
					<xsl:attribute name="class" select="@type"/>
					<xsl:apply-templates/>
				</main>
			</xsl:when>
			<xsl:when test="@type = 'poem'">
				<main>
					<xsl:attribute name="class" select="@type"/>
					<table>
						<xsl:apply-templates select="tei:lg"/>
					</table>
				</main>
			</xsl:when>
			<xsl:otherwise>
				<section>
					<xsl:attribute name="class" select="@type"/>
					<xsl:apply-templates/>
				</section>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="tei:head">
		<xsl:choose>
			<xsl:when test="tei:bibl">
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

	<xsl:template match="tei:lg">
		<xsl:choose>
			<xsl:when test="parent::tei:div[@type='poem']">
		<xsl:apply-templates/>
		<tr>
			<td>
				<br/>
			</td>
		</tr>
			</xsl:when>
			<xsl:otherwise>
				<table>
					<xsl:apply-templates/>
				</table>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:lg" mode="inQuote">
		<xsl:choose>
			<xsl:when test="parent::tei:quote/parent::tei:note">
				<xsl:apply-templates/>
			</xsl:when>
			<xsl:otherwise>
				<span class="poem"><xsl:apply-templates/></span>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:epigraph[@rend='poem']">
		<table class="epigraph">
			<xsl:apply-templates/>
		</table>
	</xsl:template>
	

	<xsl:template match="tei:epigraph[@rend='prose']">
		<p class="epigraph">
			<xsl:apply-templates/>
		</p>
	</xsl:template>
	
	<xsl:template match="tei:q">
		<xsl:text>&quot;</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>&quot;</xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:quote">
		<xsl:choose>
			<xsl:when test="parent::tei:note">
				<xsl:apply-templates mode="inQuote"/>
			</xsl:when>
			<xsl:when test="parent::tei:p">
					<xsl:choose>
					<xsl:when test="tei:p">
						<xsl:apply-templates mode="inQuote"/>
					</xsl:when>
					<xsl:when test="tei:lg">
						<xsl:apply-templates mode="inQuote"/>
					</xsl:when>
					<xsl:otherwise>
						<span class="blockquote"><xsl:apply-templates/></span>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<div class="blockquote">
					<xsl:choose>
						<xsl:when test="tei:p">
							<xsl:apply-templates/>
						</xsl:when>
						<xsl:when test="tei:lg">
							<xsl:apply-templates/>
						</xsl:when>
						<xsl:otherwise>
							<span class="blockquote"><xsl:apply-templates/></span>
						</xsl:otherwise>
					</xsl:choose>
				</div>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:bibl">
		<xsl:choose>
			<xsl:when test="parent::tei:head/parent::tei:div[@type = 'essay']">
				<header class="headBibl"><xsl:apply-templates select="tei:author"/></header>
				<header class="headBibl"><xsl:apply-templates select="tei:title"/></header>
			</xsl:when>
			<xsl:when test="tei:bibl[@type = 'epigraph']">
				<p class="epigCite">
					<xsl:apply-templates/>
				</p>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="tei:l">
		<xsl:variable name="rend" select="@rendition"/>
		<xsl:variable name="class" select="substring-after($rend, '#')"/>
		<xsl:choose>
		<xsl:when test="parent::tei:lg/parent::tei:quote">
			<span>
					<xsl:choose>
						<xsl:when test="@rendition">
					<xsl:attribute name="class" select="$class"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:attribute name="class">l</xsl:attribute>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:apply-templates/>
			</span>
			</xsl:when>
			<xsl:when test="parent::tei:lg/parent::tei:div[@type='poem']">
		<tr>
			<td>
				<xsl:attribute name="class">a</xsl:attribute>
				<span>
					<xsl:attribute name="class">
						<xsl:choose>
							<xsl:when test="@rendition">
						<xsl:value-of select="$class"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text>l</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
				<xsl:apply-templates/>
				</span>
			</td>
			<td>
				<xsl:attribute name="class">b</xsl:attribute>
				<xsl:attribute name="align">right</xsl:attribute>
				<xsl:number from="tei:div" level="any"/>
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
										<xsl:value-of select="$class"/>
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
			<xsl:otherwise>
				<span>
				<xsl:attribute name="class">
					<xsl:choose>
						<xsl:when test="@rendition">
							<xsl:value-of select="$class"/>
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
		<xsl:variable name="rend" select="@rendition"/>
		<xsl:variable name="class" select="substring-after($rend, '#')"/>
		<p>
			<xsl:choose>
				<xsl:when test="@rendition and parent::tei:quote">
					<xsl:attribute name="id">
						<xsl:text>resetMargin</xsl:text>
					</xsl:attribute>
					<xsl:attribute name="class">
						<xsl:value-of select="$class"/>
					</xsl:attribute>
				</xsl:when>
				<xsl:when test="@rendition">
					<xsl:attribute name="class">
						<xsl:value-of select="$class"/>
					</xsl:attribute>
				</xsl:when>
				<xsl:when test="@type">
					<xsl:attribute name="class" select="@type"/>
				</xsl:when>
			</xsl:choose>
			<xsl:apply-templates/>
		</p>
	</xsl:template>
	
	<xsl:template match="tei:p" mode="inQuote">
		<span class="blockquote">
			<xsl:apply-templates/>
		</span>
	</xsl:template>
	
	<xsl:template match="tei:lb">
		<br />
	</xsl:template>
	
	<xsl:template match="tei:hi">
		<xsl:variable name="rend" select="@rendition"/>
		<xsl:variable name="class" select="substring-after($rend, '#')"/>
		<span>
			<xsl:attribute name="class">
				<xsl:value-of select="$class"/>
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
			<xsl:when test="@type='gloss'">
				<dl><xsl:apply-templates/></dl>
			</xsl:when>
			<xsl:otherwise>
		<ul><xsl:apply-templates/></ul>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:item">
		<xsl:choose>
			<xsl:when test="parent::tei:list[@type='gloss']">
				<xsl:apply-templates/>
			</xsl:when>
			<xsl:otherwise>
		<li><xsl:apply-templates/></li>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:term">
		<dt>
			<xsl:attribute name="id" select="@xml:id"/>
				<xsl:apply-templates/>
		</dt>
	</xsl:template>
	
	<xsl:template match="tei:gloss">
		<dd><xsl:apply-templates/></dd>
	</xsl:template>

	<xsl:template match="tei:pb">
		<xsl:variable name="class">
		<xsl:choose>
			<xsl:when test="parent::tei:p/parent::tei:quote/parent::tei:div">
				<xsl:text>pageNoInside</xsl:text>
			</xsl:when>
			<xsl:when test="parent::tei:p/parent::tei:quote">
				<xsl:text>pageNoInside</xsl:text>
			</xsl:when>
			<xsl:when test="parent::tei:note/parent::tei:quote">
				<xsl:text>pageNoInside</xsl:text>
			</xsl:when>
			<xsl:when test="parent::tei:lg/parent::tei:quote">
				<xsl:text>pageNoInside</xsl:text>
			</xsl:when>
			<xsl:when test="parent::tei:l/parent::tei:lg/parent::tei:quote">
				<xsl:text>pageNoInside</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>pageNumber</xsl:text>
			</xsl:otherwise>
		</xsl:choose></xsl:variable>
		<span>
			<xsl:attribute name="class" select="$class"/>
			<xsl:text>[Page </xsl:text>
			<xsl:value-of select="@n"/>
			<xsl:text>]</xsl:text>
		</span>
	</xsl:template>
	
		<xsl:template match="tei:milestone">
			<xsl:variable name="class">
				<xsl:choose>
					<xsl:when test="preceding-sibling::node()[1]/@place='bottom-left'">
						<xsl:text>milesWithFW</xsl:text>
					</xsl:when>
					<!-- <xsl:when test="parent::tei:p/parent::tei:quote/parent::tei:div">
						<xsl:text>milestone</xsl:text>
					</xsl:when> -->
					<xsl:when test="parent::tei:p/parent::tei:quote">
						<xsl:text>milesNoInside</xsl:text>
					</xsl:when>
					<xsl:when test="parent::tei:note/parent::tei:quote">
						<xsl:text>milesNoInside</xsl:text>
					</xsl:when>
					<xsl:when test="parent::tei:lg/parent::tei:quote">
						<xsl:text>milesNoInside</xsl:text>
					</xsl:when>
					<xsl:when test="parent::tei:l/parent::tei:lg/parent::tei:quote">
						<xsl:text>milesNoInside</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>milestone</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
					<span>
						<xsl:attribute name="class" select="$class"/>
						<xsl:value-of select="@n"/>
					</span>
		</xsl:template>
		
		<xsl:template match="tei:fw">
			<xsl:variable name="class">
				<xsl:choose>
					<xsl:when test="@place='bottom-left'">
						<xsl:choose>
							<xsl:when test="parent::*/parent::tei:quote">
								<xsl:text>fwWithMilesQ</xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text>fwWithMiles</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<!-- <xsl:when test="parent::tei:p/parent::tei:quote/parent::tei:div">
						<xsl:text>fw</xsl:text>
					</xsl:when> -->
					<xsl:when test="parent::tei:p/parent::tei:quote">
						<xsl:text>fwNoInside</xsl:text>
					</xsl:when>
					<xsl:when test="parent::tei:note/parent::tei:quote">
						<xsl:text>fwNoInside</xsl:text>
					</xsl:when>
					<xsl:when test="parent::tei:lg/parent::tei:quote">
						<xsl:text>fwNoInside</xsl:text>
					</xsl:when>
					<xsl:when test="parent::tei:l/parent::tei:lg/parent::tei:quote">
						<xsl:text>fwNoInside</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>fw</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<br />
					<span>
						<xsl:attribute name="class" select="$class"/>
						<xsl:apply-templates/>
					</span>
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
		<p><xsl:value-of select="."/></p>
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
		<p class="note" id="{$noteNBR}">
			<sup><xsl:value-of select="$noteNBR"/></sup>
			<xsl:apply-templates/>
			<xsl:text> </xsl:text>
			<a>
				<xsl:attribute name="href"><xsl:text>#back</xsl:text><xsl:value-of select="$noteNBR"
					/></xsl:attribute>
				<xsl:text>Back</xsl:text>
			</a>
		</p>
	</xsl:template>

</xsl:stylesheet>
