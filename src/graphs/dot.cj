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
    ("rankdir", "LR")
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
let gateStyle = [
    bgColour("cyan")
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

let vertexCommentString = "Vertices"
let edgeCommentString = "Edges"
let connsCommentString = "Connections"

let maxSubgraphOpts = [
    ("rank", "max")
]
let minSubgraphOpts = [
    ("rank", "min")
]

public enum IndentInstruction {
    | Preserve
    | Indent
    | Deindent
}
extend IndentInstruction <: ToString {
    public func toString() : String {
        match(this) {
            case Preserve => "Preserve"
            case Indent => "Indent"
            case Deindent => "Deindent"
        }
    }
}

func MakeElem(tag : String, options : Array<(String, String)>, content: Option<ArrayList<(String, IndentInstruction)>>, inline: Bool) : ArrayList<(String, IndentInstruction)> {
    let elem = ArrayList<(String, IndentInstruction)>()
    let options = fold_left(
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
    let opener = (
        if (options == "") {
            "<${tag}>"
        } else {
            "<${tag} ${options}>"
        },
        Indent
    )
    let closer = ("</${tag}>", Deindent)
    elem.add(opener)
    match(content) {
        case Some(c) => elem.addAll(c)
        case None => ()
    }
    elem.add(closer)

    if (inline) {
        ArrayList<(String, IndentInstruction)>([(
            fold_left (
            { acc : String, cur : (String, IndentInstruction) => "${acc}${cur[0]}"},
            "",
            elem
        ), Preserve)])
    } else {
        elem
    }

}

func EdgeVerticesToTable(vs : Array<Vertex>, id : String) : ArrayList<(String, IndentInstruction)> {
    let content = ArrayList<(String, IndentInstruction)>()
    for (i in 0..vs.size()) {
        let td = MakeElem("td", [
            ("height", "${portHeight}"),
            ("width", "${portWidth}"),
            ("port", "${id}${i}")
        ], Option<ArrayList<(String, IndentInstruction)>>.None, true)
        let tr = MakeElem("tr", [], td, true)
        content.addAll(tr)
    }
    let table = MakeElem("table", [], content, false)
    table
}

public func DrawEdgeNode(
    id : String, 
    nodeStyle : Array<(String, String)>, 
    text : String, 
    sources : Array<Vertex>, 
    targets : Array<Vertex>
) : ArrayList<(String, IndentInstruction)> {

    func DrawVertexTable(array : Array<Vertex>, id : String) : ArrayList<(String, IndentInstruction)> {
        let content = ArrayList<(String, IndentInstruction)>()
        if (array.size() != 0) {
            let table = EdgeVerticesToTable(array, id)
            let wrapped = MakeElem("td", [], table, false)
            content.addAll(wrapped)
        }
        content
    }

    let sourceTable = DrawVertexTable(sources, "w")
    let targetTable = DrawVertexTable(targets, "e")
    let edgeText = MakeElem("td", [], ArrayList<(String, IndentInstruction)>([
        (if(DebugDotOn()){
            "${id}: ${text}"
        } else {
            text
        }, Preserve)
    ]), true)

    let content = ArrayList<(String, IndentInstruction)>()
    content.addAll(sourceTable)
    content.addAll(edgeText)
    content.addAll(targetTable)
    
    let subtable = MakeElem("tr", [], content, false)

    let currentTableStyle = ArrayList<(String, String)>(nodeStyle)
    currentTableStyle.addAll(tableStyle)

    let table = MakeElem("table", currentTableStyle.toArray(), subtable, false)

    let declaration = ("${id} [label=<", Preserve)
    table.prepend(declaration)
    let conclusion = (">];", Preserve)
    table.append(conclusion)

    table
}

func DrawEdge(e : Edge) {
    let (style, label) = match(e.GetLabel()){
        case VALUE(values, signed)  => (valueStyle      , PrintValue(values, signed, GetDotNumberRepresentation()))
        case BUNDLER(ms,ns)         => (compressorStyle , if (ms.size() < ns.size()) { "◁" } else { "▷" })
        case JOIN(width)            => (structuralStyle , "∇") 
        case GATE(spec)             => (gateStyle       , spec.GetName())
        case BLACKBOX(spec)         => (blackboxStyle   , spec.GetName())
        case DELAY(dur, width)      => (delayStyle      , "${dur}")
    }
    let text = label
    DrawEdgeNode("e${e.GetId()}", style, text, e.GetSources(), e.GetTargets())
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

func DrawVertex(v : Vertex) : (String, IndentInstruction) {
    let text = if(DebugDotOn()){
        "${v.GetId()}"
    } else {
        ""
    }
    DrawOptions("v${v.GetId()}", [("label", "${v.GetWidth()}"), ("xlabel", text)])
}

func DrawConnections(e : Edge) : ArrayList<(String, IndentInstruction)> {
    func DrawConnectionsForArray(array : Array<Vertex>, port : String, vertexFirst : Bool) : ArrayList<(String, IndentInstruction)> {
        mapi(
            { v : Vertex, i : Int64 =>  
                let vText = "v${v.GetId()}"
                let eText =  "e${e.GetId()}:${port}${i}:${port}"
                let str = if(vertexFirst) {
                    "${vText}:e -- ${eText}"
                } else {
                    "${eText} -- ${vText}:w"
                }
                (str, Preserve)
            },
            array
        )
    }
    let sourceString = DrawConnectionsForArray(e.GetSources(), "w", true)
    let targetString = DrawConnectionsForArray(e.GetTargets(), "e", false)
    sourceString.addAll(targetString)
    sourceString
}

func DrawInterfaceConnections(list : Array<Vertex>, vertexFirst : Bool) : ArrayList<(String, IndentInstruction)> {
    mapi(
        { v : Vertex, i : Int64 =>
            let vText = "v${v.GetId()}"
            let str = if(vertexFirst) {
                let eText = "output:w${i}:w"
                "${vText}:e -- ${eText}"
            } else {
                let eText = "input:e${i}:e"
                "${eText} -- ${vText}:w"
            }
            (str, Preserve)
        },
        list
    )
}

func DrawSubgraph(opt : Array<(String, String)>, content : ArrayList<(String, IndentInstruction)>) : ArrayList<(String, IndentInstruction)> {
    let subgraph = ArrayList<(String, IndentInstruction)>([("{", Indent)])
    let opts = DrawOptions("graph", opt)
    subgraph.add(opts)
    subgraph.addAll(content)
    subgraph.add(("}", Deindent))
    subgraph
}

public func DotGraph(f : InterfacedHypergraph) {
    let vertexContent = ArrayList<(String, IndentInstruction)>()
    let edgeContent = ArrayList<(String, IndentInstruction)>()
    let connectionContent = ArrayList<(String, IndentInstruction)>()
    for(e in f.GetVertices()){
        let vertexLine = DrawVertex(e)
        vertexContent.add(vertexLine)
    }
    for (e in f.GetEdges()){
        let edgeLines = DrawEdge(e)
        edgeContent.addAll(edgeLines)
        let connectionLines = DrawConnections(e)
        connectionContent.addAll(connectionLines)
    }

    let declaration = ("graph ${f.GetName()} {", Indent)
    let conclusion = ("}", Deindent)

    let graphContent = ArrayList<(String, IndentInstruction)>([declaration])
    let graphOptionsString = DrawOptions("graph", graphOpts)

    let vertexOptionsString = DrawOptions("node", vertexNodeOpts)
    let edgeOptionsString = DrawOptions("node", edgeNodeOpts)

    let input = DrawEdgeNode("input", interfaceStyle, "inputs", [], f.GetInputVertices())
    let inputContent = DrawSubgraph(minSubgraphOpts, input)
    let inputConnections = DrawInterfaceConnections(f.GetInputVertices(), false)
    let output = DrawEdgeNode("output", interfaceStyle, "outputs", f.GetOutputVertices(), [])
    let outputContent = DrawSubgraph(maxSubgraphOpts, output)
    let outputConnections = DrawInterfaceConnections(f.GetOutputVertices(), true)

    graphContent.append(graphOptionsString)
    graphContent.append(vertexOptionsString)
    graphContent.addAll(vertexContent)
    graphContent.append(edgeOptionsString)
    graphContent.addAll(inputContent)
    graphContent.addAll(edgeContent)
    graphContent.addAll(outputContent)
    graphContent.addAll(inputConnections)
    graphContent.addAll(connectionContent)
    graphContent.addAll(outputConnections)
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

public func WriteDotToFile(f : InterfacedHypergraph, file : String){
    let filename = GetDotFile(file)
    Info("WriteDotToFile", "Writing dot file ${filename}")
    let dot = DotGraph(f)
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