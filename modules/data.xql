xquery version "3.1";
(:~  
 : Basic data interactions, returns raw data for use in other modules  
 : Not a library module
:)
import module namespace config="http://syriaca.org/srophe/config" at "config.xqm";
import module namespace data="http://syriaca.org/srophe/data" at "lib/data.xqm";
import module namespace d3xquery="http://syriaca.org/srophe/d3xquery" at "../d3xquery/d3xquery.xqm";
import module namespace tei2html="http://syriaca.org/srophe/tei2html" at "content-negotiation/tei2html.xqm";
import module namespace functx="http://www.functx.com";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace util="http://exist-db.org/xquery/util";

(: Get posted data :)
let $id := if(request:get-parameter('recordID', '')) then request:get-parameter('recordID', '') else request:get-parameter('id', '')
let $relationship := if(request:get-parameter('relationship', '') != '') then request:get-parameter('relationship', '') else ()  
let $mode := if(request:get-parameter('mode', '') != '') then request:get-parameter('mode', '') else ()
let $collection := if(request:get-parameter('collection', '') != '') then request:get-parameter('collection', '') else ()
let $format := if(request:get-parameter('format', '') != '') then request:get-parameter('format', '') else ()
let $collection-data := string(config:collection-vars($collection)/@data-root)
let $queryString := 
    concat("collection('",$config:data-root,"/",$collection-data,"')//tei:TEI[not(descendant::tei:publicationStmt/tei:idno = 'people')]",
        data:keyword-search(),
        data:element-search('placeName',request:get-parameter('placeName', '')),
        data:element-search('title',request:get-parameter('title', '')),
        data:element-search('bibl',request:get-parameter('bibl', '')),
        data:uri()
        )
let $results := 
    if(request:get-data()) then request:get-data()  
    else data:search($collection, $queryString, ())    
let $results := if(request:get-parameter('getVis', '')) then d3xquery:build-graph-type($results, $id, $relationship, $mode, ()) else $results    
return
    if(request:get-parameter('getPage', '') != '') then 
        $results
    else if(request:get-parameter('view', '') = 'expand' and request:get-parameter('workid', '') != '') then
        $results
    else 
    (response:set-header("Content-Type", "application/json"),
        serialize($results, 
            <output:serialization-parameters>
                <output:method>json</output:method>
            </output:serialization-parameters>))
(:            
return <div>{$results/descendant::tei:imprint}</div>
:)