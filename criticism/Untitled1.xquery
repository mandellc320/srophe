
for $event at $level in $events/descendant::tei:sourceDesc[descendant::tei:imprint]
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
                <date>{d3xquery:formatDate($label/tei:date/@when)}</date>
                <displayType>point</displayType>
                <display>point</display>
                <position>start</position>
                <level json:literal="true">{$level}</level>
                <id>{replace(generate-id($label/tei:date/@when),'\.','')}</id>
            </nodes>