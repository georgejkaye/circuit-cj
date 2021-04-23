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
let graphOptions = indent(1, "rankdir=LR")
let edgeNodeOptions = indent(1, "node[shape=plaintext]")
let vertexNodeOptions = indent(1, "node[shape=circle]")

// TODO should be doable with a single ArrayList<Vertex> method
func TargetListToTable(vs : ArrayList<Target>, id : String, n : Int64){
    let header = indent(n,"<table>")
    var rows = ""
    for (i in 0..vs.size()) {
        let row = indent(n+1, "<tr><td port = \"${id}${i}\"></td></tr>")
        rows = rows == "" ? "${row}" : "${rows}\n${row}"
    }
    let footer = indent(n,"</table>")
    "${header}\n${rows}\n${footer}"
}
func SourceListToTable(vs : ArrayList<Source>, id : String, n : Int64){
    let header = indent(n,"<table>")
    var rows = ""
    for (i in 0..vs.size()) {
        let row = indent(n+1, "<tr><td port = \"${id}${i}\"></td></tr>")
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
    "v${t.id}[label=\"${s.name}\"]"
}

func DotGraph(f : Hypergraph){
    let declaration = "graph G {"

    var vertices = ""
    for (t in f.GetTargets()) {
        let vertex = indent(1, DrawVertex(t, f.GetConn(t)))
        vertices = vertices == "" ? vertex : "${vertices}\n${vertex}"
    }

    let inputtext = DrawEdgeNode("ei", indent(5,"inputs"), ArrayList<Source>(), f.GetInputs())
    var edges = inputtext

    var conns = ""
    for(e in f.GetEdges()){
        let edgetext = DrawEdge(e)
        edges = "${edges}\n${edgetext}"
    }
    let outputtext = DrawEdgeNode("eo", indent(5,"outputs"), f.GetOutputs(), ArrayList<Target>())
    edges = "${edges}\n${outputtext}"

    let dot = "${declaration}\n${graphOptions}\n${vertexNodeOptions}\n\n${vertices}\n\n${edgeNodeOptions}\n\n${edges}\n}"
    print(dot)
}