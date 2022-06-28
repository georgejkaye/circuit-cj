package graphs

import debug.*
import settings.*
import prelude.*

from std import io.*

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

let tableStyle = [
    ("border", "0"),
    ("cellborder", "1"),
    ("cellspacing", "0")
]
let graphOpts = [
    ("rankdir", "LR"),
    ("bgcolor", if(IsDebugDot()) { "gray" } else { "white" })
]
let edgeNodeOpts = [
    ("shape", "plaintext"),
    ("fillcolor", "white"),
    ("fixedsize", "false"),
    ("fontcolor", "black")
]
let vertexNodeOpts = [
    ("shape", "circle"),
    ("style", "filled"),
    ("fillcolor", "black"),
    ("height", "0.25"),
    ("fixedsize", "true"),
    ("fontcolor", "white")
]
let portHeight = 5
let portWidth = 5
func bgColour(colour : String) : (String, String) {
    ("bgcolor", colour)
}
let interfaceStyle = [
    bgColour("gray")
]
let compressorStyle = [
    bgColour("red")
]
let primitiveStyle = [
    bgColour("cyan")
]
let compositeStyle = [
    bgColour("darkturquoise")
]
let structuralStyle = [
    bgColour("violet"),
    ("width", "10")
]
let delayStyle = [
    bgColour("yellow")
]
let valueStyle = [
    bgColour("green")
]
let blackboxStyle = [
    bgColour("white")
]
let maxSubgraphOpts = [
    ("rank", "max")
]
let minSubgraphOpts = [
    ("rank", "min")
]
/**
 * Enum to give indentation hints for the generated dot code.
 */
public enum IndentInstruction {
    | Preserve      // Keep the current indentation
    | Indent        // Indent one more starting from the next line
    | Deindent      // Indent one fewer starting from this line
}

func CreateElemOptionsString(options : Array<(String, String)>) : String {
    fold_left(
        { acc : String , cur: (String, String) => 
            let (key, value) = cur
            let keyval = "${key}=\"${value}\""
            if (acc == "") {
                keyval
            } else {
                "${acc} ${keyval}"
            }
        },
        "",
        options
    )    
}

/**
 * Create an HTML element and add it to a list of graph content
 * 
 * @param tag           The name of this HTML element
 * @param options       The list of pairs of options to give this element
 * @param elemContent   The list of lines to include within this element
 * @param inline        Whether or not to force this element to occupy one line
 * @param graphContent  The list to add the element lines to
 */
func MakeElem(
    tag : String, 
    options : Array<(String, String)>, 
    elemContent: ArrayList<(String, IndentInstruction)>, 
    inline: Bool, 
    graphContent : ArrayList<(String, IndentInstruction)>
) : Unit {
    let elem = ArrayList<(String, IndentInstruction)>()
    let optionString = CreateElemOptionsString(options)
    let opener = ("<${tag} ${optionString}>", Indent)
    let closer = ("</${tag}>", Deindent)
    elem.append(opener)
    elem.appendAll(elemContent)
    elem.append(closer)

    let finalElem = if (inline) {
        ArrayList<(String, IndentInstruction)>([(
            fold_left (
            { acc : String, cur : (String, IndentInstruction) => "${acc}${cur[0]}"},
            "",
            elem
        ), Preserve)])
    } else {
        elem
    }
    graphContent.addAll(finalElem)
}

func EdgeVerticesToTable(vs : Array<Vertex>, id : String, graphContent : ArrayList<(String, IndentInstruction)>) : Unit {
    let content = ArrayList<(String, IndentInstruction)>()
    for (i in 0..vs.size()) {
        let td = ArrayList<(String, IndentInstruction)>()
        MakeElem("td", [
            ("height", "${portHeight}"),
            ("width", "${portWidth}"),
            ("port", "${id}${i}")
        ], ArrayList<(String, IndentInstruction)>(), true, td)
        MakeElem("tr", [], td, true, content)
    }
    MakeElem("table", [], content, false, graphContent)
}



func DrawEdgeNode(e : Edge, content : ArrayList<(String, IndentInstruction)>) : Unit {
    let (style, label) = match(e.GetLabel()){
        case VALUE(values, signed)  => (valueStyle      , PrintValue(values, signed, GetDotNumberRepresentation()))
        case BUNDLER(ms,ns)         => (compressorStyle , if (ms.size() < ns.size()) { "◁" } else { "▷" })
        case JOIN(width)            => (structuralStyle , "∇") 
        case PRIMITIVE(spec)        => (primitiveStyle  , spec.GetName())
        case COMPOSITE(spec)        => (compositeStyle  , spec.GetName())
        case BLACKBOX(spec)         => (blackboxStyle   , spec.GetName())
        case DELAY(dur, width)      => (delayStyle      , "${dur}")
    }
    DrawEdgelikeNode("e${e.GetId()}", label, style, e.GetSources(), e.GetTargets(), content)
}

func DrawEdgelikeNode(
    id : String, 
    label : String, 
    style : Array<(String, String)>,
    sources : Array<Vertex>,
    targets : Array<Vertex>,
    content : ArrayList<(String, IndentInstruction)>
) : Unit {
    func DrawPorts(
        array : Array<Vertex>, 
        id : String, 
        edgeContent : ArrayList<(String, IndentInstruction)>
    ) : Unit {
        if (array.size() != 0) {
            let table = ArrayList<(String, IndentInstruction)>()
            EdgeVerticesToTable(array, id, table)
            MakeElem("td", [], table, false, edgeContent)
        }
    }

    let edgeContent = ArrayList<(String, IndentInstruction)>()
    DrawPorts(sources, "w", edgeContent)
    MakeElem("td", [], ArrayList<(String, IndentInstruction)>([
        (if(IsDebugDot()){
            "${id}: ${label}"
        } else {
            label
        }, Preserve)
    ]), true, edgeContent)
    DrawPorts(targets, "e", edgeContent)
    
    let subtable = ArrayList<(String, IndentInstruction)>()
    MakeElem("tr", [], edgeContent, false, subtable)
    let currentTableStyle = ArrayList<(String, String)>()
    currentTableStyle.addAll(style)
    currentTableStyle.addAll(tableStyle)
    let table = ArrayList<(String, IndentInstruction)>()
    MakeElem("table", currentTableStyle.toArray(), subtable, false, table)

    let declaration = ("${id} [label=<", Preserve)
    table.prepend(declaration)
    let conclusion = (">];", Preserve)
    table.append(conclusion)

    content.addAll(table)
}

func DrawEdge(
    e : Edge,
    expand : Int64,
    vertexMap : HashMap<Int64, Int64>,
    omittedEdges : HashSet<Int64>,
    graphContent : ArrayList<(String, IndentInstruction)>,
    connectionContent: ArrayList<(String, IndentInstruction)>
) : Unit {
    if (expand != 0) {
        match (e.GetSubgraph()) {
            case None => DrawEdgeNode(e, graphContent)
            case Some(g) => 
                omittedEdges.put(e.GetId())
                DrawSubgraphCluster(g, e, expand, vertexMap, omittedEdges, graphContent, connectionContent)
        }
    } else {
        DrawEdgeNode(e, graphContent)
    }
}

func DrawOptions(selector : String, opts : Array<(String, String)>) : (String, IndentInstruction) {
    let options = fold_left(
        { acc : String, opt : (String, String) => 
            let (key, value) = opt
            let keyval = "${key}=\"${value}\""
            if(acc == "") {
                keyval
            } else {
                "${acc}, ${keyval}"
            }
        },
        "",
        opts
    )
    ("${selector}[${options}]", Preserve)
}

func DrawVertex(
    v : Vertex,
    content : ArrayList<(String, IndentInstruction)>, 
    vertexMap : HashMap<Int64, Int64>
) : Unit {
    match (vertexMap.get(v.GetId())) {
        case Some(vv) => ()
        case None => 
        let text = if(IsDebugDot()){
            "${v.GetId()}"
        } else {
            ""
        }
        content.append(DrawOptions("v${v.GetId()}", [("label", "${v.GetWidth()}"), ("xlabel", text)]))
    }
}

func DrawConnections(e : Edge, vertexMap : HashMap<Int64, Int64>, omittedEdges : HashSet<Int64>, content : ArrayList<(String, IndentInstruction)>) : Unit {
    func DrawConnectionsForArray(array : Array<Vertex>, port : String, vertexFirst : Bool) : Unit {
        for (i in 0..array.size()) {
            let v = array[i]
            let id = match (vertexMap.get(v.GetId())) {
                    case None => v.GetId()
                    case Some(w) => w
            }
            let vText = "v${id}"
            let eText =  "e${e.GetId()}:${port}${i}:${port}"
            let str = DrawConnection(vText, eText, vertexFirst)
            content.append((str, Preserve))
        }
    }
    if(!omittedEdges.contains(e.GetId())){
        DrawConnectionsForArray(e.GetSources(), "w", true)
        DrawConnectionsForArray(e.GetTargets(), "e", false)
    }
}

func DrawConnection(vText : String, eText : String, vertexFirst : Bool) {
    if(vertexFirst) {

        "${vText}:e -- ${eText}"
    } else {
        "${eText} -- ${vText}:w"
    }
}

func DrawInterfaceConnections(list : Array<Vertex>, vertexFirst : Bool, content : ArrayList<(String, IndentInstruction)>) : Unit {
    for (i in 0..list.size()){
        let v = list[i]
        let vText = "v${v.GetId()}"
        let str = if (vertexFirst) {
            let eText = "output:w${i}:w"
            DrawConnection(vText, eText, vertexFirst)
        } else {
            let eText = "input:e${i}:e"
            DrawConnection(vText, eText, vertexFirst)
        }
        content.append((str, Preserve))
    }
}

func DrawSubgraph(
    opt : Array<(String, String)>, 
    subgraphContent : ArrayList<(String, IndentInstruction)>,
    graphContent : ArrayList<(String, IndentInstruction)>
) : Unit {
    graphContent.add(("{", Indent))
    let opts = DrawOptions("graph", opt)
    graphContent.add(opts)
    graphContent.addAll(subgraphContent)
    graphContent.add(("}", Deindent))
}

func DrawInterface(
    vertices : Array<Vertex>, 
    sink : Bool,
    content : ArrayList<(String, IndentInstruction)>
) : Unit {
    let (text, opts, sources, targets) = if (sink) {
        ("output", maxSubgraphOpts, vertices, Array<Vertex>())
    } else {
        ("input", minSubgraphOpts, Array<Vertex>(), vertices)
    }
    let subgraphContent = ArrayList<(String, IndentInstruction)>()
    DrawEdgelikeNode(text, text, interfaceStyle, sources, targets, subgraphContent)
    DrawSubgraph(opts, subgraphContent, content)
    DrawInterfaceConnections(vertices, sink, content)

}

func DrawSubgraphCluster(
    f : InterfacedHypergraph,
    parent : Edge,
    expand : Int64,
    vertexMap : HashMap<Int64, Int64>,
    omittedEdges : HashSet<Int64>,
    graphContent : ArrayList<(String, IndentInstruction)>,
    connectionContent : ArrayList<(String, IndentInstruction)>
) : Unit {

    func UpdateVertexMap(array : Array<Vertex>, getLocalVertex : (Int64) -> Vertex, getParentVertex : (Int64) -> Vertex) : Unit {
        for (i in 0..array.size()) {
            let localVertex = getLocalVertex(i).GetId()
            let parentVertex = getParentVertex(i).GetId()
            match(vertexMap.get(parentVertex)) {
                case Some(vv) => vertexMap.put(localVertex, vv)
                case None => vertexMap.put(localVertex, parentVertex)
            }
        }
    }

    let id = parent.GetId()
    let label = parent.GetLabel()

    UpdateVertexMap(f.GetInputVertices(), { i : Int64 => f.GetInput(i) }, { i : Int64 => parent.GetSource(i) })
    UpdateVertexMap(f.GetOutputVertices(), { i : Int64 => f.GetOutput(i) }, { i : Int64 => parent.GetTarget(i) })

    let opening = ("subgraph cluster${id} {", Indent)
    let labelText = ("label=\"${label}\"", Preserve)
    let closing = ("}", Deindent)

    let subgraphContent = ArrayList<(String, IndentInstruction)>()
    DrawHypergraph(f.GetGraph(), expand - 1, vertexMap, omittedEdges, subgraphContent, connectionContent)

    graphContent.append(opening)
    graphContent.append(labelText)
    graphContent.addAll(subgraphContent)
    graphContent.append(closing)
}

func DrawInterfaces(f : InterfacedHypergraph, content : ArrayList<(String, IndentInstruction)>) : Unit {
    DrawInterface(f.GetInputVertices(), false, content)
    DrawInterface(f.GetOutputVertices(), true, content)
}

public func DrawHypergraph(
    f : Hypergraph, 
    expand : Int64,
    vertexMap : HashMap<Int64, Int64>,
    omittedEdges : HashSet<Int64>,
    graphContent : ArrayList<(String, IndentInstruction)>,
    connectionContent : ArrayList<(String, IndentInstruction)>
) : Unit {
    let vertexContent = ArrayList<(String, IndentInstruction)>()
    let edgeContent = ArrayList<(String, IndentInstruction)>()
    let newConnectionContent = ArrayList<(String, IndentInstruction)>()
    for(e in f.GetVertices()){
        DrawVertex(e, vertexContent, vertexMap)
    }
    for (e in f.GetEdges()){
        DrawEdge(e, expand,  vertexMap, omittedEdges, edgeContent, connectionContent)
        DrawConnections(e, vertexMap, omittedEdges, connectionContent)
    }
    let vertexOptionsString = DrawOptions("node", vertexNodeOpts)
    let edgeOptionsString = DrawOptions("node", edgeNodeOpts)
    
    
    graphContent.append(vertexOptionsString)
    graphContent.addAll(vertexContent)
    graphContent.append(edgeOptionsString)
    graphContent.addAll(edgeContent)
    connectionContent.addAll(newConnectionContent)
}

public func DotGraph(f : InterfacedHypergraph, expand : Int64) : String {

    let declaration = ("graph ${f.GetName()} {", Indent)    
    let graphContent = ArrayList<(String, IndentInstruction)>([declaration])

    let graphOptionsString = DrawOptions("graph", graphOpts)
    graphContent.append(graphOptionsString)

    let connectionContent = ArrayList<(String, IndentInstruction)>()

    DrawHypergraph(f.GetGraph(), expand, HashMap<Int64, Int64>(), HashSet<Int64>(), graphContent, connectionContent)
    graphContent.addAll(connectionContent)
    DrawInterfaces(f, graphContent)

    let conclusion = ("}", Deindent)
    graphContent.append(conclusion)

    ConvertStringIndentListToString(graphContent)
}

let tab = "    "

func indentString(n : Int64, str : String) : String {
    var tabs = ""
    for (i in 0..n) {
        tabs = "${tabs}${tab}"
    }
    "${tabs}${str}"
}

public func ConvertStringIndentListToString(list : ArrayList<(String, IndentInstruction)>) : String {
    let (output, i) = 
        fold_left(
            { acc : (String, Int64) , si : (String, IndentInstruction) => 
                let (accString, accIndent) = acc
                let (curString, instruction) = si
                let (curIndent, nextIndent) = match(instruction) {
                     case Indent => (accIndent, accIndent + 1)
                     case Deindent => (accIndent - 1, accIndent - 1)
                     case Preserve => (accIndent, accIndent)
                }
                let line = "${indentString(curIndent, curString)}"
                let nextAcc = if(accString == "") {
                    line
                } else {
                    "${accString}\n${line}"
                }
                (nextAcc, nextIndent)
            },
            ("", 0),
            list
        )
    output
}

public func WriteDotToFile(f : InterfacedHypergraph, expand : Int64, file : String){
    let filename = GetDotFile(file)
    Info("WriteDotToFile", "Writing dot file ${filename}")
    let dot = DotGraph(f, expand)
    let fs = FileStream(filename, OpenMode.ForceCreate)
    if(fs.openFile()){
        fs.write(dot)
        fs.flush()
        fs.close()
    } else {
        fs.close()
        throw CouldNotOpenFileException("WriteDotToFile", filename)
    }
}