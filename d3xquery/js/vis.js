//Saved while test tooltip issue
/* Global vars */
var chartDiv = document.getElementById("graphVis");
var color = d3.scaleOrdinal(d3.schemeCategory20c);
var width = 1020;
//var height = (isNaN(parseInt(chartDiv.clientHeight))) ? 300 : chartDiv.clientHeight;;

if (isNaN(parseInt(chartDiv.clientHeight))){
    var height = 800;
} else if(chartDiv.clientHeight > 50){
    var height = 800//chartDiv.clientHeight;
} else {
    var height = 800;
}


function responsivefy(svg) {
    // get container + svg aspect ratio
    var container = d3.select(svg.node().parentNode),
        width = parseInt(svg.style("width")), 
        height = parseInt(svg.style("height")),
        aspect = width / height;
    
    // add viewBox and preserveAspectRatio properties,
    // and call resize so that svg resizes on inital page load
    svg.attr("viewBox", "0 0 " + width + " " + height)
        .attr("perserveAspectRatio", "xMinYMid")
        .call(resize);

    // to register multiple listeners for same event type, 
    // you need to add namespace, i.e., 'click.foo'
    // necessary if you call invoke this function for multiple svgs
    // api docs: https://github.com/mbostock/d3/wiki/Selections#on
    d3.select(window).on("resize." + container.attr("id"), resize);

    // get width of container and resize svg to fit it
    function resize() {
        var targetWidth = (isNaN(parseInt(container.style("width")))) ? 960 : parseInt(container.style("width")); 
        svg.attr("width", targetWidth);
        svg.attr("height", Math.round(targetWidth / aspect));
    }
}

/* Select graph type */
function selectGraphType(data,rootURL,type) {
    if (type.toLowerCase() === "table") {
        console.log(type + ' cant do that one yet');
        //  htmltable()
    } else if (type.toLowerCase() === 'force') {
        //console.log(type + ' cant do that one yet');
        forcegraph(data,rootURL,type)
    } else if (type.toLowerCase() === 'sankey') {
        console.log(type + ' cant do that one yet');
        //  sankey()
    } else if (type.toLowerCase() === 'bubble') {
        //console.log(type + ' cant do that one yet');
        bubble(data,rootURL,type)
    } else if (type.toLowerCase() === 'raw xml') {
        console.log(type + ' cant do that one yet');
        //  rawXML()
    } else if (type.toLowerCase() === 'Raw json') {
        console.log(type + ' cant do that one yet');
        //  rawJSON()
    } else {
        console.log(type.toLowerCase() + ' cant do that one yet');
    }
};

/* Force Graph */
function forcegraph(graph,rootURL,type) {
    /* Set up svg */
    var linkedByIndex = {};
    var svg = d3.select("#graphVis").append("svg")
        .attr("width", width)
        .attr("height", height)
        .style("border", "1px solid grey")
        .call(responsivefy);
    
    var legend = d3.select("#graphVis")
            .append("div")
            .attr("class", "legend")
            .attr("id","legendContainer")
            .style("opacity", 1)
            .html("<h3>Filters</h3><h4>Relationships</h4><div id='relationFilter' class='filterList'></div><h4>Occupations</h4><div id='occupationFilter' class='filterList'></div>"); 
    
    var tooltip = d3.select("body").append("div")
        .attr("class", "d3jstooltip")
    	.style("position","absolute")
    	.style("opacity", 0);

    //var color = d3.scaleOrdinal(d3.schemeCategory20);
    var color = d3.scaleOrdinal(d3.schemeCategory20c),
        rel = d3.scaleOrdinal(d3.schemeCategory20c),
        occ = d3.scaleOrdinal(d3.schemeCategory20c),
        radius = 10;
    
    //Force simulation initialization
    var simulation = d3.forceSimulation()
             .force("link", d3.forceLink().id(function (d) {return d.id;}).distance(80).strength(0.75))
             .force("charge", d3.forceManyBody().strength(-10))
             .force("center", d3.forceCenter(width / 2, height / 3));
        
        
    //console.log(graph);
    
   var link = svg.append("g")
            .attr("class", "links")
            .selectAll("g")
            .data(graph.links).enter()
            .append('path')
            .attr('class', 'link')
            .attr('fill-opacity', 0)
            .attr('stroke-opacity', 1)
            .attr("stroke-width", "1")
            .style('fill', 'none')
            .attr("stroke", function (d) {
                return d3.rgb(rel(d.relationship));
            })
            .attr('id', function (d, i) {return 'link' + i})
            .style("pointer-events", "none");
            
    var node = svg.append("g")
            .attr("class", "nodes")
            .selectAll("g")
            .data(graph.nodes).enter()
            .append("g");
        
        var circles = node.append("circle")
            .attr("r",function(d) {
	       if(d.degree === 'primary'){
	           return radius * 3.5;    
            } else if(d.degree === 'first') {
                return radius * 2;
            } else {
                return radius;
        }}) 
        //.attr("class", "forceNode")
        .attr("class", function (d) {
            return d.type;
        })
        .style("fill", function (d) {
            //return d3.rgb(occ(d.type));
            if(d.type === 'Work'){
                return d3.rgb(occ(d.type));
            } else {
                return 'white';
            }}) 
            .style("stroke", function (d) {
                return d3.rgb(color(d.type)).darker();
            })
            .call(d3.drag().on("start", dragstarted).on("drag", dragged).on("end", dragended))
            .on("mouseover", function (d) {
                fade(d,.1);
                tooltip.style("visibility", "visible").html('<span class="nodelabel">' + d.label + '</span><br/>[' + d.type + ']').style("padding", "4px").style("opacity", .99).style("left", (d3.event.pageX) + "px").style("top", (d3.event.pageY - 28) + "px");
            }).on("mouseout", function (d) { 
                fade(d,1);
                tooltip.style("visibility", "hidden");
            }).on("mousemove", function () {
                return tooltip.style("top", (event.pageY -10) + "px").style("left",(event.pageX + 10) + "px");                     
            }).on('dblclick', function (d, i) { 
                window.location = d.link;
            });
        
        node.append("title").text(function (d) {
            return d.id;
        });
    
    simulation.nodes(graph.nodes).on("tick", ticked);
    
    simulation.force("link").links(graph.links);
    
    function ticked() {
            circles
      		.attr("cx", function(d) { return d.x = Math.max(radius, Math.min(width - radius, d.x)); })
      		.attr("cy", function(d) { return d.y = Math.max(radius, Math.min(height - radius, d.y)); });
      
      	/* curved lines */                   
              link.attr("d", function(d) {
                  var dx = d.target.x - d.source.x,
                      dy = d.target.y - d.source.y,
                      dr = Math.sqrt(dx * dx + dy * dy);
                      return "M" + d.source.x + "," + d.source.y + "A" + dr + "," + dr + " 0 0,1 " + d.target.x + "," + d.target.y;
                  });
        }
    
    //Link Connected
        graph.links.forEach(function (d) {
             linkedByIndex[d.source.index + "," + d.target.index] = 1;
        });
      
        //Connection for Highlight related
        function isConnected(a, b) {
            return linkedByIndex[a.index + "," + b.index] || linkedByIndex[b.index + "," + a.index] || a.index === b.index;
        }
        
        function fade(d,opacity) {
                node.style("stroke-opacity", function (o) {
                    thisOpacity = isConnected(d, o) ? 1: opacity;
                    this.setAttribute('fill-opacity', thisOpacity);
                    return thisOpacity;
                    return isConnected(d, o);
                });
                link.style("stroke-opacity", opacity).style("stroke-opacity", function (o) {
                    return o.source === d || o.target === d ? 1: opacity;
                });
        //end fade function
        }; 
        
        //Drag functions
        function dragstarted(d) {
            if (! d3.event.active) simulation.alphaTarget(0.3).restart();
            d.fx = d.x;
            d.fy = d.y;
        }
        
        function dragged(d) {
            d.fx = d3.event.x;
            d.fy = d3.event.y;
        }
        
        function dragended(d) {
            if (! d3.event.active) simulation.alphaTarget(0);
            d.fx = null;
            d.fy = null;
        }
        
};

//Force Graph functions
function bubble(graph,rootURL,type) {
    console.log('root url: ' + rootURL)
    /* Set up svg */
    var svg = d3.select("#graphVis").append("svg")
        .attr("width", width)
        .attr("height", height)
        .style("border", "1px solid grey")
        .call(responsivefy);
    
   var tooltip = d3.select("body").append("div")
        .attr("class", "d3jstooltip")
    	.style("position","absolute")
    	.style("opacity", 0);
    
    //Data
    data = graph.data.children;
    
    var minRadius = d3.min(data, function(d){return d.size})
    var maxRadius = d3.max(data, function(d){return d.size})
    var radiusScale = d3.scaleSqrt()
            .domain([minRadius, maxRadius])
            .range([10,80]); 
    
    var n = data.length, // total number of circles
        m = 10; // number of distinct clusters

    
    //color based on cluster
    var c = d3.scaleOrdinal(d3.schemeCategory10).domain(d3.range(m));
    
    // The largest node for each cluster.
    var clusters = new Array(m);
    
    var nodes = data.map(function (d) {
        var i = d.group,
        l = d.name,
        s = d.size,
        id = d.id,
        r = radiusScale(d.size),
        d = {
            cluster: i, radius: r, name: l, size: s, id: id
        };
        if (! clusters[i] || (r > clusters[i].radius)) clusters[i] = d;
        return d;
    });
    
    var forceCollide = d3.forceCollide()
        .radius(function (d) {
            return d.radius + 2.5;
        }).iterations(1);
        
    var force = d3.forceSimulation()
        .nodes(nodes)
        .force("center", d3.forceCenter())
        .force("collide", forceCollide)
        .force("cluster", forceCluster)
        .force("gravity", d3.forceManyBody(30))
        .force("x", d3.forceX().strength(.5))
        .force("y", d3.forceY().strength(.5))
        .on("tick", tick);
    
    var g = svg.append('g').attr('transform', 'translate(' + width / 2 + ',' + height / 2 + ')');
    
    var circle = g.selectAll("circle")
        .data(nodes).enter()
        .append("circle")
        .attr("r", function (d) {
            return d.radius;
        }).style("fill", function (d) {
            return color(d.cluster);
        }).attr("stroke", function (d) {
            return d3.rgb(color(d.cluster)).darker();
        }).on("mouseover", function (d) {
            d3.select(this).style("opacity", .5);
            return tooltip.style("visibility", "visible")
                    .text(d.name + ' [' + d.size + ' works]')
                    .style("opacity", 1)
                    .style("left", (d3.event.pageX) + "px")
                    .style("top", (d3.event.pageY + 10) + "px");
        }).on("mouseout", function (d) {
            d3.select(this).style("opacity", 1);
            return tooltip.style("visibility", "hidden");
        }).on("mousemove", function () {
            return tooltip.style("top", (event.pageY -10) + "px").style("left",(event.pageX + 10) + "px");
        }).on('dblclick', function (d, i) {
            var searchString = ";fq-Taxonomy:" + d.id;
            var url = rootURL + "/search.html?fq=" + encodeURIComponent(searchString);
            window.location = url;
            //console.log('URL: ' + url);
        });
    
    function tick() {
        circle.attr("cx", function (d) {
            return d.x;
        }).attr("cy", function (d) {
            return d.y;
        });
    }
    
    function forceCluster(alpha) {
        for (var i = 0, n = nodes.length, node, cluster, k = alpha * 1; i < n;++ i) {
            node = nodes[i];
            cluster = clusters[node.cluster];
            node.vx -= (node.x - cluster.x) * k;
            node.vy -= (node.y - cluster.y) * k;
        }
    }
};