package hypergraphs
import core.*

func indent(n : Int64, str : String){
    var out = ""
    let tab = "  "
    for (i in 0..n) {
        out = "${out}${tab}"
    }
    "${out}${str}"
}

let tableStyle = "border=\"0\" cellborder=\"1\" cellspacing=\"0\""
let graphOptions = "rankdir=LR"
let edgeNodeOptions = "shape=plaintext fillcolor=white fixedsize=false"
let vertexNodeOptions = "shape=circle style=filled fillcolor=black height=0.25 fixedsize=true"
let portHeight = 10
let portWidth = 10
let vertexComment = "Vertices"
let edgeComment = "Edges"
let connsComment = "Connections"

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

func DrawEdgeNode(id : String, text : String, sources : ArrayList<Source>, targets : ArrayList<Target>){
    let declaration = indent(1, "${id} [label=<")
    let tableheader = indent(2,"<table ${tableStyle}>")
    let sourceTable = sources.size() == 0 ? "" : WrapInTd(SourceListToTable(sources, "s", 5), 4)
    let targetTable = targets.size() == 0 ? "" : WrapInTd(TargetListToTable(targets, "t", 5), 4)
    let sourceNewline = sourceTable == "" ? "" : "\n"
    let targetNewline = targetTable == "" ? "" : "\n"
    let edgetext = WrapInTd(text, 4)
    let subtable = WrapInTr("${sourceTable}${sourceNewline}${edgetext}${targetNewline}${targetTable}", 3)
    let tablefooter = indent(2, "</table>")
    let conclusion = indent(1,">];")
    "${declaration}\n${tableheader}\n${subtable}\n${tablefooter}\n${conclusion}"
}

func DrawEdge(e : Edge){
    let edgedetails = match(e.kind){
        case .REGULAR(label)   => indent(5, label.name)
        case .IDENTITY         => indent(5, "id")
        case .LINK(spec, kind) => indent(5, spec.name)
    }
    DrawEdgeNode("e${e.id}", edgedetails, e.sources, e.targets)
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
    "v${t.id}[label=\"\" xlabel=\"${s.name}\"]"
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

        let connl = indent(1, "${left} -- v${t.id}:w")
        let connr = indent(1, "v${t.id}:e -- ${right}")
        let conn = "${connl}\n${connr}"
        conns = conns == "" ? conn : "${conns}\n${conn}" 
    }

    let inputtext = DrawEdgeNode("ei", indent(5,"inputs"), ArrayList<Source>(), f.GetInputs())
    var edges = inputtext
    for (e in f.GetEdges()){
        let edgetext = DrawEdge(e)
        edges = "${edges}\n${edgetext}"
    }
    let outputtext = DrawEdgeNode("eo", indent(5,"outputs"), f.GetOutputs(), ArrayList<Target>())
    edges = "${edges}\n${outputtext}"

    let dot = "${declaration}\n${graphOptions}\n\n${vertexComment}\n${vertexNodeOptions}\n${vertices}\n\n${edgeComment}\n${edgeNodeOptions}\n\n${edges}\n\n${connsComment}\n${conns}\n}"
    print(dot)
}