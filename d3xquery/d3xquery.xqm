xquery version "3.1";

module namespace d3xquery="http://syriaca.org/srophe/d3xquery";
import module namespace config="http://syriaca.org/srophe/config" at "../modules/config.xqm";
import module namespace functx="http://www.functx.com";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace json="http://www.json.org";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare function d3xquery:list-relationship($records as item()*){
    <list>{
        for $r in distinct-values(for $r in $records//tei:relation return ($r/@ref,$r/@name) )
        return 
            <option label="{if(contains($r,':')) then substring-after($r,':') else $r}" value="{$r}"/>
            }
    </list>
};

declare function d3xquery:get-relationship($records, $relationship, $id){
    let $id := concat($id,'(\W.*)?$')
    let $all-relationships := 
            if(contains($relationship,'Select relationship') or contains($relationship,'All') or $relationship = '') then true() 
            else false()
    return 
        if($all-relationships = false()) then 
            if($id != '') then
               $records//tei:relation[@ref=$relationship or @name=$relationship][@passive[matches(.,$id)] or 
                    @active[matches(.,$id)] or
                    @mutual[matches(.,$id)]] 
            else $records//tei:relation[@ref=$relationship or @name=$relationship] 
        else if($id != '') then 
              $records//tei:relation[@passive[matches(.,$id)] or 
                    @active[matches(.,$id)] or
                    @mutual[matches(.,$id)]]
        else $records//tei:relation
};

(: Output based on d3js requirements for producing an HTML table:)
declare function d3xquery:format-table($relationships as item()*){        
        <root>{
                (
                <head>{
                for $attr in $relationships[1]/@* 
                return <vars>{name($attr)}</vars>
                }</head>,
                <results>{
                for $r in $relationships 
                return $r
                }</results>)
            }
        </root>
};

(: Output based on d3js requirements for producing a d3js tree format, single nested level, gives collection overview :)
declare function d3xquery:format-tree-types($relationships,$relationshipType){
(: poetess 
descendant::tei:catRef/@target

:)
if($relationships/@ref or $relationships/@name) then
<root>
        <data>
            <children>
                {
                    for $r in $relationships
                    let $group := if($r/@ref) then $r/@ref else $r/@name
                    group by $type := $group
                    order by count($r) descending
                    return 
                        <json:value>
                            <name>{string($type)}</name>
                            <size>{count($r)}</size>
                         </json:value>
                 }
            </children>
        </data>
    </root>
else if($relationshipType = 'taxonomy') then
  <root>
        <data>
            <children>
                {
                    for $cat in tokenize(string-join($relationships/descendant::tei:catRef/@target,' '),' ')
                    let $catRef := substring-after($cat,'#')
                    let $taxRef := replace($catRef,'\d*','')
                    group by $taxGrp := $catRef
                    let $categoryName := $relationships//tei:category[@xml:id = $catRef][1]
                    let $catGrp := $categoryName[1]/parent::tei:taxonomy/tei:bibl/text()
                    return 
                        if($categoryName) then  
                            <json:value>
                                <name>{normalize-space(string($categoryName[1]))}</name>
                                <id>{$cat[1]}</id>
                                <group>{normalize-space($catGrp)}</group>
                                <size>{count($cat)}</size>
                             </json:value>  
                        else ()      
                 }
            </children>
        </data>
    </root>  
else if($relationshipType = 'author') then
  <root>
        <data>
            <children>
                {
                    for $author in $relationships/descendant::tei:author
                    group by $authorGrp := normalize-space(string($author))
                    let $authorType := string($author[1]/@type)
                    return 
                        if(count($author) gt 1) then  
                            <json:value>
                                <name>{$authorGrp[1]}</name>
                                <id>{$authorGrp[1]}</id>
                                <group>{normalize-space($authorType)}</group>
                                <size>{count($author)}</size>
                             </json:value>  
                        else ()      
                 }
            </children>
        </data>
    </root>  

else <root>Data does not match expected patterns</root>  
};

(: output based on d3js requirements :)
declare function d3xquery:format-relationship-graph($relationships){
    let $uris := distinct-values((
                    for $r in $relationships return tokenize($r/@active,' '), 
                    for $r in $relationships return tokenize($r/@passive,' '), 
                    for $r in $relationships return tokenize($r/@mutual,' ')
                    )) 
    return 
        <root>
            <nodes>
                {
                for $uri in $uris
                return
                    <json:value>
                        <id>{$uri}</id>
                        <label>{$uri}</label>
                   </json:value>
                }
            </nodes>
            <links>
                {
                    for $r in $relationships
                    return 
                        if($r/@mutual) then 
                             for $m in tokenize($r/@mutual,' ')
                             return 
                                 let $node := 
                                     for $p in tokenize($r/@mutual,' ')
                                     where $p != $m
                                     return 
                                         <json:value>
                                             <source>{$m}</source>
                                             <target>{$p}</target>
                                             <relationship>{replace($r/@ref,'^(.*?):','')}</relationship>
                                             <value>0</value>
                                         </json:value>
                                 return $node
                        else if(contains($r/@active,' ')) then 
                                (: Check passive for spaces/multiple values :)
                                if(contains($r/@passive,' ')) then 
                                    for $a in tokenize($r/@active,' ')
                                    return 
                                        for $p in tokenize($r/@passive,' ')
                                        return 
                                           <json:value>
                                                <source>{string($p)}</source>
                                                <target>{string($a)}</target>
                                                <relationship>{replace($r/@ref,'^(.*?):','')}</relationship>
                                                <value>0</value>
                                            </json:value> 
                                (: multiple active, one passive :)
                                else 
                                    let $passive := string($r/@passive)
                                    for $a in tokenize($r/@active,' ')
                                    return 
                                            <json:value>
                                                <source>{string($passive)}</source>
                                                <target>{string($a)}</target>
                                                <relationship>{replace($r/@name,'^(.*?):','')}</relationship>
                                                <value>0</value>
                                            </json:value>
                            (: One active multiple passive :)
                            else if(contains($r/@passive,' ')) then 
                                    let $active := string($r/@active)
                                    for $p in tokenize($r/@passive,' ')
                                    return 
                                            <json:value>
                                            {if(count($relationships) = 1) then attribute {xs:QName("json:array")} {'true'} else ()}
                                                <source>{string($p)}</source>
                                                <target>{string($active)}</target>
                                                <relationship>{replace($r/@ref,'^(.*?):','')}</relationship>
                                                <value>0</value>
                                            </json:value>
                                (: One active one passive :)            
                            else 
                                    <json:value>
                                    {if(count($relationships) = 1) then attribute {xs:QName("json:array")} {'true'} else ()}
                                        <source>{string($r/@passive)}</source>
                                        <target>{string($r/@active)}</target>
                                        <relationship>{replace($r/@ref,'^(.*?):','')}</relationship>
                                        <value>0</value>
                                    </json:value>
                }
            </links>
        </root>
};


(: output based on d3js requirements :)
declare function d3xquery:format-relationship-graph-people($data){
if($data/descendant::tei:name) then
    <root>
        <nodes>
            {( (: Works :)
              for $w in $data
              let $uri := $w/descendant::tei:publicationStmt/tei:idno
              let $title := $w/descendant::tei:title[1]
              let $id := 
                if(ends-with($uri,'/tei')) then replace($uri,'/tei','')
                else $uri 
              let $series := normalize-space(string($w/descendant-or-self::tei:seriesStmt/tei:title[@level="s"]))  
              let $collection-path := string($config:get-config//repo:collection[@title=$series]/@app-root)  
              let $link := concat($config:nav-base,$collection-path,'work/',replace($id,$config:base-uri,$config:nav-base))  
              return 
                <json:value>
                    <id>{string($uri)}</id>
                    <type>Work</type>
                    <label>{normalize-space(string-join($title,' '))}</label>
                    <link>{$link}</link>
                </json:value>,
              (: Names :)
              for $name in $data/descendant::tei:sourceDesc/descendant-or-self::tei:name | $data/descendant::tei:body/descendant-or-self::tei:name
              group by $facet-grp := normalize-space(string-join($name,' '))
              return 
                <json:value>
                    <id>{$facet-grp}</id>
                    <type>Person</type>
                    {for $n in $name
                     group by $n-grp := if(name($n/parent::*[1]) = 'ref') then name($n/parent::*[1]/parent::*[1]) else name($n/parent::*[1])
                     return 
                        <role json:array="true">{$n-grp}</role>
                    }
                    <label>{$facet-grp}</label>
                    <link>{concat($config:nav-base,'/creators/index.html?author=',encode-for-uri($facet-grp))}</link>
                </json:value>
            )}
        </nodes>
        <links>
            {
                for $w in $data
                let $workID := string($w/descendant::tei:publicationStmt/tei:idno)
                for $n in $w/descendant::tei:sourceDesc/descendant-or-self::tei:name | $w/descendant::tei:body/descendant-or-self::tei:name
                let $nameID := normalize-space(string-join($n,' '))
                let $r := if(name($n/parent::*[1]) = 'ref') then name($n/parent::*[1]/parent::*[1]) else name($n/parent::*[1])
                return 
                    <json:value>
                        <source>{$workID}</source>
                        <target>{$nameID}</target>
                        <relationship>{$r}</relationship>
                        <value>0</value>
                    </json:value>
            }
        </links>
    </root>
else () 
};

declare function d3xquery:build-graph-type($records, $id as xs:string?, $relationship as xs:string?, $type as xs:string?){
    let $data := 
        if($type = ('Force','Sankey')) then 
            if($relationship = 'people') then
                d3xquery:format-relationship-graph-people($records)
            else d3xquery:format-relationship-graph(d3xquery:get-relationship($records, $relationship, $id))
        else if($type = ('Table','table','Bundle')) then 
            d3xquery:format-table(d3xquery:get-relationship($records, $relationship, $id))
        else if($type = ('Tree','Round Tree','Circle Pack','Bubble','bubble')) then
            if($relationship = 'taxonomy') then 
                d3xquery:format-tree-types($records,$relationship)
            else if($relationship = 'author') then   
                d3xquery:format-tree-types($records,$relationship)
            else d3xquery:format-tree-types(d3xquery:get-relationship($records, $relationship, $id),$relationship)
        else if($type = ('Bar Chart','Pie Chart')) then
            d3xquery:format-tree-types(d3xquery:get-relationship($records, $relationship, $id),$relationship)   
        else d3xquery:format-table(d3xquery:get-relationship($records, $relationship, $id)) 
    return 
        if(request:get-parameter('format', '') = ('json','JSON')) then
            (serialize($data, 
                        <output:serialization-parameters>
                            <output:method>json</output:method>
                        </output:serialization-parameters>),
                        response:set-header("Content-Type", "application/json"))        
        else $data
};        

(:
 : Visualize data
:)
declare function d3xquery:html-display($data, $relationship as xs:string?, $type as xs:string?) {
    let $record := request:get-parameter('recordID', '')
    let $collectionPath := request:get-parameter('collection', '')
    let $data := 
            if($data/descendant::tei:title) then $data
            else if($record != '') then
            (: Return a single TEI record:)
                collection($config:data-root)/tei:TEI[.//tei:idno[@type='URI'][. = concat($record,'/tei')]][1]
            (: Return a collection:)
            else if($collectionPath != '') then 
                collection(string($collectionPath))
            (: Return all TEI data:)     
            else collection($config:data-root)  
    let $type := if($type) then $type else if(request:get-parameter('type', '') != '') then request:get-parameter('type', '') else 'Force'
    let $relationship := if($relationship) then $relationship else if(request:get-parameter('relationship', '') != '') then request:get-parameter('relationship', '') else ()
    let $formatedData := d3xquery:build-graph-type($data, (), $relationship, $type)
    let $json := 
            (serialize($formatedData, 
               <output:serialization-parameters>
                   <output:method>json</output:method>
               </output:serialization-parameters>))
    return 
        if(not(empty($data))) then 
            <div id="LODResults" xmlns="http://www.w3.org/1999/xhtml">
                <script src="{$config:nav-base}/d3xquery/js/d3.v4.min.js" type="text/javascript"/>
                <div id="graphVis" style="height:500px;"/>
                <script><![CDATA[
                        $(document).ready(function () {
                            var rootURL = ']]>{$config:nav-base}<![CDATA[';
                            var postData =]]>{$json}<![CDATA[;
                            var id = ']]>{request:get-parameter('id', '')}<![CDATA[';
                            var type = ']]>{$type}<![CDATA[';
                            if($('#graphVis svg').length == 0){
                               	selectGraphType(postData,rootURL,type);
                               }
                            jQuery(window).trigger('resize');
                        
                        });
                ]]></script>
                <style><![CDATA[
                    .d3jstooltip {
                      background-color:white;
                      border: 1px solid #ccc;
                      border-radius: 6px;
                      padding:.5em;
                      }
                    }
                    ]]>
                </style>
                <script src="{$config:nav-base}/d3xquery/js/vis.js" type="text/javascript"/>
            </div>
        else ()
};
