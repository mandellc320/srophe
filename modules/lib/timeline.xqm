xquery version "3.0";

module namespace timeline="http://syriaca.org/srophe/timeline";

(:~
 : Module to build timeline json passed to http://cdn.knightlab.com/libs/timeline/latest/js/storyjs-embed.js widget
 : @author Winona Salesky <wsalesky@gmail.com>
 : @authored 2014-08-05
:)
import module namespace global="http://syriaca.org/srophe/global" at "global.xqm";
import module namespace config="http://syriaca.org/srophe/config" at "../config.xqm";
import module namespace tei2html="http://syriaca.org/srophe/tei2html" at "../content-negotiation/tei2html.xqm";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
(:
 : Display Timeline. Uses http://timeline.knightlab.com/
:)
declare function timeline:timeline(){ 
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
                    autolink:  'true',
                    source:     ]]>{timeline:get-publication-dates()}<![CDATA[,
                    embed_id:   'my-timeline'
                    });
                });
                ]]>
        </script>
    <div id="my-timeline"/>
    <p>*Timeline generated with <a href="http://timeline.knightlab.com/">http://timeline.knightlab.com/</a></p>
    </div>
};

(:
 : Display Timeline. Uses http://timeline.knightlab.com/
:)
declare function timeline:timeline($data as node()*, $title as xs:string*){
(: Test for valid dates json:xml-to-json() May want to change some css styles for font:)
if($data/descendant-or-self::*[@when or @to or @from or @notBefore or @notAfter]) then 
    <div class="timeline">
        <script type="text/javascript" src="http://cdn.knightlab.com/libs/timeline/latest/js/storyjs-embed.js"/>
        <script type="text/javascript">
        <![CDATA[
            $(document).ready(function() {
                var parentWidth = $(".timeline").width();
                createStoryJS({
                    start:      'start_at_end',
                    type:       'timeline',
                    width:      "'" +parentWidth+"'",
                    height:     '525',
                    source:     ]]>{timeline:get-publication-dates()}<![CDATA[,
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