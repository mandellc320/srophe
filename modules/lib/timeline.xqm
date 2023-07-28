xquery version "3.0";

module namespace timeline="http://srophe.org/srophe/timeline";

(:~
 : Module to build timeline json passed to http://cdn.knightlab.com/libs/timeline/latest/js/storyjs-embed.js widget
 : @author Winona Salesky <wsalesky@gmail.com>
 : @authored 2014-08-05
:)
import module namespace config="http://srophe.org/srophe/config" at "../config.xqm";
import module namespace global="http://srophe.org/srophe/global" at "global.xqm";
import module namespace tei2html="http://srophe.org/srophe/tei2html" at "../content-negotiation/tei2html.xqm";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
(:
 : Display Timeline. Uses http://timeline.knightlab.com/
:)
declare function timeline:timeline($data as node()*, $title as xs:string*){
(: Test for valid dates json:xml-to-json() May want to change some css styles for font:)
if($data/descendant-or-self::*[@when or @to or @from or @notBefore or @notAfter]) then 
    <div class="timeline">
        <script type="text/javascript" src="https://cdn.knightlab.com/libs/timeline/latest/js/storyjs-embed.js"/>
        <script type="text/javascript">
        <![CDATA[
            $(document).ready(function() {
                var parentWidth = $(".timeline").width();
                createStoryJS({
                    start:      'start_at_end',
                    type:       'timeline',
                    width:      "'" +parentWidth+"'",
                    height:     '450',
                    source:     ]]>{timeline:get-all-dates($data, $title)}<![CDATA[,
                    embed_id:   'srophe-timeline'
                    });
                });
                ]]>
        </script>
    <div id="my-timeline"/>
    <p>*Timeline generated with <a href="http://timeline.knightlab.com/">http://timeline.knightlab.com/</a></p>
    </div>
else ()
};

(:
 : Display Timeline. Uses http://timeline.knightlab.com/
:)
declare function timeline:timeline($data as node()*, $title as xs:string*, $xpath as xs:string*){
(: Test for valid dates json:xml-to-json() May want to change some css styles for font:)
if($data/descendant-or-self::*[@when or @to or @from or @notBefore or @notAfter]) then 
    <div class="timeline">
        <script type="text/javascript" src="http://cdn.knightlab.com/libs/timeline/latest/js/storyjs-embed.js"/>
        <script type="text/javascript">
        <![CDATA[
            $(document).ready(function() {
                var parentWidth = $(".timeline").width();
                createStoryJS({
                    //start:      'start_at_end',
                    start_at_slide: slideID,
                    type:       'timeline',
                    width:      "'" +parentWidth+"'",
                    height:     '325',
                    source:     ]]>{timeline:get-all-dates($data, $title)}<![CDATA[,
                    embed_id:   'my-timeline'
                    });
                });
                ]]>
        </script>
    <div id="my-timeline"/>
    <p>*Timeline generated with <a href="http://timeline.knightlab.com/">http://timeline.knightlab.com/</a></p>
    </div>
else ()
};

(:
 : Format specified dates as JSON to be passed to timeline widget.
:)
declare function timeline:get-date-xpath($data as node()*, $title as xs:string*, $xpath as xs:string*){
let $timeline-title := if($title != '') then $title else 'Timeline'
let $dates := 
    <root>
        <timeline>
            <headline>{$timeline-title}</headline>
            <type>default</type>
            <asset>
                <media>{$config:app-title}</media>
                <credit>{$config:app-title}</credit>
                <caption>{$timeline-title}</caption>
            </asset>
            <date>
                {for $p in $xpath
                 for $date in util:eval(concat('$data/descendant-or-self::', $p))
                 let $start :=  if($date/@when) then string($date/@when)
                                else if($date/@from) then string($date/@from)
                                else if($date/@notBefore) then string($date/@notBefore)
                                else if($date/tei:date/@when) then string($date/tei:date[@when][1]/@when)
                                else if($date/tei:date/@from) then string($date/tei:date[@from][1]/@from)
                                else if($date/tei:date/@notBefore) then string($date/tei:date[@notBefore][1]/@notBefore)
                                else ()
                 let $end :=    if($date/@when) then string($date/@when)
                                else if($date/@to) then string($date/@to)
                                else if($date/@notAfter) then string($date/@notAfter)
                                else if($date/tei:date[@when][2]) then string($date/tei:date[@when][2]/@when)
                                else if($date/tei:date/@to) then string($date/tei:date[@to][2]/@to)
                                else if($date/tei:date/@notAfter) then string($date/tei:date[@notAfter][2]/@notAfter)
                                else ()  
                let $root := root($date)
                let $id := $root/descendant::tei:publicationStmt/tei:idno[@type='URI'][1]                  
                let $title := string-join($root//tei:titleStmt/tei:title[1]//text(),' ')
                let $link := replace(replace($id,$config:base-uri,$config:nav-base),'/tei','')
                order by $start, $title
                return                   
                    if($start != '' or $end != '') then 
                        timeline:format-dates($start, $end, $title, string-join($date/descendant-or-self::text(),' '), $link, $id)
                    else () 
                 }</date>
        </timeline>
    </root>
return
    serialize($dates, 
        <output:serialization-parameters>
            <output:method>json</output:method>
        </output:serialization-parameters>)

};

(:
 : Format dates as JSON to be passed to timeline widget.
:)
declare function timeline:get-dates($data as node()*, $title as xs:string*){
let $timeline-title := if($title != '') then $title else 'Timeline'
let $dates := 
    <root>
        <timeline>
            <headline>{$timeline-title}</headline>
            <type>default</type>
            <asset>
                <media>LiC.org</media>
                <credit>LiC.org</credit>
                <caption>Events for {$timeline-title}</caption>
            </asset>
            <date>
                {(
                    timeline:get-date-published($data)
                    )}</date>
        </timeline>
    </root>
return
    serialize($dates, 
        <output:serialization-parameters>
            <output:method>json</output:method>
        </output:serialization-parameters>)

};

(: Do all publication dates :)
declare function timeline:get-publication-dates(){
let $imprints := collection($config:data-root)//tei:sourceDesc[descendant::tei:date]
let $dates := 
    <root>
        <timeline>
            <headline>Publication Dates</headline>
            <type>default</type>
            <asset>
                <media>LiC.org</media>
                <credit>LiC.org</credit>
                <caption>Publication Dates</caption>
            </asset>
            <date>
                {(
                    timeline:get-date-published($imprints)
                    )}</date>
        </timeline>
    </root>
return
    serialize($dates, 
        <output:serialization-parameters>
            <output:method>json</output:method>
        </output:serialization-parameters>)

};


declare function timeline:format-dates($start as xs:string*, $end as xs:string*, $headline as xs:string*, $text as xs:string*, $link as xs:string*){
    if($start != '' or $end != '') then 
        <json:value json:array="true">
            {(
                if($start != '' or $end != '') then 
                    <startDate>
                        {
                            if(empty($start)) then $end
                            else if(starts-with($start,'-')) then concat('-',tokenize($start,'-')[2])
                            else replace($start,'-',',')
                        }
                    </startDate>
                 else (),
                if($end != '') then 
                    <endDate>
                        {
                            if(starts-with($end,'-')) then concat('-',tokenize($end,'-')[2])
                            else replace($end,'-',',')
                        }
                    </endDate>
                 else (),
                 if($headline != '') then 
                    <headline>{$headline}</headline>
                 else (),
                 if($text != '') then 
                    <text>{$text}<![CDATA[ <a href="]]>{$link}<![CDATA["><span class="glyphicon glyphicon-circle-arrow-right"></span></a>]]></text> 
                else ()                 
                )}
        </json:value>
    else ()
};

(: Dates with link to resource :)
declare function timeline:format-dates($start as xs:string*, $end as xs:string*, $headline as xs:string*, $text as xs:string*, $link as xs:string*, $id as xs:string?){
    if($start != '' or $end != '') then 
        <json:value json:array="true">
            {(
                if($start != '' or $end != '') then 
                    <startDate>
                        {
                            if(empty($start)) then $end
                            else if(starts-with($start,'-')) then concat('-',tokenize($start,'-')[2])
                            else replace($start,'-',',')
                        }
                    </startDate>
                 else (),
                if($end != '') then 
                    <endDate>
                        {
                            if(starts-with($end,'-')) then concat('-',tokenize($end,'-')[2])
                            else replace($end,'-',',')
                        }
                    </endDate>
                 else (),
                 if($headline != '') then 
                    <headline>{$headline}</headline>
                 else (),
                 if($text != '') then 
                    <text>{$text}<![CDATA[ <a href="]]>{$link}<![CDATA["><span class="glyphicon glyphicon-circle-arrow-right"></span></a>]]></text> 
                else (),
                <id>{$id}</id>
                )}
        </json:value>
    else ()
};

(:~
 : Build datePublished
 : @param $data as node
:)
declare function timeline:get-date-published($data as node()*) as node()*{
    if($data/descendant-or-self::tei:date) then
        for $imprint in $data/descendant::tei:imprint
        let $title := $imprint/ancestor::tei:sourceDesc/descendant::tei:title[1]
        let $root := root($imprint)
        let $doc := document-uri($root)
        let $id := replace($root/descendant::tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[1],'/tei','')
        let $id := if(contains($id, '/')) then tokenize($id,'/')[last()] else $id
        let $series := normalize-space(string($root/descendant-or-self::tei:seriesStmt/tei:title[@level="s"][1]))
        let $collection-path := if($series = '') then
                                    let $s := tokenize(replace($doc,$config:data-root,''),'/')[2]
                                    return string($config:get-config//repo:collection[@data-root=$s][1]/@app-root)
                                else string($config:get-config//repo:collection[@title=$series][1]/@app-root)
        let $link := concat($config:nav-base,$collection-path,'work/',replace(replace($id,$config:data-root,''),'.xml',''))
        let $citation :=
            let $monograph := $imprint/ancestor::tei:sourceDesc[1]/descendant::tei:monogr[1]
            return 
                (tei2html:tei2html($monograph/tei:title),
                        if($monograph/tei:imprint) then 
                          concat(' (',
                           normalize-space(string-join($monograph[1]/tei:imprint[1]/tei:pubPlace[1],'')),
                           if($monograph/tei:imprint/tei:publisher) then 
                            concat(': ', normalize-space(string-join($monograph[1]/tei:imprint[1]/tei:publisher[1],'')))
                           else (),
                           if($monograph/tei:imprint/tei:date) then 
                            concat(', ', normalize-space(string-join($monograph[1]/tei:imprint[1]/tei:date[1],'')))
                           else ()
                           ,') ')
                        else ()
                        )
        let $citation := string-join($citation,' ')            
        let $start := if($imprint/tei:date/@when) then
                        string($imprint/tei:date[1]/@when)
                     else if($imprint/tei:date/@from) then   
                        string($imprint/tei:date[1]/@from)
                     else ()
        let $end := if($imprint/tei:date/@when) then
                        string($imprint/tei:date[1]/@when)
                     else if($imprint/tei:date/@to) then   
                        string($imprint/tei:date[1]/@to)
                     else ()   
        let $imprint-text := normalize-space(concat($title,' ',tei2html:tei2html($imprint/tei:date[1])))
        return timeline:format-dates($start, $end,$imprint-text,$citation, $link)
    else () 
};
