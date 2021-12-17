<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	exclude-result-prefixes="xs tei" version="2.0">
	
	<!-- script for converting XML-TEI to HTML. 		
	Laura Mandell on 05/27/18 
	00-began with fork from /xslt/masters/HTMLtransform.xsl
	01-filled master with needed code
	02-revised plays, simplified by eliminating TOC
	03-created for CritArchive 
	04-changes 09/20/2021 -->

	<!-- Here is the document declaration necessary for an HTML5 (web) page -->

	<xsl:output method="html" doctype-system="about:legacy-compact"
		omit-xml-declaration="yes" indent="yes" encoding="UTF-8"/>
	<xsl:strip-space elements="*"/>
	
	<xsl:param name="nbrPoetryLines"/>
	
	<!-- to run multiple files   
	<xsl:template match="list">
		<xsl:for-each select="item">
			<xsl:apply-templates select="document(@code)/tei:TEI"/>
		</xsl:for-each>
	</xsl:template> --> 
	
	<!-- to run single files  
	<xsl:template match="/">
		<xsl:apply-templates/>
	</xsl:template>  -->

	
	<!-- for Srophe, and comment out the first tei:TEI template below.  -->
	<xsl:template match="tei:TEI">
		<body>
			<xsl:apply-templates select="tei:text"/>
			<section class="noteSpace"/>
		</body>
	</xsl:template>
	
	<!--structuring the document 

	<xsl:template match="tei:TEI">
	<xsl:variable name="filename" select="tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno"/>
		<xsl:result-document href="../HTML/{$filename}.html">
		<html>
			<head><title><xsl:value-of select="tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1]"/></title>
				<link rel="stylesheet" type="text/css" href="critarchive.css"/>
			</head>
				<body>
					<xsl:apply-templates select="tei:text"/>
					<section class="noteSpace"/>
				</body>
		</html>
		</xsl:result-document>
	</xsl:template> -->
	
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
		<p class="noindent">
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
						<div class="poem">
							<xsl:apply-templates/>
						</div>
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
	
	<xsl:template match="tei:bibl">
		<xsl:choose>
			<xsl:when test="parent::tei:head/parent::tei:div[@type = 'essay']"> <!-- why not for poem? because the poem div starts after header info.-->
				<header class="headBibl">
					<xsl:apply-templates/>
				</header>
			</xsl:when>
			<xsl:when test="tei:bibl[@type = 'epigraph']">
				<p class="epigCite">
					<xsl:apply-templates/>
				</p>
			</xsl:when>
			<xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:div/tei:head/tei:bibl/tei:author">
		<span class="author"><xsl:apply-templates/></span>
	</xsl:template>
	
	<xsl:template match="tei:div/tei:head/tei:bibl/tei:title">
		<span class="title"><xsl:apply-templates/></span>
	</xsl:template>

	<xsl:template match="tei:epigraph[@rendition='#poem']">
		<table class="epigraph">
			<xsl:apply-templates/>
		</table>
	</xsl:template>
	

	<xsl:template match="tei:epigraph[@rendition='#prose']">
		<p class="epigraph">
			<xsl:apply-templates/>
		</p>
	</xsl:template>
	
	<xsl:template match="tei:q">
		<xsl:text>&quot;</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>&quot;</xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:quote"> <!-- still need to fix offsetting, but works in Srophe -->
		<xsl:choose>
			<xsl:when test="parent::tei:div">
				<div class="blockquote">
					<xsl:apply-templates/>
				</div>
			</xsl:when>
			<xsl:when test="parent::tei:p">
				<span class="blockquote">
					<xsl:apply-templates/>
				</span>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:lg">
		<span class="stanza"><xsl:apply-templates/></span>
		<xsl:if test="tei:l[last()]">
			<span class="stanzaSpace"><xsl:text>space between stanzas</xsl:text></span>
		</xsl:if>
	</xsl:template>

	<xsl:template match="tei:l">
		<xsl:variable name="rend" select="@rendition"/>
		<xsl:variable name="class" select="substring-after($rend, '#')"/>
		<span class="l">
			<xsl:choose>
				<xsl:when test="@rendition">
						<span class="{$class}">
							<xsl:apply-templates/>
						</span>
				</xsl:when>
				<xsl:otherwise>
						<xsl:apply-templates/>
				</xsl:otherwise>
			</xsl:choose>
		</span>
		<xsl:if test="$nbrPoetryLines = 'yes'">
			<span class="lno">
				<xsl:number from="tei:div" level="any"/>
			</span>
		</xsl:if>
	</xsl:template>

	<xsl:template match="tei:p">
		<xsl:variable name="rend" select="@rendition"/>
		<xsl:variable name="class" select="substring-after($rend, '#')"/>
		<xsl:choose>
			<xsl:when test="parent::tei:quote/parent::tei:p">
					<xsl:choose>
						<xsl:when test="@rendition = '#noindent'">
							<span class="noIndentP">
								<xsl:apply-templates/>
							</span>
						</xsl:when>
						<xsl:otherwise>
							<span class='indentP'>
								<xsl:apply-templates/>
							</span>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
			<xsl:otherwise>
				<p>
					<xsl:choose>
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
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:table">
		<table>
		<xsl:if test="@rendition">
			<xsl:attribute name="class">
				<xsl:value-of select="substring-after(@rendition, '#')"/>
		</xsl:attribute>
		</xsl:if>
			<xsl:apply-templates/>
		</table>
	</xsl:template>
	
	<xsl:template match="tei:row">
		<tr>
		<xsl:if test="parent::tei:table[@rendition]">
			<xsl:attribute name="class" select="substring-after(parent::tei:table/@rendition, '#')"/>
		</xsl:if>
		<xsl:apply-templates/>
		</tr>
	</xsl:template>
	
	<xsl:template match="tei:cell">
		<td>
		<xsl:if test="parent::tei:row/parent::tei:table[@rendition]">
			<xsl:attribute name="class" select="substring-after(parent::tei:row/parent::tei:table/@rendition, '#')"/>
		</xsl:if>
		<xsl:apply-templates/>
		</td>
	</xsl:template>
	
	<xsl:template match="tei:lb">
		<br/>
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
		<xsl:choose><!-- could this just be, "when ancester is quote?" -->
			<xsl:when test="parent::tei:quote/parent::tei:div">
				<xsl:text>pageInside</xsl:text>
			</xsl:when>
			<xsl:when test="parent::tei:quote/parent::tei:p">
				<xsl:text>pageInside</xsl:text>
			</xsl:when>
			<xsl:when test="parent::tei:p/parent::tei:quote/parent::tei:div">
				<xsl:text>pageInside</xsl:text>
			</xsl:when>
			<xsl:when test="parent::tei:p/parent::tei:quote">
				<xsl:text>pageInside</xsl:text>
			</xsl:when>
			<xsl:when test="parent::tei:note/parent::tei:quote">
				<xsl:text>pageInside</xsl:text>
			</xsl:when>
			<xsl:when test="parent::tei:lg/parent::tei:quote">
				<xsl:text>pageInside</xsl:text>
			</xsl:when>
			<xsl:when test="parent::tei:l/parent::tei:lg/parent::tei:quote">
				<xsl:text>pageInside</xsl:text>
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
	
	<xsl:template match="tei:fw">
			<xsl:variable name="class">
				<xsl:choose>
					<xsl:when test="@type='vol'">
						<xsl:choose>
							<xsl:when test="following-sibling::tei:fw[1][@type='sig']">
								<xsl:choose>
									<xsl:when test="parent::tei:quote">
										<xsl:text>volWithSigInside</xsl:text>
									</xsl:when>
									<xsl:when test="parent::tei:p/parent::tei:quote/parent::tei:div"> <!-- I think this is unnecessary, given the next one -->
										<xsl:text>volWithSigInside</xsl:text>
									</xsl:when>
									<xsl:when test="parent::tei:p/parent::tei:quote">
										<xsl:text>volWithSigInside</xsl:text>
									</xsl:when>
									<xsl:when test="parent::tei:lg/parent::tei:quote">
										<xsl:text>volWithSigInside</xsl:text>
									</xsl:when>
									<xsl:when test="parent::tei:l/parent::tei:lg/parent::tei:quote">
										<xsl:text>volWithSigInside</xsl:text>
									</xsl:when>
									<xsl:otherwise>
										<xsl:text>volWithSig</xsl:text></xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:when test="parent::tei:quote">
								<xsl:text>volInside</xsl:text>
							</xsl:when>
							<xsl:when test="parent::tei:p/parent::tei:quote/parent::tei:div"> <!-- I think this is unnecessary, given the next one -->
								<xsl:text>volInside</xsl:text>
							</xsl:when> 
							<xsl:when test="parent::tei:p/parent::tei:quote">
								<xsl:text>volInside</xsl:text>
							</xsl:when>
							<xsl:when test="parent::tei:lg/parent::tei:quote">
								<xsl:text>volInside</xsl:text>
							</xsl:when>
							<xsl:when test="parent::tei:l/parent::tei:lg/parent::tei:quote">
								<xsl:text>volInside</xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text>vol</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:when test="@type='sig'">
						<xsl:choose>
							<xsl:when test="preceding-sibling::tei:fw[1][@type='vol']">
								<xsl:choose>
									<xsl:when test="parent::tei:quote">
										<xsl:text>sigWithVolInside</xsl:text>
									</xsl:when>
									<xsl:when test="parent::tei:p/parent::tei:quote/parent::tei:div"> <!-- I think this is unnecessary, given the next one -->
										<xsl:text>sigWithVolInside</xsl:text>
									</xsl:when> 
									<xsl:when test="parent::tei:p/parent::tei:quote">
										<xsl:text>sigWithVolInside</xsl:text>
									</xsl:when>
									<xsl:when test="parent::tei:lg/parent::tei:quote">
										<xsl:text>sigWithVolInside</xsl:text>
									</xsl:when>
									<xsl:when test="parent::tei:l/parent::tei:lg/parent::tei:quote">
										<xsl:text>sigWithVolInside</xsl:text>
									</xsl:when>
									<xsl:otherwise><xsl:text>sigWithVol</xsl:text></xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:when test="parent::tei:quote">
								<xsl:text>sigInside</xsl:text>
							</xsl:when>
							<xsl:when test="parent::tei:p/parent::tei:quote/parent::tei:div"> <!-- I think this is unnecessary, given the next one -->
								<xsl:text>sigInside</xsl:text>
							</xsl:when> 
							<xsl:when test="parent::tei:p/parent::tei:quote">
								<xsl:text>sigInside</xsl:text>
							</xsl:when>
							<xsl:when test="parent::tei:lg/parent::tei:quote">
								<xsl:text>sigInside</xsl:text>
							</xsl:when>
							<xsl:when test="parent::tei:l/parent::tei:lg/parent::tei:quote">
								<xsl:text>sigInside</xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text>sig</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
				</xsl:choose>
			</xsl:variable>
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
			<xsl:value-of select="$noteNBR"/><xsl:text>.&#160;&#160;</xsl:text>
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
