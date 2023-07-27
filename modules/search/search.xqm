xquery version "3.1";        
(:~  
 : Builds HTML search forms and HTMl search results Srophe Collections and sub-collections   
 :) 
module namespace search="http://srophe.org/srophe/search";

(:eXist templating module:)
import module namespace templates="http://exist-db.org/xquery/templates" ;

(: Import KWIC module:)
import module namespace kwic="http://exist-db.org/xquery/kwic";

(: Import Srophe application modules. :)
import module namespace config="http://srophe.org/srophe/config" at "../config.xqm";
import module namespace data="http://srophe.org/srophe/data" at "../lib/data.xqm";
import module namespace global="http://srophe.org/srophe/global" at "../lib/global.xqm";
import module namespace facet="http://expath.org/ns/facet" at "../lib/facet.xqm";
import module namespace sf="http://srophe.org/srophe/facets" at "../lib/facets.xql";
import module namespace page="http://srophe.org/srophe/page" at "../lib/paging.xqm";
import module namespace slider = "http://srophe.org/srophe/slider" at "../lib/date-slider.xqm";
import module namespace tei2html="http://srophe.org/srophe/tei2html" at "../content-negotiation/tei2html.xqm";

(: Syriaca.org search modules :)
import module namespace bibls="http://srophe.org/srophe/bibls" at "bibl-search.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(: Global Variables:)
declare variable $search:start {
    if(request:get-parameter('start', 1)[1] castable as xs:integer) then 
        xs:integer(request:get-parameter('start', 1)[1]) 
    else 1};
declare variable $search:perpage {
    if(request:get-parameter('perpage', 25)[1] castable as xs:integer) then 
        xs:integer(request:get-parameter('perpage', 25)[1]) 
    else 25
    };
(:~
 : Search results stored in map for use by other HTML display functions
:)
declare %templates:wrap function search:search-data($node as node(), $model as map(*), $collection as xs:string?, $sort-element as xs:string?){
    let $queryExpr := if($collection = 'bibl') then
                            bibls:query-string()
                      else search:query-string($collection)                 
    let $hits := if($queryExpr != '') then 
                     data:search($collection, $queryExpr, $sort-element)
                 else data:search($collection, '', $sort-element)                 
    return
        if($collection = 'collections') then 
                let $collectionTypes := distinct-values(collection($config:data-root)//tei:category[tei:catDesc[starts-with(.,'collection ')]]/@xml:id) 
                let $collectionRefIDs := string-join(for $c in $collectionTypes return concat('#',$c),'|')
                let $collectionHits := 
                                    if(request:get-parameter('collection-id', '') != '') then $hits
                                    else 
                                        for $ch in $hits[descendant::tei:catRef/@target[matches(.,concat('(',$collectionRefIDs,')(\W|$)'))]]                 
                                        return $ch
                return 
                    map {
                        "hits" := $collectionHits,                              
                        "collectionTypes" :=  $collectionTypes,
                        "query" := $queryExpr,
                        "sort" := $sort-element
                        } 
        else 
            map {
                "hits" := $hits,
                "query" := $queryExpr,
                "sort" := $sort-element
            } 
};

declare %templates:wrap function search:group-by-author($node as node(), $model as map(*), $collection as xs:string?){
   map {"group-by-authors" := 
        let $hits := $model("hits")
        let $authors := distinct-values(
                        for $a in $hits/descendant::tei:sourceDesc/tei:biblStruct/descendant-or-self::tei:author | $hits/descendant::tei:sourceDesc/tei:biblStruct/descendant-or-self::tei:editor 
                        let $name := if($a/tei:name/@reg) then string($a/tei:name/@reg)
                                     else if($a/tei:name/tei:surname) then concat($a/tei:name/tei:surname//text(),', ', $a/tei:name/tei:forename)
                                     else if($a/tei:name) then $a/tei:name//text()
                                     else $a//text()
                        let $normalized := if(contains($name,('Unknown','unknown','Anonymous','anonymous','[anon.]','[anon]','[Anon.]'))) then ' Anonymous' else normalize-space(string-join($name,''))                                     
                        return $normalized)
        return 
            if(request:get-parameter('author-exact', '')) then 
               for $author in $authors[. = request:get-parameter('author-exact', '')]
               order by $author 
               return 
                    <browse xmlns="http://www.w3.org/1999/xhtml" author="{$author}"/>
            else 
                for $author in $authors
                order by $author 
                return 
                    <browse xmlns="http://www.w3.org/1999/xhtml" author="{$author}"/>
   }    
};

(:~ 
 : Builds results output
 <div>debug {search:query-string($collection)}</div>
:)
declare 
    %templates:default("start", 1)
function search:show-collections($node as node()*, $model as map(*), $collection as xs:string?, $kwic as xs:string?) {
    let $collectionTypes := $model("collectionTypes")
    let $collectionHits := $model("hits")
    return
    <div xmlns="http://www.w3.org/1999/xhtml">
       <div class="collections-jump" id="top">
        {
        if(request:get-parameter('collection-id', '')) then
            <a href="{request:get-url()}" class="btn btn-primary">Back to Collections</a>
        else 
            for $type at $p in $collectionTypes 
            let $collection-title := replace($collectionHits/descendant::tei:category[@xml:id = $type][1],'collection ','')
            order by $collection-title
            where $collectionHits[descendant::tei:catRef/@target[matches(.,concat('(',$type,')','(\W|$)'))]]
            return 
                if(request:get-parameter('collection-id', '')) then
                    <a href="{request:get-url()}#{$collection/@collection-type}" class="btn btn-primary">{$collection-title}</a>
                else <a href="#{$type}" class="btn btn-primary">{$collection-title}</a>
        }</div>
       <div class="indent" id="search-results">{
            if(request:get-parameter('collection-id', '')) then
                <div>{
                    let $collectionRefIDs := string-join(for $c in $collectionTypes return concat('#',$c),'|')
                    let $collection := for $c in collection($config:data-root)//tei:TEI[descendant::tei:seriesStmt[tei:idno ='bijou1828-p5.xml']][descendant::tei:catRef/@target[matches(.,concat('(',$collectionRefIDs,')(\W|$)'))]]                 
                                       return $c
                    let $collection-id := request:get-parameter('collection-id', '')
                    return
                    <div>
                        <span class="collection-titles">{tei2html:summary-view($collection, '', $collection-id)}</span>
                        <div class="toolbar">{page:pages($model("hits"), $collection, $search:start, $search:perpage,'', 'author,title,pubDate,pubPlace',())}</div>
                        {
                        for $work at $p in subsequence($collectionHits,$search:start,$search:perpage) 
                        let $work-id := replace($work/descendant::tei:publicationStmt/tei:idno[1],'/tei','')
                        let $kwic := if($kwic = ('true','yes','true()','kwic')) then kwic:expand($work) else ()               
                        (:where $work-id != $collection-id:)
                        return 
                            <div class="indent result">{(
                                tei2html:summary-view($work, '', $work-id),
                                if($kwic//exist:match) then 
                                    tei2html:output-kwic($kwic, $work-id)
                                else ()
                            )}</div>
                        }
                    </div>  
                }</div>
            else 
                for $type at $p in $collectionTypes 
                let $collection-title := normalize-space(replace($collectionHits/descendant::tei:category[@xml:id = $type][1],'collection ',''))
                order by $collection-title
                let $typeHits := $collectionHits[descendant::tei:catRef/@target[matches(.,concat('(',$type,')','(\W|$)'))]]
                where $typeHits
                return 
                   <div id="{$type}">{(
                        <h3>{concat(upper-case(substring($collection-title,1,1)),substring($collection-title,2))}</h3>,<hr/>, 
                        for $work in $typeHits
                        let $seriesId := $work/descendant::tei:seriesStmt/tei:idno
                        let $subsidiaryItems := count(collection($config:data-root)/tei:TEI[descendant::tei:seriesStmt/tei:idno = $seriesId])
                        let $name := if($work/descendant-or-self::tei:author) then $work/descendant-or-self::tei:author[1] 
                                     else $work/descendant::tei:sourceDesc/tei:biblStruct/descendant-or-self::tei:editor[1]
                        let $name := if($name/tei:name/@reg) then $name/tei:name/@reg
                                     else if($name/tei:name/tei:surname) then $name/tei:name/tei:surname
                                     else if($name/tei:name) then $work/tei:name
                                     else $name//text()
                        let $id := replace($work/descendant::tei:idno[1],'/tei','')
                        order by $name
                        return
                            <div>
                                {tei2html:summary-view($work, '', $id)} 
                                {if($subsidiaryItems gt 0) then
                                    <span><a href="search.html?collection-id={$seriesId}" class="btn btn-default pull-right">Seel all {$subsidiaryItems} collection items</a></span>
                                else ()}
                            </div>
                    )}</div>                            
        }</div>
    </div>
};

(:~ 
 : Builds results output
 <div>debug {search:query-string($collection)}</div>
:)
declare 
    %templates:default("start", 1)
function search:show-authors($node as node()*, $model as map(*), $collection as xs:string?, $kwic as xs:string?) {
<div class="indent" id="search-results" xmlns="http://www.w3.org/1999/xhtml">
    {
            let $hits := $model("group-by-authors")
            for $hit at $p in $hits (:subsequence($hits, $search:start, $search:perpage):)
            let $alpha := substring($hit/@author,1,1)
            group by $alpha-grp := $alpha
            return 
                <div id="{if($alpha-grp = ' ') then 'Anonymous' else $alpha-grp}">{(
                    if(request:get-parameter('author-exact', '') != '') then ()
                    else <label>{if($alpha-grp = ' ') then 'Anonymous' else $alpha-grp}</label>,
                    <div class="indent">{
                    for $a in $hit
                    return 
                    <div class="result authors" xmlns="http://www.w3.org/1999/xhtml"> 
                        {if((count($model("hits")) gt $search:perpage) and request:get-parameter('author-exact', '') != '') then
                            <div class="toolbar-min">{page:pages($model("hits"), $collection, $search:start, $search:perpage,'', 'author,title,pubDate,pubPlace',())}</div>
                        else ()}
                         <a href="{request:get-uri()}?author-exact={string($a/@author)}">{string($a/@author)}</a>
                         {
                            if(request:get-parameter('author-exact', '') or request:get-parameter('details', '') = 'true') then 
                                let $hits := $model("hits")
                                for $hit at $p in subsequence($hits, $search:start, $search:perpage)
                                let $id := replace($hit/descendant::tei:idno[1],'/tei','')
                                return 
                                 <div class="row result" xmlns="http://www.w3.org/1999/xhtml">
                                    <div class="col-md-1" style="margin-right:-1em; padding-top:.25em;">        
                                        <span class="badge" style="margin-right:1em;">{$search:start + $p - 1}</span>
                                    </div>
                                     <div class="col-md-11" style="margin-right:-1em; padding-top:.25em;">
                                         {tei2html:summary-view($hit, '', $id)}
                                     </div>
                                 </div>                              
                            else ()
                         }
                    </div>
                    }</div>
                )}</div>
   }  
</div>
};

(:~ 
 : Builds results output
 <div>debug {search:query-string($collection)}</div>
:)
declare 
    %templates:default("start", 1)
function search:show-hits($node as node()*, $model as map(*), $collection as xs:string?, $kwic as xs:string?) {
<div class="indent" id="search-results" xmlns="http://www.w3.org/1999/xhtml">
    {
            let $hits := $model("hits")
            for $hit at $p in subsequence($hits, $search:start, $search:perpage)
            let $id := replace($hit/descendant::tei:idno[1],'/tei','')
            let $kwic := if($kwic = ('true','yes','true()','kwic')) then kwic:expand($hit) else () 
            return 
             <div class="row record" xmlns="http://www.w3.org/1999/xhtml" style="border-bottom:1px dotted #eee; padding-top:.5em">
                 <div class="col-md-1" style="margin-right:-1em; padding-top:.25em;">        
                     <span class="badge" style="margin-right:1em;">{$search:start + $p - 1}</span>
                 </div>
                 <div class="col-md-11" style="margin-right:-1em; padding-top:.25em;">
                     {tei2html:summary-view($hit, '', $id)}
                     {
                        if($kwic//exist:match) then 
                           tei2html:output-kwic($kwic, $id)
                        else ()
                     }
                 </div>
             </div>   
  }  
</div>
};

(:~
 : Build advanced search form using either search-config.xml or the default form search:default-search-form()
 : @param $collection. Optional parameter to limit search by collection. 
 : @note Collections are defined in repo-config.xml
 : @note Additional Search forms can be developed to replace the default search form.
 : @depreciated: do a manual HTML build, add xquery keyboard options 
:)
declare function search:search-form($node as node(), $model as map(*), $collection as xs:string?){
if(exists(request:get-parameter-names())) then ()
else 
    let $search-config := 
        if($collection != '') then concat($config:app-root, '/', string(config:collection-vars($collection)/@app-root),'/','search-config.xml')
        else concat($config:app-root, '/','search-config.xml')
    return 
        if($collection ='bibl') then <div>{bibls:search-form()}</div>
        else if(doc-available($search-config)) then 
            search:build-form($search-config)             
        else search:default-search-form()
};

(:~
 : Builds a simple advanced search from the search-config.xml. 
 : search-config.xml provides a simple mechinisim for creating custom inputs and XPaths, 
 : For more complicated advanced search options, especially those that require multiple XPath combinations
 : we recommend you add your own customizations to search.xqm
 : @param $search-config a values to use for the default search form and for the XPath search filters.
 : @depreciated: do a manual HTML build, add xquery keyboard options 
:)
declare function search:build-form($search-config) {
    let $config := doc($search-config)
    return 
        <form method="get" class="form-horizontal indent" role="form">
            <h1 class="search-header">{if($config//label != '') then $config//label else 'Search'}</h1>
            {if($config//desc != '') then 
                <p class="indent info">{$config//desc}</p>
            else() 
            }
            <div class="search-box">
                <div class="row">
                    <div class="col-md-10">{
                        for $input in $config//input
                        let $name := string($input/@name)
                        let $id := concat('s',$name)
                        return 
                            <div class="form-group">
                                <label for="{$name}" class="col-sm-2 col-md-3  control-label">{string($input/@label)}: 
                                {if($input/@title != '') then 
                                    <span class="glyphicon glyphicon-question-sign text-info moreInfo" aria-hidden="true" data-toggle="tooltip" title="{string($input/@title)}"></span>
                                else ()}
                                </label>
                                <div class="col-sm-10 col-md-9 ">
                                    <div class="input-group">
                                        <input type="text" 
                                        id="{$id}" 
                                        name="{$name}" 
                                        data-toggle="tooltip" 
                                        data-placement="left" class="form-control keyboard"/>
                                        {($input/@title,$input/@placeholder)}
                                        {
                                            if($input/@keyboard='yes') then 
                                                <span class="input-group-btn">{global:keyboard-select-menu($id)}</span>
                                             else ()
                                         }
                                    </div> 
                                </div>
                            </div>}
                    </div>
                </div> 
            </div>
            <div class="pull-right">
                <button type="submit" class="btn btn-info">Search</button>&#160;
                <button type="reset" class="btn btn-warning">Clear</button>
            </div>
            <br class="clearfix"/><br/>
        </form> 
};

(:~
 : Simple default search form to us if not search-config.xml file is present. Can be customized. 
:)
declare function search:default-search-form() {
    <form method="get" class="form-horizontal indent" role="form">
        <h1 class="search-header">Advanced Search</h1>
        <div class="search-box">
            <div class="row">
                <div class="col-md-10">
                    <!-- Keyword -->
                    <div class="form-group">
                        <label for="keyword" class="col-sm-2 col-md-3  control-label">Keyword: </label>
                        <div class="col-sm-10 col-md-9 ">
                            <div class="input-group">
                                <input type="text" id="keyword" name="keyword" class="form-control keyboard"/>
                            </div> 
                        </div>
                    </div>
                    <!-- Authors -->
                    <div class="form-group">
                        <label for="author" class="col-sm-2 col-md-3  control-label">Authors: </label>
                        <div class="col-sm-10 col-md-9 ">
                            <div class="input-group">
                                <input type="text" id="author" name="author" class="form-control keyboard"/>
                            </div>   
                        </div>
                    </div>
                    <!-- Works -->
                    <div class="form-group">
                        <label for="works" class="col-sm-2 col-md-3  control-label">Works: </label>
                        <div class="col-sm-10 col-md-9 ">
                            <div class="input-group">
                                <input type="text" id="works" name="works" class="form-control keyboard"/>
                            </div>   
                        </div>
                    </div>
                    <!-- Publisher -->
                    <div class="form-group">
                        <label for="publisher" class="col-sm-2 col-md-3  control-label">Publisher: </label>
                        <div class="col-sm-10 col-md-9 ">
                            <div class="input-group">
                                <input type="text" id="publisher" name="publisher" class="form-control keyboard"/>
                            </div>   
                        </div>
                    </div> 
                    <!-- Place of publication -->
                    <div class="form-group">
                        <label for="pubplace" class="col-sm-2 col-md-3  control-label">Place of publication: </label>
                        <div class="col-sm-10 col-md-9 ">
                            <div class="input-group">
                                <input type="text" id="pubplace" name="pubplace" class="form-control keyboard"/>
                            </div>   
                        </div>
                    </div> 
                    <!-- Dates -->
                    <div class="form-group row">
                        <label for="startDate" class="col-sm-2 col-md-3 control-label">Year range: </label>
                        <div class="col-sm-4">
                          <input type="text" id="startDate" name="startDate" class="form-control small keyboard" placeholder="From"/>
                        </div>
                        <div class="col-sm-4">
                          <input type="text" id="endDate" name="endDate" class="form-control small keyboard" placeholder="To"/>
                        </div>
                    </div>
                    <!-- Publication Type -->
                    <div class="form-group">
                        <label for="pubType" class="col-sm-2 col-md-3  control-label">Publication Type: </label>
                        <div class="col-sm-10 col-md-9 ">
                            In process  
                        </div>
                    </div>
                    <!-- Publication Type -->
                    <div class="form-group">
                        <label for="fullText" class="col-sm-2 col-md-3  control-label">Full Text Documents Only </label>
                        <div class="col-sm-10 col-md-9 ">
                            In process  
                        </div>
                    </div>
                <!-- end col  -->
                </div>
                <!-- end row  -->

            </div>    
            <div class="pull-right submit">
                <button type="submit" class="btn btn-info">Search</button>&#160;
                <button type="reset" class="btn">Clear</button>
            </div>
            <br class="clearfix"/><br/>
        </div>
    </form>
};

(:~   
 : Builds general search string from main syriaca.org page and search api.
:)
declare function search:query-string($collection as xs:string?) as xs:string?{
let $search-config := concat($config:app-root, '/', string(config:collection-vars($collection)/@app-root),'/','search-config.xml')
return
    if($collection != '') then 
        if(doc-available($search-config)) then 
           concat("collection('",$config:data-root,"/",$collection,"')//tei:TEI",facet:facet-filter(global:facet-definition-file($collection)),slider:date-filter(()),data:dynamic-paths($search-config))
        else if($collection = 'places') then  
            concat("collection('",$config:data-root,"')//tei:TEI",
            facet:facet-filter(global:facet-definition-file($collection)),
            slider:date-filter(()),
            data:keyword-search(),
            data:element-search('placeName',request:get-parameter('placeName', '')),
            data:element-search('title',request:get-parameter('title', '')),
            data:element-search('bibl',request:get-parameter('bibl', '')),
            data:uri(),
            data:element-search('term',request:get-parameter('term', ''))
          )
        else
            concat("collection('",$config:data-root,"/",$collection,"')//tei:TEI",facet:facet-filter(global:facet-definition-file($collection)),
            facet:facet-filter(global:facet-definition-file($collection)),
            slider:date-filter(()),
            data:keyword-search(),
            data:element-search('placeName',request:get-parameter('placeName', '')),
            data:element-search('title',request:get-parameter('title', '')),
            data:element-search('bibl',request:get-parameter('bibl', '')),
            data:uri()
          )
    else concat("collection('",$config:data-root,"')//tei:TEI",
        facet:facet-filter(global:facet-definition-file($collection)),facet:facet-filter(global:facet-definition-file($collection)),
        slider:date-filter(()),
        data:keyword-search(),
        data:element-search('placeName',request:get-parameter('placeName', '')),
        data:element-search('title',request:get-parameter('title', '')),
        data:element-search('bibl',request:get-parameter('bibl', '')),
        data:uri()
        )
};
