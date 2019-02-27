<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs tei" version="2.0">
	
	<!-- script for converting XML-TEI to HTML. 		
	Laura Mandell on 05/27/18 
	00-began with fork from /xslt/masters/HTMLtransform.xsl
	01-filled master with needed code
	02-revised plays, simplified by eliminating TOC
	03-created for CritArchive
-->

	<!-- Here is the document declaration necessary for an HTML5 (web) page -->

	<xsl:output method="html" doctype-system="about:legacy-compat" omit-xml-declaration="yes" indent="yes" encoding="UTF-8"/>
	<xsl:strip-space elements="*"/>

	<!-- Make these variables so that you can easily change them. -->
	<xsl:variable name="stylesheet">critarchive.css</xsl:variable>
	<xsl:variable name="baseURL">http://www.poetessarchive.org/critarchive/</xsl:variable>
	
	<!-- for running one document --> 
	<xsl:template match="/">
		<xsl:apply-templates/>
	</xsl:template>

	<!-- running multiple documents in an XML directory  -->
	<xsl:template match="list">
		<xsl:for-each select="item">
			<xsl:apply-templates select="document(@code)/tei:TEI"/>
		</xsl:for-each>
	</xsl:template>
	

	<!--structuring the document-->

	<xsl:template match="tei:TEI">
		<xsl:variable name="filename">
			<xsl:value-of select="tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno"/>
		</xsl:variable>
		<xsl:variable name="mainTitle" select="tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type='main']"/>
		<xsl:variable name="subTitle" select="tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type='subordinate']"/>
		<xsl:variable name="author" select="tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author"/>
		<xsl:apply-templates select="tei:text"/>
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
		<xsl:variable name="workCode" select="ancestor-or-self::tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno"/>
		<!--<xsl:variable name="URL" select="concat($baseURL, 'XML/', $workCode, '.xml')"/> -->
		<xsl:choose>
			<xsl:when test="@type='essay'">
				<main id="{$workCode}">
					<xsl:attribute name="class" select="@type"/>
					<xsl:apply-templates/>
				</main>
			</xsl:when>
			<xsl:when test="@type = 'poem'">
				<main id="{$workCode}">
					<p class="tei">
						<xsl:apply-templates select="tei:head"/>
					</p>
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
		<xsl:text>"</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>"</xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:quote">
		<xsl:choose>
			<xsl:when test="parent::tei:p | parent::tei:note">
			<span class="tei-quote">
				<xsl:choose>
					<xsl:when test="tei:p">
						<xsl:apply-templates/>
					</xsl:when>
					<xsl:when test="tei:lg">
						<xsl:apply-templates/>
					</xsl:when>
					<xsl:otherwise>
						<span class="tei-p pnoindent"><xsl:apply-templates/></span>
					</xsl:otherwise>
				</xsl:choose>
			</span>
			</xsl:when>
			<xsl:otherwise>
				<span class="tei-quote">
					<xsl:choose>
						<xsl:when test="tei:p">
							<xsl:apply-templates/>
						</xsl:when>
						<xsl:when test="tei:lg">
							<xsl:apply-templates/>
						</xsl:when>
						<xsl:otherwise>
							<span class="tei-p pnoindent"><xsl:apply-templates/></span>
						</xsl:otherwise>
					</xsl:choose>
				</span>
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
		<xsl:choose>
			<xsl:when test="parent::tei:lg/parent::tei:div[@type='poem']">
		<tr>
			<td>
				<xsl:attribute name="class">a</xsl:attribute>
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
			<xsl:otherwise><span>
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
		<p>
			<xsl:choose>
				<xsl:when test="@rendition">
			<xsl:attribute name="class">
				<xsl:apply-templates select="@rendition"/>
			</xsl:attribute>
				</xsl:when>
				<xsl:when test="@type">
					<xsl:attribute name="class" select="@type"/>
				</xsl:when>
			</xsl:choose>
			<xsl:apply-templates/>
		</p>
	</xsl:template>
	
	<xsl:template match="tei:lb">
		<br/>
	</xsl:template>
	
	<xsl:template match="tei:hi">
		<span>
			<xsl:attribute name="class">
				<xsl:apply-templates select="@rendition"/>
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
		<span class="pageNumber">
			<xsl:text>[Page </xsl:text><xsl:value-of select="@n"/><xsl:text>]</xsl:text>		
		</span>
	</xsl:template>
	
		<xsl:template match="tei:milestone">
			<span class="tei-milestone milestone">
				<xsl:value-of select="@n"/>
			</span>
		</xsl:template>
		
		<xsl:template match="tei:fw">
			<xsl:choose>
				<xsl:when test="following-sibling::tei:milestone[1]">
					<span class="mlst1 {string(@rendition)} tei-p">
						<xsl:apply-templates/>
					</span>
					<span class="mlst2 {string(@rendition)} tei-p">
						<xsl:value-of select="following-sibling::tei:milestone[1]/@n"/>
					</span>
				</xsl:when>
				<xsl:otherwise>
					<span>
						<xsl:if test="@rendition">
							<xsl:attribute name="class">
								<xsl:apply-templates select="@rendition"/>
							</xsl:attribute>
						</xsl:if>
						<xsl:apply-templates/>
					</span>
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
			<td class="mlst3"><xsl:text> </xsl:text></td>
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
		<p id="{$noteNBR}"><xsl:value-of select="$noteNBR"/>. <xsl:apply-templates/>
			<xsl:text> </xsl:text>
			<a>
				<xsl:attribute name="href"><xsl:text>#back</xsl:text><xsl:value-of select="$noteNBR"/></xsl:attribute>
				<xsl:text>Back</xsl:text>
			</a>
		</p>
	</xsl:template>

</xsl:stylesheet>