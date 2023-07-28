xquery version "3.1";

module namespace d3xquery="http://srophe.org/srophe/d3xquery";
import module namespace config="http://srophe.org/srophe/config" at "../modules/config.xqm";
import module namespace tei2html="http://srophe.org/srophe/tei2html" at "../modules/content-negotiation/tei2html.xqm";
import module namespace bibl2html="http://srophe.org/srophe/bibl2html" at "../modules/content-negotiation/bibl2html.xqm";
import module namespace functx="http://www.functx.com";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace json="http://www.json.org";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare function d3xquery:formatDate($date){
let $formatDate := 
    if($date castable as xs:date) then xs:date($date)
    else if(matches($date,'^\d{4}$')) then 
        let $newDate :=  concat($date,'-01-01')
        return 
            if($newDate castable as xs:date) then xs:date($newDate)
            else $newDate
    else if(matches($date,'^\d{4}-\d{2}')) then 
        let $newDate :=  concat($date,'-01')
        return 
            if($newDate castable as xs:date) then xs:date($newDate)
            else $newDate            
    else $date
return 
    if(not(empty($formatDate))) then 
        try {format-date(xs:date($formatDate), "[M]-[D]-[Y]")} catch * {concat('ERROR: invalid date.' ,$formatDate)}
    else ()    
};

declare function d3xquery:startDate($date){
    if($date[@type = 'circa'] or contains($date,'circa')) then 
        if($date[@notBefore] and $date[@notAfter]) then 
            d3xquery:formatDate($date/@notBefore)
        else ()    
    else if($date[@when]) then
        d3xquery:formatDate($date/@when)
    else if($date[@from] and $date[@to]) then
        d3xquery:formatDate($date/@from)
    else if($date[@notBefore] and $date[@notAfter]) then   
        d3xquery:formatDate($date/@notBefore)
    else if($date[@notBefore] and $date[@to]) then     
        d3xquery:formatDate($date/@notBefore)
    else if($date[@from] and $date[@notAfter]) then  
        d3xquery:formatDate($date/@from)
    else if($date[@notAfter]) then ()    
    else if($date[@notBefore]) then 
        d3xquery:formatDate($date/@notBefore)
    else if($date[@to]) then ()    
    else if($date[@from]) then 
        d3xquery:formatDate($date/@from)
    else d3xquery:formatDate($date)
};

declare function d3xquery:endDate($date){
    if($date[@type = 'circa'] or contains($date,'circa')) then 
        if($date[@notBefore] and $date[@notAfter]) then 
            d3xquery:formatDate($date/@notAfter)
        else 'Possible error'    
    else if($date[@when]) then ()
    else if($date[@from] and $date[@to]) then
        d3xquery:formatDate($date/@to)
    else if($date[@notBefore] and $date[@notAfter]) then   
        d3xquery:formatDate($date/@notAfter)
    else if($date[@notBefore] and $date[@to]) then     
        d3xquery:formatDate($date/@to)   
    else if($date[@from] and $date[@notAfter]) then  
        d3xquery:formatDate($date/@notAfter)  
    else if($date[@notAfter]) then    
        d3xquery:formatDate($date/@notAfter)
    else if($date[@notBefore]) then ()  
    else if($date[@to]) then 
        d3xquery:formatDate($date/@to)
    else if($date[@from]) then () 
    else ()
};

declare function d3xquery:timelineNodes($events){
for $event at $level in $events/descendant::tei:sourceDesc[descendant::tei:date]
let $title := $event/descendant::tei:title[1]
let $eventTitle := normalize-space(string-join($title//text(),' '))
let $id := string($event/ancestor::tei:TEI/descendant::tei:publicationStmt/tei:idno[1])
let $series := normalize-space(string($event/ancestor-or-self::tei:TEI/descendant::tei:seriesStmt[1]/tei:title[@level="s"][1]))
let $collection-path := string($config:get-config//repo:collection[@title=$series]/@app-root)
let $recID := concat($config:nav-base,$collection-path,'work/',replace($id,$config:base-uri,$config:nav-base))
return 
    for $label in $event/descendant::tei:imprint
    let $eventlabel := normalize-space(string-join(bibl2html:citation($event/ancestor::tei:TEI)))                       
    let $catRef := tokenize(replace(string($event/ancestor::tei:TEI/descendant::tei:catRef[@scheme="#f"]/@target),'#',''),' ')[1]
    let $eventType := normalize-space(($event/ancestor::tei:TEI/descendant::tei:taxonomy[@xml:id="f"]/descendant::tei:category[@xml:id = $catRef]/tei:catDesc))
    (:
    let $end := if(d3xquery:endDate($label/tei:date) != '') then substring(tokenize(d3xquery:endDate($label/tei:date),'-')[last()],1,2)
                else if(d3xquery:startDate($label/tei:date) != '') then substring(tokenize(d3xquery:startDate($label/tei:date),'-')[last()],1,2)
                else 0
    let $prev := if(d3xquery:startDate($label/preceding-sibling::*[1]/tei:date) != '') then substring(tokenize(d3xquery:startDate($label/preceding-sibling::*[1]/tei:date),'-')[last()],1,2)
                 else if(d3xquery:endDate($label/preceding-sibling::*[1]/tei:date) != '') then substring(tokenize(d3xquery:endDate($label/preceding-sibling::*[1]/tei:date),'-')[last()],1,2)
                 else 0                
    let $level := 
        if(xs:integer($end) eq xs:integer($prev)) then $level + .5
        else if(xs:integer($end) lt xs:integer($prev)) then $level - .5
        else $level
     :)   
    return 
        if($label/tei:date[@type = 'circa'] or contains($label/tei:date,'circa')) then
        (: 6. Circa 
           Code: <date type=”circa” notBefore=”1095-01-01” notAfter=”1103-12-13”>circa 1099</date>
           display: center dot, dashed line to invisible end dots 
           #of points 3? :)
            if($label/tei:date[@notBefore] and $label/tei:date[@notAfter]) then   
                (
                    <nodes>
                        <name>{$eventTitle}</name>
                        <recid>{$recID}</recid>
                        <label>{$eventlabel}</label>
                        <eventType>{$eventType}</eventType>
                        <date>{d3xquery:formatDate($label/tei:date/@notBefore)}</date>
                        <displayType>circa</displayType>
                        <display>none</display>
                        <position>start</position>
                        <level json:literal="true">{$level}</level>
                        <id>{replace(generate-id($label/tei:date/@notBefore),'\.','')}</id>
                    </nodes>,
                    <nodes>
                        <name>{$eventTitle}</name>
                        <recid>{$recID}</recid>
                        <label>{$eventlabel}</label>
                        <eventType>{$eventType}</eventType>
                        <date>
                        { (:WS:Note will need to test this :)
                            let $start := tokenize(d3xquery:formatDate($label/tei:date/@notBefore),'-')[last()]
                            let $end := tokenize(d3xquery:formatDate($label/tei:date/@notAfter),'-')[last()]
                            let $diff := ((xs:double($end) - xs:double($start)) div 2) + xs:double($start)
                            return concat('01-01-',$diff)
                        }</date>
                        <displayType>circa</displayType>
                        <display>point</display>
                        <position>center</position>
                        <level json:literal="true">{$level}</level>
                        <id>{concat(replace(generate-id($label/tei:date/@notBefore),'\.',''),'c')}</id>
                    </nodes>,
                    <nodes>
                        <name>{$eventTitle}</name>
                        <recid>{$recID}</recid>
                        <label>{$eventlabel}</label>
                        <eventType>{$eventType}</eventType>
                        <date>{d3xquery:formatDate($label/tei:date/@notAfter)}</date>
                        <displayType>circa</displayType>
                        <display>none</display>
                        <position>end</position>
                        <level json:literal="true">{$level}</level>
                        <id>{replace(generate-id($label/tei:date/@notAfter),'\.','')}</id>
                    </nodes>
                    )
            else 'Possible error'
        else if($label/tei:date[@when]) then 
        (: 1. Point 
               Code: <date type=”point” when=”1234-05-06”>May 6, 1234</date>
               display: single date point
               #of points 1 :)
           <nodes>
                <name>{$eventTitle}</name>
                <recid>{$recID}</recid>
                <label>{$eventlabel}</label>
                <eventType>{$eventType}</eventType>
                <date>{d3xquery:formatDate($label/tei:date/@when)}</date>
                <displayType>point</displayType>
                <display>point</display>
                <position>start</position>
                <level json:literal="true">{$level}</level>
                <id>{replace(generate-id($label/tei:date/@when),'\.','')}</id>
            </nodes>
        else if($label/tei:date[@from] and $label/tei:date[@to]) then   
        (:2. Range
               Code: <date type=”range” from=”1095-01-01” to=”1103-12-13”>from 1095 to 1103</date>
               display: two half dots with solid line, arrow to right edge
               #of points 2:)
           (
            <nodes>
                <name>{$eventTitle}</name>
                <recid>{$recID}</recid>
                <label>{$eventlabel}</label>
                <eventType>{$eventType}</eventType>
                <date>{d3xquery:formatDate($label/tei:date/@from)}</date>
                <displayType>range</displayType>
                <display>start</display>
                <position>start</position>
                <level json:literal="true">{$level}</level>
                <id>{replace(generate-id($label/tei:date/@from),'\.','')}</id>
            </nodes>,
            <nodes>
                <name>{$eventTitle}</name>
                <recid>{$recID}</recid>
                <label>{$eventlabel}</label>
                <eventType>{$eventType}</eventType>
                <date>{d3xquery:formatDate($label/tei:date/@to)}</date>
                <displayType>range</displayType>
                <display>end</display>
                <position>end</position>                
                <level json:literal="true">{$level}</level>
                <id>{replace(generate-id($label/tei:date/@to),'\.','')}</id>
            </nodes>
            )
        else if($label/tei:date[@notBefore] and $label/tei:date[@notAfter]) then   
        (:3. between
           Code: <date type=”between” notBefore=”1095-01-01” notAfter=”1103-12-13”>between 1095 and 1103</date>
           display: two half dots with dotted line
           #of points 2?:)
        (
            <nodes>
                <name>{$eventTitle}</name>
                <recid>{$recID}</recid>
                <label>{$eventlabel}</label>
                <eventType>{$eventType}</eventType>
                <date>{d3xquery:formatDate($label/tei:date/@notBefore)}</date>
                <displayType>between</displayType>
                <display>start</display>
                <position>start</position>
                <level json:literal="true">{$level}</level>
                <id>{replace(generate-id($label/tei:date/@notBefore),'\.','')}</id>
            </nodes>,
            <nodes>
                <name>{$eventTitle}</name>
                <recid>{$recID}</recid>
                <label>{$eventlabel}</label>
                <eventType>{$eventType}</eventType>
                <date>{d3xquery:formatDate($label/tei:date/@notAfter)}</date>
                <displayType>between</displayType>
                <display>end</display>
                <position>end</position>
                <level json:literal="true">{$level}</level>
                <id>{replace(generate-id($label/tei:date/@notAfter),'\.','')}</id>
            </nodes>
            )
        else if($label/tei:date[@notBefore] and $label/tei:date[@to]) then     
        (:4. before
           Code: <date type=”before” notBefore=”1095-01-01” to=”1103-12-13”>before 1103</date>
           display: right half dot, dashed line to invisible 'start dot' arrow to right edge
           #of points 2?
        :)
        (
            <nodes>
                <name>{$eventTitle}</name>
                <recid>{$recID}</recid>
                <label>{$eventlabel}</label>
                <eventType>{$eventType}</eventType>
                <date>{d3xquery:formatDate($label/tei:date/@notBefore)}</date>
                <displayType>before</displayType>
                <display>none</display>
                <position>start</position>
                <level json:literal="true">{$level}</level>
                <id>{replace(generate-id($label/tei:date/@notBefore),'\.','')}</id>
            </nodes>,
            <nodes>
                <name>{$eventTitle}</name>
                <recid>{$recID}</recid>
                <label>{$eventlabel}</label>
                <eventType>{$eventType}</eventType>
                <date>{d3xquery:formatDate($label/tei:date/@to)}</date>
                <displayType>before</displayType>
                <display>end</display>
                <position>end</position>
                <level json:literal="true">{$level}</level>
                <id>{replace(generate-id($label/tei:date/@to),'\.','')}</id>
            </nodes>
            )
        else if($label/tei:date[@from] and $label/tei:date[@notAfter]) then     
        (:5. After
           Code: <date type=”after” from=”1095-01-01” notAfter=”1103-12-13”>after 1095</date>
           display: left half dot dashed line to invisible 'end dot' arrow to left edge?
           #of points 2?:)
           (
            <nodes>
                <name>{$eventTitle}</name>
                <recid>{$recID}</recid>
                <label>{$eventlabel}</label>
                <eventType>{$eventType}</eventType>
                <date>{d3xquery:formatDate($label/tei:date/@from)}</date>
                <displayType>after</displayType>
                <display>start</display>
                <position>start</position>
                <level json:literal="true">{$level}</level>
                <id>{replace(generate-id($label/tei:date/@from),'\.','')}</id>
            </nodes>,
            <nodes>
                <name>{$eventTitle}</name>
                <recid>{$recID}</recid>
                <label>{$eventlabel}</label>
                <eventType>{$eventType}</eventType>
                <date>{d3xquery:formatDate($label/tei:date/@notAfter)}</date>
                <displayType>after</displayType>
                <display>none</display>
                <position>end</position>
                <level json:literal="true">{$level}</level>
                <id>{replace(generate-id($label/tei:date/@notAfter),'\.','')}</id>
            </nodes>
            )
        else if($label/tei:date[@notAfter]) then 
            <nodes>
                <name>{$eventTitle}</name>
                <recid>{$recID}</recid>
                <label>{$eventlabel}</label>
                <eventType>{$eventType}</eventType>
                <date>{d3xquery:formatDate($label/tei:date/@notAfter)}</date>
                <displayType>notAfter</displayType>
                <display>end</display>
                <position>end</position>
                <level json:literal="true">{$level}</level>
                <id>{replace(generate-id($label/tei:date/@notAfter),'\.','')}</id>
            </nodes>
        else if($label/tei:date[@notBefore]) then 
            <nodes>
                <name>{$eventTitle}</name>
                <recid>{$recID}</recid>
                <label>{$eventlabel}</label>
                <eventType>{$eventType}</eventType>
                <date>{d3xquery:formatDate($label/tei:date/@notBefore)}</date>
                <displayType>notBefore</displayType>
                <display>start</display>
                <position>start</position>
                <level json:literal="true">{$level}</level>
                <id>{replace(generate-id($label/tei:date/@notBefore),'\.','')}</id>
            </nodes>
        else if($label/tei:date[@to]) then 
            <nodes>
                <name>{$eventTitle}</name>
                <recid>{$recID}</recid>
                <label>{$eventlabel}</label>
                <eventType>{$eventType}</eventType>
                <date>{d3xquery:formatDate($label/tei:date/@to)}</date>
                <displayType>to</displayType>
                <display>end</display>
                <position>end</position>
                <level json:literal="true">{$level}</level>
                <id>{replace(generate-id($label/tei:date/@to),'\.','')}</id>
            </nodes> 
        else if($label/tei:date[@from]) then 
            <nodes>
                <name>{$eventTitle}</name>
                <recid>{$recID}</recid>
                <label>{$eventlabel}</label>
                <eventType>{$eventType}</eventType>
                <date>{d3xquery:formatDate($label/tei:date/@from)}</date>
                <displayType>from</displayType>
                <display>start</display>
                <position>start</position>
                <level json:literal="true">{$level}</level>
                <id>{replace(generate-id($label/tei:date/@from),'\.','')}</id>
            </nodes>             
        else
            <nodes>
                <name>{$eventTitle}</name>
                <recid>{$recID}</recid>
                <label>{$eventlabel}</label>
                <eventType>{$eventType}</eventType>
                <date>{d3xquery:formatDate($label/tei:date)}</date>
                <displayType>point</displayType>
                <display>point</display>
                <position>start</position>
                <level json:literal="true">{$level}</level>
                <id>{replace(generate-id($label/tei:date),'\.','')}</id>
            </nodes>
};

(: Establish the URI for the following node used by links :)
declare function d3xquery:getFollowingID($label){
let $following := $label/following-sibling::*[1]
return 
    if($following/tei:date[@type = 'circa'] or contains($following/tei:date,'circa')) then
            if($following/tei:date[@notBefore] and $following/tei:date[@notAfter]) then   
               concat(replace(generate-id($following/tei:date/@notBefore),'\.',''),'c')
            else ()
    else if($following/tei:date[@notBefore] and $following/tei:date[@to]) then
            replace(generate-id($following/tei:date/@to),'\.','')
    else if($following/tei:date[@from] and $following/tei:date[@notAfter]) then
            replace(generate-id($following/tei:date/@from),'\.','')
    else if($following/tei:date[@when]) then replace(generate-id($following/tei:date/@when),'\.','')
    else if($following/tei:date[@from] and $following/tei:date[@to]) then replace(generate-id($following/tei:date/@from),'\.','')
    else if($following/tei:date[@notBefore] and $label/tei:date[@notAfter]) then replace(generate-id($following/tei:date/@notBefore),'\.','')
    else if($following/tei:date[@notBefore] and $label/tei:date[@to]) then replace(generate-id($following/tei:date/@notBefore),'\.','')
    else if($following/tei:date[@notAfter] and $label/tei:date[@from]) then replace(generate-id($following/tei:date/@from),'\.','')
    else if($following/tei:date[@from]) then replace(generate-id($following/tei:date/@from),'\.','')
    else if($following/tei:date[@to]) then replace(generate-id($following/tei:date/@to),'\.','')
    else if($following/tei:date[@notBefore]) then replace(generate-id($following/tei:date/@notBefore),'\.','')
    else if($following/tei:date[@notAfter]) then replace(generate-id($following/tei:date/@notAfter),'\.','')
    else ()     
};

declare function d3xquery:timelineLinks($events){
for $event at $level in $events/descendant::tei:sourceDesc[descendant::tei:date]
let $title := $event/descendant::tei:title[1]
let $eventTitle := normalize-space(string-join($title//text(),' '))
return 
    for $label in $event/descendant::tei:imprint
    let $eventlabel := $label/descendant::text()
    let $eventType := string($label/@type)
    let $id := concat((count($event/preceding-sibling::*) + 1), (count($label/preceding-sibling::*) + 1))
    return 
        if($label/tei:date[@type = 'circa'] or contains($label/tei:date,'circa')) then
            if($label/tei:date[@notBefore] and $label/tei:date[@notAfter]) then
                (
                <links>
                    <source>{replace(generate-id($label/tei:date/@notBefore),'\.','')}</source>
                    <target>{concat(replace(generate-id($label/tei:date/@notBefore),'\.',''),'c')}</target>
                    <eventType>{$eventType}</eventType>
                    <linkType>dashed</linkType>
                </links>,
                <links>
                    <source>{concat(replace(generate-id($label/tei:date/@notBefore),'\.',''),'c')}</source>
                    <target>{replace(generate-id($label/tei:date/@notAfter),'\.','')}</target>
                    <eventType>{$eventType}</eventType>
                    <linkType>dashed</linkType>
                </links>,
                if(d3xquery:getFollowingID($label) != '') then 
                <links>
                    <source>{concat(replace(generate-id($label/tei:date/@notBefore),'\.',''),'c')}</source>
                    <target>{d3xquery:getFollowingID($label)}</target>
                    <eventType>{$eventType}</eventType>
                    <linkType>solid</linkType> 
                </links>
                else ()
                )   
            else ()
        else if($label/tei:date[@when]) then 
            if(d3xquery:getFollowingID($label) != '') then 
                <links>
                    <source>{replace(generate-id($label/tei:date/@when),'\.','')}</source>
                    <target>{d3xquery:getFollowingID($label)}</target>
                    <eventType>{$eventType}</eventType>
                    <linkType>solid</linkType> 
                </links>
            else ()
        else if($label/tei:date[@from] and $label/tei:date[@to]) then 
            (
            <links>
                <source>{replace(generate-id($label/tei:date/@from),'\.','')}</source>
                <target>{replace(generate-id($label/tei:date/@to),'\.','')}</target>
                <eventType>{$eventType}</eventType>
                <linkType>solid</linkType>
            </links>,
            if(d3xquery:getFollowingID($label) != '') then 
            <links>
                <source>{replace(generate-id($label/tei:date/@to),'\.','')}</source>
                <target>{d3xquery:getFollowingID($label)}</target>
                <eventType>{$eventType}</eventType>
                <linkType>solid</linkType> 
            </links>
            else ()
            )
        else if($label/tei:date[@notBefore] and $label/tei:date[@notAfter]) then 
            (
                <links>
                <source>{replace(generate-id($label/tei:date/@notBefore),'\.','')}</source>
                <target>{replace(generate-id($label/tei:date/@notAfter),'\.','')}</target>
                <eventType>{$eventType}</eventType>
                <linkType>dashed</linkType>
            </links>,
            if(d3xquery:getFollowingID($label) != '') then 
            <links>
                <source>{replace(generate-id($label/tei:date/@notAfter),'\.','')}</source>
                <target>{d3xquery:getFollowingID($label)}</target>
                <eventType>{$eventType}</eventType>
                <linkType>solid</linkType> 
            </links>
            else ()
                )
        else if($label/tei:date[@notBefore] and $label/tei:date[@to]) then 
            (
            <links>
                <source>{replace(generate-id($label/tei:date/@notBefore),'\.','')}</source>
                <target>{replace(generate-id($label/tei:date/@to),'\.','')}</target>
                <eventType>{$eventType}</eventType>
                <linkType>dashed</linkType>
            </links>,
            if(d3xquery:getFollowingID($label) != '') then 
            <links>
                <source>{replace(generate-id($label/tei:date/@to),'\.','')}</source>
                <target>{d3xquery:getFollowingID($label)}</target>
                <eventType>{$eventType}</eventType>
                <linkType>solid</linkType> 
            </links>
            else ()
                )
        else if($label/tei:date[@notAfter] and $label/tei:date[@from]) then 
           (
                <links>
                <source>{replace(generate-id($label/tei:date/@notAfter),'\.','')}</source>
                <target>{replace(generate-id($label/tei:date/@from),'\.','')}</target>
                <eventType>{$eventType}</eventType>
                <linkType>dashed</linkType>
            </links>,
            if(d3xquery:getFollowingID($label) != '') then 
            <links>
                <source>{replace(generate-id($label/tei:date/@from),'\.','')}</source>
                <target>{d3xquery:getFollowingID($label)}</target>
                <eventType>{$eventType}</eventType>
                <linkType>solid</linkType> 
            </links>
            else ()
                )
        else if($label/tei:date[@notAfter]) then 
            if(d3xquery:getFollowingID($label) != '') then 
                <links>
                    <source>{replace(generate-id($label/tei:date/@notAfter),'\.','')}</source>
                    <target>{d3xquery:getFollowingID($label)}</target>
                    <eventType>{$eventType}</eventType>
                    <linkType>solid</linkType> 
                </links>
            else ()  
        else if($label/tei:date[@notBefore]) then 
            if(d3xquery:getFollowingID($label) != '') then 
                <links>
                    <source>{replace(generate-id($label/tei:date/@notBefore),'\.','')}</source>
                    <target>{d3xquery:getFollowingID($label)}</target>
                    <eventType>{$eventType}</eventType>
                    <linkType>solid</linkType> 
                </links>
            else ()  
        else if($label/tei:date[@to]) then 
            if(d3xquery:getFollowingID($label) != '') then 
                <links>
                    <source>{replace(generate-id($label/tei:date/@to),'\.','')}</source>
                    <target>{d3xquery:getFollowingID($label)}</target>
                    <eventType>{$eventType}</eventType>
                    <linkType>solid</linkType> 
                </links>
            else ()   
        else if($label/tei:date[@from]) then 
            if(d3xquery:getFollowingID($label) != '') then 
                <links>
                    <source>{replace(generate-id($label/tei:date/@from),'\.','')}</source>
                    <target>{d3xquery:getFollowingID($label)}</target>
                    <eventType>{$eventType}</eventType>
                    <linkType>solid</linkType> 
                </links>
            else ()              
        else 
            if(d3xquery:getFollowingID($label) != '') then 
                <links>
                    <source>{replace(generate-id($label/tei:date/@when),'\.','')}</source>
                    <target>{d3xquery:getFollowingID($label)}</target>
                    <eventType>{$eventType}</eventType>
                    <linkType>solid</linkType> 
                </links>
            else ()
};

declare function d3xquery:timeline($records as item()*){
    <root>{(d3xquery:timelineNodes($records), d3xquery:timelineLinks($records))}</root>
};
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
              let $series := normalize-space(string($w/ancestor-or-self::tei:TEI/descendant::tei:seriesStmt/tei:title[@level="s"]))
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
        else if($type = ('timeline','Timeline')) then
            d3xquery:timeline($records)
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

(:~
 : Build JSON data for d3js visualizations
 : @param $data record or records
 : @param $id record id for locus on single record
 : @param $relationship name of relationship to filter data on
 : @param $mode graph type: Force, Sankey, Table, Bubble
:)
declare function d3xquery:build-graph-type($data, $id as xs:string?, $relationship as xs:string?, $mode as xs:string?, $locus as xs:string?){
let $visData := 
   if($mode = ('timeline','Timeline')) then
            d3xquery:timeline($data)
    else d3xquery:format-table(d3xquery:get-relationship($data, $relationship, $id)) 
return 
        if(request:get-parameter('format', '') = ('json','JSON')) then
            (serialize($visData, 
                        <output:serialization-parameters>
                            <output:method>json</output:method>
                        </output:serialization-parameters>),
                        response:set-header("Content-Type", "application/json"))        
        else $visData   
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

declare function d3xquery:timeline-display($data as item()*, $json-file as xs:string?, $collection as xs:string?, $mode as xs:string?) {
    let $fileName := if($json-file != '') then
                        concat($config:nav-base,'/',$json-file)
                    else if($data) then ()
                    else concat($config:nav-base,'/modules/data.xql?getVis=true&amp;collection=',$collection,'&amp;mode=timeline')
    let $jsonData := 
                if($data != '') then 
                    let $formatedData := d3xquery:build-graph-type($data, (), (), 'Timeline')
                    let $json := 
                        (serialize($formatedData, 
                           <output:serialization-parameters>
                               <output:method>json</output:method>
                           </output:serialization-parameters>))
                    return  $json
                else '[]'            
    return 
           <div>
                <div id="eventVis">
                    <h2 class="text-center">Timeline</h2>
                    <div id="vis"/>
                    <script src="{$config:nav-base}/d3xquery/js/d3.v4.min.js" type="text/javascript"/>
                    <script src="{$config:nav-base}/d3xquery/js/d3-selection-multi.v1.js"/>
                    <script src="{$config:nav-base}/d3xquery/js/timelineVis.js"/>
                    <script type="text/javascript">
                     <![CDATA[
                     $(document).ready(function () {
                            var jsonData = ]]>{$jsonData}<![CDATA[;
                            var fileName = ']]>{$fileName}<![CDATA[';
                            var height = 600;
                            if(jsonData.length == 0) {
                                d3.json(fileName, function (error, graph) {
                                    if (error) throw error;
                                    make(graph, "800",height);
                                });
                                console.log('pass filename');
                            } else {
                                make(jsonData, "800",height);
                                console.log('pass data');
                            }
                      });
                      //
                     ]]>
                   </script>
                <link rel="stylesheet" type="text/css" href="{$config:nav-base}/d3xquery/css/vis.css"/>
            </div>    
        </div> 
};