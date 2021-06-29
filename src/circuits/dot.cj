/**
 * dot.cj
 *
 * This file contains functions to generate dot graphs from hypergraphs
 */

package circuits

import io.*
import debug.*
import settings.*

/**
 * Indent a string by a given number of tabs
 * @param n   the number of tabs to indent by
 * @param str the string to indent
 * @return the indented string
 */
func indent(n : Int64, str : String){
    var out = ""
    for (i in 0..n) {
        out = "${out}${tab}"
    }
    "${out}${str}"
}
/**
 * Convert a number into unicode subscripts
 * @param n the number
 * @return the corresponding unicode subscript characters
 */
func subscript(n : Int64){
    let code = "${n}"
    var sub = ""
    for(i in 0..code.size()){
        let charc = ord(code[i])
        let subs = chr(charc + 0x2050)
        sub = "${sub}${subs}"
    }
    sub
}

let tableStyle = "border=\"0\" cellborder=\"1\" cellspacing=\"0\""
let graphOpts = "rankdir=LR"
let edgeNodeOpts = "shape=plaintext fillcolor=white fixedsize=false"
let vertexNodeOpts = "shape=circle style=filled fillcolor=black height=0.15 fixedsize=true"

let portHeight = 10
let portWidth = 10

let interfaceStyle = "bgcolor=\"gray\""
let identityStyle = "bgcolor=\"gray\""
let linkStyle = "bgcolor=\"red\""
let gateStyle = "bgcolor=\"cyan\""
let structuralStyle = "bgcolor=\"violet\" width=\"10\""
let delayStyle = "bgcolor=\"yellow\""
let valueStyle = "bgcolor=\"green\""
let blackboxStyle = "bgcolor=\"white\""

let vertexCommentString = "Vertices"
let edgeCommentString = "Edges"
let connsCommentString = "Connections"

let maxSubgraphOptions = "rank=max"
let minSubgraphOptions = "rank=min"

let declaration = "graph G {"
let graphOptions = indent(1, graphOpts)
let vertexNodeOptions = indent(1, "node[${vertexNodeOpts}]")
let edgeNodeOptions = indent(1, "node[${edgeNodeOpts}]")
let vertexComment = indent(1, "// ${vertexCommentString}")
let edgeComment = indent(1, "// ${edgeCommentString}")
let connsComment = indent(1, "// ${connsCommentString}")

// TODO should be doable with a single ArrayList<Vertex> method
/**
 * Generate the dot html code for a target list
 * @param vs The list of targets
 * @param id The id of the corresponding edge
 * @param n the number of tabs to indent
 * @return The dot html code for this target list
 */
func TargetListToTable(vs : ArrayList<Target>, id : String, n : Int64){
    let header = indent(n,"<table>")
    var rows = ""
    for (i in 0..vs.size()) {
        let row = indent(n+1, "<tr><td height=\"${portHeight}\" width=\"${portWidth}\" port = \"${id}${i}\"></td></tr>")
        rows = if (rows == "") { "${row}" } else { "${rows}\n${row}" }
    }
    let footer = indent(n,"</table>")
    "${header}\n${rows}\n${footer}"
}
/**
 * Generate the dot html code for a source list
 * @param vs The list of sources
 * @param id The id of the corresponding edge
 * @param n the number of tabs to indent
 * @return The dot html code for this target list
 */
func SourceListToTable(vs : ArrayList<Source>, id : String, n : Int64){
    let header = indent(n,"<table>")
    var rows = ""
    for (i in 0..vs.size()) {
        let row = indent(n+1, "<tr><td height=\"${portHeight}\" width=\"${portWidth}\" port = \"${id}${i}\"></td></tr>")
        rows = if (rows == "") { "${row}" } else { "${rows}\n${row}" }
    }
    let footer = indent(n,"</table>")
    "${header}\n${rows}\n${footer}"
}
/**
 * Wrap a string in a given tag
 * @param elem the tag to wrap in
 * @param str the string to wrap
 * @param n The number of tabs to indent
 * @return the td-wrapped string
 */
func WrapIn(elem : String, str : String, n : Int64) {
    let op = indent(n, "<${elem}>")
    let cl = indent(n, "</${elem}>")
    "${op}\n${str}\n${cl}"
}
/**
 * Wrap a string in tr tags
 * @param str the string to wrap
 * @param n The number of tabs to indent
 * @return the tr-wrapped string
 */
func WrapInTr(str : String, n : Int64) {
    WrapIn("tr", str, n)
}
/**
 * Wrap a string in td tags
 * @param str the string to wrap
 * @param n The number of tabs to indent
 * @return the td-wrapped string
 */
func WrapInTd(str : String, n : Int64) {
    WrapIn("td", str, n)
}
/**
 * Generate the dot code for a graphviz edge node
 * @param n The number of tabs to indent
 * @param id The id of the node
 * @param nodeStyle the style of this node
 * @param text the text on this node
 * @param sources the list of sources of this node
 * @param targets the list of targets of this node
 * @return The dot code for this edge
 */
func DrawEdgeNode(n : Int64, id : String, nodeStyle : String, text : String, sources : ArrayList<Source>, targets : ArrayList<Target>){
    let declaration = indent(n, "${id} [label=<")
    let tableheader = indent(n+1,"<table ${nodeStyle} ${tableStyle}>")
    let sourceTable = if(sources.size() == 0) { "" } else { WrapInTd(SourceListToTable(sources, "s", 5), n+3) }
    let targetTable = if(targets.size() == 0) { "" } else { WrapInTd(TargetListToTable(targets, "t", 5), n+3) }
    let sourceNewline = if(sourceTable == "") { "" } else { "\n" }
    let targetNewline = if(targetTable == "") { "" } else { "\n" }
    let edgetext = WrapInTd(indent(n+4, if(DebugDotOn()) { "${id}: ${text}" } else { text }), n+3)
    let subtable = WrapInTr("${sourceTable}${sourceNewline}${edgetext}${targetNewline}${targetTable}", n+2)
    let tablefooter = indent(n+1, "</table>")
    let conclusion = indent(n,">];")
    "${declaration}\n${tableheader}\n${subtable}\n${tablefooter}\n${conclusion}"
}
/**
 * Generate the dot code for an edge
 * @param n The number of tabs to indent
 * @param e The edge
 * @return The dot code for this edge
 */
func DrawEdge(n : Int64, e : Edge){
    let style = match(e.generator){
        case VALUE(value)       => valueStyle
        case STRUCTURAL(struct) => structuralStyle
        case GATE(label)        => gateStyle
        case BLACKBOX(label)    => blackboxStyle
        case DELAY(dur)         => delayStyle
        case $IDENTITY          => identityStyle
        case INLINK(spec)       => linkStyle
        case OUTLINK(spec)      => linkStyle
    }
    let text = match(e.generator){
        case VALUE(value)       => "${value}"
        case STRUCTURAL(struct) => "${struct}"
        case GATE(label)        => label.name
        case BLACKBOX(label)    => label.name
        case DELAY(dur)         => "d[${dur}]"
        case $IDENTITY          => "id"
        case INLINK(spec)       => spec.name
        case OUTLINK(spec)      => spec.name
    }
    DrawEdgeNode(n, "e${e.id}", style, text, e.sources, e.targets)
}
/**
 * Generate the dot code for a target-source vertex pair
 * @param t the target in the pair
 * @param s the source in the pair
 * @return The dot code for this vertex pair
 */
func DrawVertex(t : Target, s : Source) {
    var wires = ""
    for(wire in s.wires){

        let wiretext = match(wire.bus.name){
            case Some(name) => "${name}[${wire.i}]"
            case $None      => if(DebugDotOn()) { "${wire.bus.id}[${wire.i}]" } else { "" }
        }
        wires = if(wires == "") { "${wiretext}" } else if(wiretext == "") { "${wires}" } else { "${wires}, ${wiretext}" }
    }
    let text = if(DebugDotOn()) { "${t.id}|${s.id}\n${wires}" } else { wires }
    "v${t.id}[label=\"\" xlabel=\"${text}\"]"
}
/**
 * Generate the dot code for a subgraph 
 * @param n    The number of tabs to indent
 * @param opt  The options for this subgraph
 * @param text The text to put in the subgraph
 * @return The dot code for this subgraph
 */
func DrawSubgraph(n : Int64, opt : String, text : String){
    let opener = indent(n, "{")
    let closer = indent(n, "}")
    "${opener} ${opt}\n${text}\n${closer}"
}
/**
 * Translate a hypergraph into a dot graph
 * TODO this seems very slow, is there a way to improve performance?
 * @param f        The hypergraph to translate
 * @param resolve  Whether or not to resolve the links in this hypergraph
 * @return The dot code for this graph
 */
external func DotGraph(f : Hypergraph, resolve : Bool){
    Debug("DotGraph", "Generating dot graph for '${f.GetName()}'")
    // If desired, resolve the links in the graph first
    let f = if(resolve){
        let f = ResolveLinks(f)
        f.ToGraph()
    } else {
        f
    }
    var vertices = ""
    var conns = ""
    for (t in f.GetTargets()) {
        let s = t.GetConn()
        let vertex = indent(1, DrawVertex(t, s))
        vertices = if(vertices == "") { vertex } else { "${vertices}\n${vertex}" }

        let left = match(t.GetPort()){
            case EdgePort(e,n)     => "e${e.id}:t${n}"
            case InterfacePort(n)  => "ei:t${n}"
        }
        let right = match(s.GetPort()){
            case EdgePort(e,n)     => "e${e.id}:s${n}"
            case InterfacePort(n)  => "eo:s${n}"
        }

        let connl = indent(1, "${left}:e -- v${t.id}:w")
        let connr = indent(1, "v${t.id}:e -- ${right}:w")
        let conn = "${connl}\n${connr}"
        conns = if(conns == "") { conn } else { "${conns}\n${conn}" }
    }

    let input = DrawEdgeNode(2, "ei", interfaceStyle, "inputs", ArrayList<Source>(), f.GetInputs())
    let inputgraph = DrawSubgraph(1, minSubgraphOptions, input)
    var edges = inputgraph
    for (e in f.GetEdges()){
        let edgetext = DrawEdge(1, e)
        edges = "${edges}\n${edgetext}"
    }
    let output = DrawEdgeNode(1, "eo", interfaceStyle, "outputs", f.GetOutputs(), ArrayList<Target>())
    let outputgraph = DrawSubgraph(1, maxSubgraphOptions, output)
    edges = "${edges}\n${outputgraph}"

    "${declaration}\n${graphOptions}\n\n${vertexComment}\n${vertexNodeOptions}\n${vertices}\n\n${edgeComment}\n${edgeNodeOptions}\n${edges}\n\n${connsComment}\n${conns}\n}"
}
/**
 * Write the corresponding dot graph for a hypergraph to a file
 * The file is placed in the directory specified in settings.cj and given a .dot extension
 * @param f       The hypergraph to draw
 * @param file    The filename of the output
 * @param resolve Whether or not to resolve links
 */
external func WriteDotToFile(f : Hypergraph, file : String, resolve!: Bool = false){
    let filename = GetDotFile(file)
    Info("WriteDotToFile", "Writing dot file ${filename}")
    let dot = DotGraph(f, resolve)
    let fs = FileStream(filename, OpenMode.ForceCreate)
    if(fs.openFile()){
        let ds = DataStream(fs)
        ds.writeString(dot)
        ds.flush()
        ds.close()
    } else {
        fs.close()
        throw CouldNotOpenFileException("WriteDotToFile", filename)
    }
    fs.close()
}