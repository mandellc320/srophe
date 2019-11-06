<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs tei" version="2.0">

	<!-- script for converting XML-TEI to HTML. 

	Laura Mandell on 05/27/18 
	00-began with fork from /xslt/masters/HTMLtransform.xsl
	01-filled master with needed code
	02-revised plays, simplified by eliminating TOC (toWebComplete.xsl)
	03-created for critarchive 10/17/18 (toWebCritArchive.xsl)
	04-re-used for bijou 10/21/18, and added back elements from 02 (toWebBijou.xsl)
	05-reformed for srophe 11/03/19
-->

	<!-- Here is the document declaration necessary for an HTML5 (web) page -->

	<xsl:output method="html" doctype-system="about:legacy-compat" omit-xml-declaration="yes" indent="yes" encoding="UTF-8"/>
	<xsl:strip-space elements="*"/>

	<!-- Make these variables so that you can easily change them. -->
	<xsl:variable name="stylesheet">bijou.css</xsl:variable>
	<xsl:variable name="baseURL">http://www.poetessarchive.org/bijou/</xsl:variable>


	<xsl:template match="tei:TEI">
		<body>
			<xsl:apply-templates select="tei:text"/>
			<section class="noteSpace"/>
		</body>
	</xsl:template>

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

	<xsl:template match="tei:titlePart[@type='main']">
		<h2 class="tp">
			<a href="http://poetess.dh.tamu.edu/bijou/work/bijou1828-p5"><xsl:apply-templates/></a>
		</h2>
	</xsl:template>
	
	<xsl:template match="tei:titlePart[@type='subordinate']">
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
				<h5>
					<xsl:text>pp. </xsl:text>
					<xsl:value-of select="tei:bibl/tei:biblScope[@unit = 'page']"/>
				</h5>
	</xsl:template>


	<!-- =======================================================
	         body templates used by all types of documents -->

	
	<xsl:template match="tei:text">
		<main>
			<img src="http://iiif.dh.tamu.edu/iiif/2/poetess%2Fbijou%2F010.tif/200,360,1550,180/960,/0/gray.jpg" class="partHead" alt="The Bijou"/>
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
		<xsl:choose>
			<xsl:when test=".[@type = 'poem'] | .[@type = 'drama'] | .[@type = 'scene']">
				<section id="{@xml:id}">
					<xsl:attribute name="class" select="@type"/>
					<xsl:apply-templates/>
				</section>
			</xsl:when>
			<xsl:when test="@type = 'index'">
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
						<section id="{@xml:id}">
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
		<xsl:variable name="rotate">
			<xsl:choose>
				<xsl:when test="contains(@url, '/90/')">
					<xsl:text>90</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>0</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="imageURL">
			<xsl:value-of select="concat('http://iiif.dh.tamu.edu/iiif/2/poetess%2Fbijou%2F', $imageNbr, '.tif/full/full/', $rotate, '/default.jpg')"/>
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
			<xsl:when test="parent::tei:sp/parent::tei:div[@type = 'scene']">
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
	
	<xsl:template match="tei:lg" mode="inQuote">
		<span class="poem"><xsl:apply-templates/></span>
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
				<p class="pnoindent">
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
				</p>
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
			<xsl:when test="parent::tei:lg/parent::tei:div[@type = 'poem'] | parent::tei:lg/parent::tei:sp/parent::tei:div[@type = 'scene']">
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
	
	<xsl:template match="tei:p" mode="inQuote">
		<span class="blockquote">
			<xsl:apply-templates/>
		</span>
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
		<xsl:variable name="PAid">
			<xsl:value-of select="substring-after(@target, '#')"/>
		</xsl:variable>
		<xsl:variable name="PAtype">
			<xsl:choose>
				<xsl:when test="$PAid = 'FP'">
					<xsl:text>frontispiece</xsl:text>
				</xsl:when>
				<xsl:when test="contains($PAid, 'P')">
					<xsl:text>poem</xsl:text>
				</xsl:when>
				<xsl:when test="contains($PAid, 'S')">
					<xsl:text>story</xsl:text>
				</xsl:when>
				<xsl:when test="contains($PAid, 'D')">
					<xsl:text>drama</xsl:text>
				</xsl:when>
				<xsl:when test="contains($PAid, 'L')">
					<xsl:text>letter</xsl:text>
				</xsl:when>
				<xsl:when test="contains($PAid, 'F')">
					<xsl:text>picture</xsl:text>
				</xsl:when>
				<xsl:when test="contains($PAid, 'I')">
					<xsl:text>index</xsl:text>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="ancestor-or-self::tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct/tei:analytic">
				<a href="bijou1828.{$PAtype}{$PAid}.html">
					<xsl:apply-templates/>
				</a>
			</xsl:when>
			<xsl:otherwise>
				<a href="{@target}">
					<xsl:apply-templates/>
				</a>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="tei:ab">
		<p>
			<xsl:if test="@rend">
				<xsl:attribute name="class" select="@rend"/>
			</xsl:if>
			<xsl:apply-templates/>
		</p>
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
			<xsl:when test=".[@type = 'exit'] | .[@type = 'entrance']">
				<p>
					<xsl:attribute name="class" select="@type"/>
					<xsl:apply-templates/>
				</p>
			</xsl:when>
			<xsl:when test="@type = 'delivery'">
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
	
	<xsl:template match="tei:pb">
		<xsl:variable name="imgNbr">
			<xsl:value-of select="substring-after(@xml:id, 'image')"/>
		</xsl:variable>
		<xsl:variable name="URL">
			<xsl:value-of select="concat('http://iiif.dh.tamu.edu/iiif/2/poetess%2Fbijou%2F', $imgNbr, '.tif/full/full/0/default.jpg')"/>
		</xsl:variable>
		<xsl:variable name="class">
			<xsl:choose>
				<xsl:when test="parent::tei:p/parent::tei:quote/parent::tei:div">
					<xsl:text>pageNumber</xsl:text>
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
			<xsl:choose>
				<xsl:when test="@n">
					<xsl:text>[Page </xsl:text>
					<xsl:value-of select="@n"/>
					<xsl:text>]</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>[np]</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</span>
		<xsl:choose>
			<xsl:when test="parent::tei:div/@type = 'picture'"/>
			<xsl:otherwise>
				<span class="pageImage" id="{$imgNbr}">
					<a href="{$URL}">
						<img class="pageImage" alt="page image and link" src="http://iiif.dh.tamu.edu/iiif/2/poetess%2Fbijou%2F{$imgNbr}.tif/full/,70/0/default.jpg"/>
					</a>
				</span>
			</xsl:otherwise>
		</xsl:choose>
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
		<p id="{$noteNBR}"><xsl:value-of select="$noteNBR"/>. <xsl:apply-templates/>
			<xsl:text> </xsl:text>
			<a>
				<xsl:attribute name="href"><xsl:text>#back</xsl:text><xsl:value-of select="$noteNBR"/></xsl:attribute>
				<xsl:text>Back</xsl:text>
			</a>
		</p>
	</xsl:template>

</xsl:stylesheet>
