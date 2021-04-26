package hypergraphs
import core.*

let tab = "  "

func indent(n : Int64, str : String){
    var out = ""
    for (i in 0..n) {
        out = "${out}${tab}"
    }
    "${out}${str}"
}

func subscript(n : Int64){
    let code = "${n}"
    var sub = ""
    for(i in 0..code.length()){
        let charc = ord(code.charAt(i))
        let subs = chr(charc + 0x2050)
        sub = "${sub}${subs}"
    }
    sub
}

let tableStyle = "border=\"0\" cellborder=\"1\" cellspacing=\"0\""
let graphOptions = "rankdir=LR"
let edgeNodeOptions = "shape=plaintext fillcolor=white fixedsize=false"
let vertexNodeOptions = "shape=circle style=filled fillcolor=black height=0.15 fixedsize=true"

let portHeight = 10
let portWidth = 10

let interfaceStyle = "bgcolor=\"gray\""
let identityStyle = "bgcolor=\"gray\""
let linkStyle = "bgcolor=\"red\""
let gateStyle = "bgcolor=\"cyan\""
let structuralStyle = "bgcolor=\"violet\""
let delayStyle = "bgcolor=\"yellow\""
let valueStyle = "bgcolor=\"green\""

let vertexComment = "Vertices"
let edgeComment = "Edges"
let connsComment = "Connections"

let maxSubgraphOptions = "rank=max"
let minSubgraphOptions = "rank=min"

// TODO should be doable with a single ArrayList<Vertex> method
func TargetListToTable(vs : ArrayList<Target>, id : String, n : Int64){
    let header = indent(n,"<table>")
    var rows = ""
    for (i in 0..vs.size()) {
        let row = indent(n+1, "<tr><td height=\"${portHeight}\" width=\"${portWidth}\" port = \"${id}${i}\"></td></tr>")
        rows = rows == "" ? "${row}" : "${rows}\n${row}"
    }
    let footer = indent(n,"</table>")
    "${header}\n${rows}\n${footer}"
}
func SourceListToTable(vs : ArrayList<Source>, id : String, n : Int64){
    let header = indent(n,"<table>")
    var rows = ""
    for (i in 0..vs.size()) {
        let row = indent(n+1, "<tr><td height=\"${portHeight}\" width=\"${portWidth}\" port = \"${id}${i}\"></td></tr>")
        rows = rows == "" ? "${row}" : "${rows}\n${row}"
    }
    let footer = indent(n,"</table>")
    "${header}\n${rows}\n${footer}"
}

func WrapIn(elem : String, str : String, n : Int64) {
    let op = indent(n, "<${elem}>")
    let cl = indent(n, "</${elem}>")
    "${op}\n${str}\n${cl}"
}

func WrapInTr(str : String, n : Int64) {
    WrapIn("tr", str, n)
}

func WrapInTd(str : String, n : Int64) {
    WrapIn("td", str, n)
}

func DrawEdgeNode(n : Int64, id : String, nodeStyle : String, text : String, sources : ArrayList<Source>, targets : ArrayList<Target>){
    let declaration = indent(n, "${id} [label=<")
    let tableheader = indent(n+1,"<table ${nodeStyle} ${tableStyle}>")
    let sourceTable = sources.size() == 0 ? "" : WrapInTd(SourceListToTable(sources, "s", 5), n+3)
    let targetTable = targets.size() == 0 ? "" : WrapInTd(TargetListToTable(targets, "t", 5), n+3)
    let sourceNewline = sourceTable == "" ? "" : "\n"
    let targetNewline = targetTable == "" ? "" : "\n"
    let edgetext = WrapInTd(indent(n+4, text), n+3)
    let subtable = WrapInTr("${sourceTable}${sourceNewline}${edgetext}${targetNewline}${targetTable}", n+2)
    let tablefooter = indent(n+1, "</table>")
    let conclusion = indent(n,">];")
    "${declaration}\n${tableheader}\n${subtable}\n${tablefooter}\n${conclusion}"
}

func DrawEdge(n : Int64, e : Edge){
    let (style, text) = match(e.generator){
        case .VALUE(value)      => (valueStyle, "${value}")
        case .STRUCTURAL(label) => (structuralStyle, label.name)
        case .GATE(label)       => (gateStyle, label.name)
        case .DELAY(dur)        => (delayStyle, "𝛿${subscript(dur)}")
        case .IDENTITY          => (identityStyle, "id")
        case .INLINK(spec)      => (linkStyle, spec.name)
        case .OUTLINK(spec)     => (linkStyle, spec.name)
    }
    DrawEdgeNode(n, "e${e.id}", style, text, e.sources, e.targets)
}

func DrawTargetVertices(vs : ArrayList<Target>){
    var vertices = ""
    for (v in vs){
        let vertex = indent(1, "v${v.id}")
        vertices = vertices == "" ? vertex : "${vertices}\n${vertex}"
    }
    vertices
}

func DrawVertex(t : Target, s : Source) {
    var names = ""
    for(name in s.names){
        names = names == "" ? name : "${names}, ${name}"
    }
    "v${t.id}[label=\"\" xlabel=\"${names}\"]"
}

func DrawSubgraph(n : Int64, opt : String, text : String){
    let opener = indent(n, "{")
    let closer = indent(n, "}")
    "${opener} ${opt}\n${text}\n${closer}"
}

func DotGraph(f : Hypergraph){
    let declaration = "graph G {"
    let graphOptions = indent(1, graphOptions)
    let vertexNodeOptions = indent(1, "node[${vertexNodeOptions}]")
    let edgeNodeOptions = indent(1, "node[${edgeNodeOptions}]")
    let vertexComment = indent(1, "// ${vertexComment}")
    let edgeComment = indent(1, "// ${edgeComment}")
    let connsComment = indent(1, "// ${connsComment}")

    var vertices = ""
    var conns = ""
    for (t in f.GetTargets()) {
        let s = f.GetConn(t)
        let vertex = indent(1, DrawVertex(t, s))
        vertices = vertices == "" ? vertex : "${vertices}\n${vertex}"

        let left = match(f.GetEdge(t)){
            case .EdgePort(e,n)     => "e${e.id}:t${n}"
            case .InterfacePort(n)  => "ei:t${n}"
        }
        let right = match(f.GetEdge(s)){
            case .EdgePort(e,n)     => "e${e.id}:s${n}"
            case .InterfacePort(n)  => "eo:s${n}"
        }

        let connl = indent(1, "${left}:e -- v${t.id}:w")
        let connr = indent(1, "v${t.id}:e -- ${right}:w")
        let conn = "${connl}\n${connr}"
        conns = conns == "" ? conn : "${conns}\n${conn}" 
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

external func TestDot(){
    let f = AndGate(output: "out")
    print(DotGraph(f))
}