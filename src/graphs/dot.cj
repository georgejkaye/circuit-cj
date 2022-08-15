/**
 * graphs/dot.cj
 *
 * Functions for generating dot graphs for hypergraphs
 *
 * @author George Kaye
 * @since 0.1
 */

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
    for(i in 0..code.size){
        let charc = UInt32(code[i])
        let subs = Char(charc + 0x2050)
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
/**
 * Record for storing a line of dot code along with a relevant
 * indentation instruction
 */
public class DotLine {
    public DotLine(
        let str : String,
        let instruction : IndentInstruction
    ){}
}
/**
 * Create a string of the form "key1=val1 key2=val2 ... keyn=valn" for a given
 * array of key-value pairs, for use as options in an HTML element
 * @param options The array of options
 * @return The html options string
 */
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
 * @param elementContent  The list to add the element lines to
 */
func MakeElem(
    tag : String,
    options : Array<(String, String)>,
    elemContent: ArrayList<DotLine>,
    inline: Bool,
    elementContent : ArrayList<DotLine>
) : Unit {
    let elem = ArrayList<DotLine>()
    let optionString = CreateElemOptionsString(options)
    let opener = DotLine("<${tag} ${optionString}>", Indent)
    let closer = DotLine("</${tag}>", Deindent)
    elem.append(opener)
    elem.appendAll(elemContent)
    elem.append(closer)

    let finalElem = if (inline) {
        ArrayList<DotLine>([
            DotLine(
                fold_left (
                { acc : String, cur : DotLine => "${acc}${cur.str}"},
                "",
                elem
            ), Preserve)])
    } else {
        elem
    }
    elementContent.appendAll(finalElem)
}
/**
 * Convert an array of source or target ports into an HTML table in which each cell
 * contains the name of the port, if present, and the width of the port. These ports
 * can be used as the ports of a parent HTML node.
 * @param ports The array of ports
 * @param id The id string of the parent edge
 * @param elementContent The
 */
func EdgeVerticesToTable(ports : Array<Socket>, id : String, elementContent : ArrayList<DotLine>) : Unit {
    let content = ArrayList<DotLine>()
    // Each port is its own row
    for (i in 0..ports.size) {
        let port = ports[i]
        let td = ArrayList<DotLine>()
        // The port contains the port name (if one is given)
        // and the width of the port
        let portText = match(port.GetName()){
            case None => "${port.GetWidth()}"
            case Some(str) => "${str}:${port.GetWidth()}"
        }
        MakeElem(
            "td",
            [
                ("height", "${portHeight}"),
                ("width", "${portWidth}"),
                ("port", "${id}${i}")
            ],
            ArrayList<DotLine>([
                DotLine(portText, Preserve)
            ]),
            true,
            td
        )
        MakeElem("tr", [], td, true, content)
    }
    MakeElem("table", [], content, false, elementContent)
}
/**
 * Append dotlines for an edge to a list of content dotlines
 * @param e The edge
 * @param content The list of dotlines to append to
 */
func DrawEdgeNode(e : Edge, content : ArrayList<DotLine>) : Unit {
    let (style, label) = match(e.GetLabel()){
        case VALUE(spec) =>
            (valueStyle, Some(spec.GetValueAsRepresentation(GetDotNumberRepresentation())))
        case BUNDLER(ms,ns) =>
            (compressorStyle, Some(if (ms.size < ns.size) { "<" } else { ">" }))
        case JOIN(width) =>
            (structuralStyle, Some("V"))
        case PRIMITIVE(spec) =>
            (primitiveStyle, spec.GetName())
        case COMPOSITE(spec) =>
            (compositeStyle, spec.GetName())
        case BLACKBOX(spec) =>
            (blackboxStyle, spec.GetName())
        case DELAY(dur, width) =>
            (delayStyle, Some("${dur}"))
    }
    DrawEdgelikeNode(
        "e${e.GetId()}",
        label,
        style,
        e.GetSources(),
        e.GetInputPorts(),
        e.GetTargets(),
        e.GetOutputPorts(),
        content
    )
}
/**
 * Append dotlines for an 'edge-like' node (i.e. edge or interface node) to
 * list of element dotlines
 * @param id The id of the node
 * @param label The label to give the node
 * @param style The key-value list of styles to apply to this node
 * @param sources The list of source vertices
 * @param sourcePorts The list of source ports
 * @param targets The list of target vertices
 * @param content The list of content dotlines so far
 */
func DrawEdgelikeNode<T>(
    id : String,
    label : Option<String>,
    style : Array<(String, String)>,
    sources : Array<T>,
    sourcePorts : Array<Socket>,
    targets : Array<T>,
    targetPorts : Array<Socket>,
    content : ArrayList<DotLine>
) : Unit where T <: ContainsVertex {
    /**
     * Append dotlines for the ports on the left or right of the edge
     * to a list of edge dotlines
     * @param array The array of vertices
     * @param port The array of ports
     * @param id The id of the edge
     * @param edgeContent The list of dotlines to append to
     */
    func DrawPorts(
        array : Array<T>,
        ports : Array<Socket>,
        id : String,
        edgeContent : ArrayList<DotLine>
    ) : Unit {
        if (array.size != 0) {
            let table = ArrayList<DotLine>()
            EdgeVerticesToTable(ports, id, table)
            MakeElem("td", [], table, false, edgeContent)
        }
    }
    // The edge needs to be drawn as a table
    let edgeContent = ArrayList<DotLine>()
    // Draw the sources on the left
    DrawPorts(sources, sourcePorts, "w", edgeContent)
    let labelText = match(label) {
        case None    => ""
        case Some(l) => l
    }
    // Draw the label on the middle
    MakeElem(
        "td",
        [],
        ArrayList<DotLine>([
            DotLine(
                if(IsDebugDot()){
                    "${id}: ${labelText}"
                } else {
                    labelText
                },
                Preserve
            )
        ]),
        true,
        edgeContent
    )
    // Draw the targets on the right
    DrawPorts(targets, targetPorts, "e", edgeContent)
    // These three components exist inside a single row
    let subtable = ArrayList<DotLine>()
    MakeElem("tr", [], edgeContent, false, subtable)
    // Create the overall table
    let currentTableStyle = ArrayList<(String, String)>()
    currentTableStyle.appendAll(style)
    currentTableStyle.appendAll(tableStyle)
    let table = ArrayList<DotLine>()
    MakeElem("table", currentTableStyle.toArray(), subtable, false, table)
    // Add the edge identifier and closing braces
    let declaration = DotLine("${id} [label=<", Preserve)
    table.prepend(declaration)
    let conclusion = DotLine(">];", Preserve)
    table.append(conclusion)

    content.appendAll(table)
}
/**
 * Append dotlines for an edge to a list of element and connections dotlines
 * @param e The edge
 * @param depth The maximum depth of subgraph to expand
 * @param vertexMap A map sending vertices to vertices that have subsumed it
 * @param omittedEdges A list of edges that should not be drawn
 * @param elementContent The list of element dotlines so far
 * @param connectionContent The list of connection dotlines
 */
func DrawEdge(
    e : Edge,
    depth : Int64,
    vertexMap : HashMap<Int64, Int64>,
    omittedEdges : HashSet<Int64>,
    elementContent : ArrayList<DotLine>,
    connectionContent: ArrayList<DotLine>
) : Unit {
    if (depth != 0) {
        match (e.GetSubgraph()) {
            case None => DrawEdgeNode(e, elementContent)
            case Some(g) =>
                omittedEdges.put(e.GetId())
                DrawSubgraphCluster(g, e, depth, vertexMap, omittedEdges, elementContent, connectionContent)
        }
    } else {
        DrawEdgeNode(e, elementContent)
    }
}
/**
 * Get a dotline of options in selector[key=val, key1=val1...] format
 * @param selector The selector to apply the options to
 * @param opts The list of key-value pairs of options
 * @return The dotline of the options
 */
func DrawOptions(selector : String, opts : Array<(String, String)>) : DotLine {
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
    DotLine("${selector}[${options}]", Preserve)
}
/**
 * Append the dotline for a vertex to a list
 * @param v The vertex
 * @param content The list of dotlines to append to
 * @param vertexMap A map sending vertices to vertices that have subsumed it
 */
func DrawVertex(
    v : Vertex,
    content : ArrayList<DotLine>,
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
        content.append(
            DrawOptions(
                "v${v.GetId()}",
                [
                    ("label", "${v.GetWidth()}"),
                    ("xlabel", text)
                ]
            )
        )
    }
}
/**
 * Append all the connections for the sources and targets of an edge to a
 * list of dotlines.
 * @param e The edge
 * @param vertexMap A map sending vertices to vertices that have subsumed it
 * @param omittedEdges List of edges that should not be drawn
 * @param content The list of dotlines to append to
 */
func DrawConnections(
    e : Edge,
    vertexMap : HashMap<Int64, Int64>,
    omittedEdges : HashSet<Int64>,
    content : ArrayList<DotLine>
) : Unit {
    func DrawConnectionsForArray(array : Array<Vertex>, port : String, vertexFirst : Bool) : Unit {
        for (i in 0..array.size) {
            let v = array[i]
            let id = match (vertexMap.get(v.GetId())) {
                    case None => v.GetId()
                    case Some(w) => w
            }
            let vText = "v${id}"
            let eText =  "e${e.GetId()}:${port}${i}:${port}"
            let str = DrawConnection(vText, eText, vertexFirst)
            content.append(DotLine(str, Preserve))
        }
    }
    if(!omittedEdges.contains(e.GetId())){
        DrawConnectionsForArray(e.GetSources(), "w", true)
        DrawConnectionsForArray(e.GetTargets(), "e", false)
    }
}
/**
 * Get the connection text for a connection between a vertex and an edge
 * @param vText The name of the vertex
 * @param eText The name of the edge
 * @param vertexFirst Whether the connection is from vertex to edge (i.e.
                        target) or vice versa (i.e. source)
 * @return The connection string
 */
func DrawConnection(vText : String, eText : String, vertexFirst : Bool) : String {
    if(vertexFirst) {

        "${vText}:e -- ${eText}"
    } else {
        "${eText} -- ${vText}:w"
    }
}
/**
 * Append dotlines corresponding to a subgraph to lists of existing graph content.
 * A subgraph is drawn as a cluster with a box around, indicating the extend of the
 * subgraph. The sources and targets of the parent edge are 'merged' with the interface
 * vertices of the subgraph, making a smooth connection.
 * @param f The interfaced hypergraph
 * @param parent The edge that this subgraph belongs to
 * @param depth The maximum depth of subgraphs to expand
 * @param vertexMap A map indicating which vertices have been subsumed by others
 * @param omittedEdges A list of edges that should not be drawn
 * @param elementContent The list of graph element dotlines so far
 * @param connectionContent The list of connection element dotlines so far
 */
func DrawSubgraphCluster(
    f : InterfacedHypergraph,
    parent : Edge,
    depth : Int64,
    vertexMap : HashMap<Int64, Int64>,
    omittedEdges : HashSet<Int64>,
    elementContent : ArrayList<DotLine>,
    connectionContent : ArrayList<DotLine>
) : Unit {
    /**
     * Update the map that sends vertices to vertices that they have been subsumed by. This occurs
     * because the internal interfaces of subgraphs that have been expanded are 'merged' with
     * the sources and targets of their parent edge.
     * @param array An interface of the parent edge
     * @param getLocalVertex A function that gets the ith local interface vertex
     * @param getParentVertex A function that gets the ith parent interface vertex
     */
    func UpdateVertexMap(
        array : Array<Vertex>,
        getLocalVertex : (Int64) -> Vertex,
        getParentVertex : (Int64) -> Vertex
    ) : Unit {
        for (i in 0..array.size) {
            let localVertex = getLocalVertex(i).GetId()
            let parentVertex = getParentVertex(i).GetId()
            match(vertexMap.get(parentVertex)) {
                case Some(vv) => vertexMap.put(localVertex, vv)
                case None => vertexMap.put(localVertex, parentVertex)
            }
        }
    }
    let id = parent.GetId()
    let openingText = DotLine("subgraph cluster${id} {", Indent)
    let label = parent.GetLabel()
    let labelText = DotLine("label=\"${label}\"", Preserve)
    let closingText = DotLine("}", Deindent)
    // Recursively draw the subgraph, mapping any of its interface vertices
    // to the source and target of the parent edge, and decreasing the depth
    // by one
    let subelementContent = ArrayList<DotLine>()
    DrawHypergraph(
        f.GetGraph(),
        depth - 1,
        vertexMap,
        omittedEdges,
        subelementContent,
        connectionContent
    )
    elementContent.append(openingText)
    elementContent.append(labelText)
    elementContent.appendAll(subelementContent)
    elementContent.append(closingText)
}
/**
 * Append dotlines corresponding to a(n uninterfaced) hypergraph to lists of
 * element and connection dotlines, expanding subgraphs up to a given depth.
 * @param f The hypergraph
 * @param depth The maximum depth to expand subgraphs
 * @param vertexMap A map containing vertex ids that subsume the ones in this graph,
 *                      such as if a parent edge has been expanded and the internal
 *                      vertices need to be merged with the external ones
 * @param omittedEdges A set of edges that should not be drawn, e.g. the parent edges
                         of subgraphs that have been expanded
 * @param elementContent The list containing the existing element dotlines so far
 * @param connectionContent The list containing the existing connection dotlines so far
 */
public func DrawHypergraph(
    f : Hypergraph,
    depth : Int64,
    vertexMap : HashMap<Int64, Int64>,
    omittedEdges : HashSet<Int64>,
    elementContent : ArrayList<DotLine>,
    connectionContent : ArrayList<DotLine>
) : Unit {
    let vertexContent = ArrayList<DotLine>()
    let edgeContent = ArrayList<DotLine>()
    let newConnectionContent = ArrayList<DotLine>()
    for(e in f.GetVertices()){
        DrawVertex(e, vertexContent, vertexMap)
    }
    for (e in f.GetEdges()){
        DrawEdge(e, depth,  vertexMap, omittedEdges, edgeContent, connectionContent)
        DrawConnections(e, vertexMap, omittedEdges, connectionContent)
    }
    let vertexOptionsString = DrawOptions("node", vertexNodeOpts)
    let edgeOptionsString = DrawOptions("node", edgeNodeOpts)
    // Append everything to the content lists
    elementContent.append(vertexOptionsString)
    elementContent.appendAll(vertexContent)
    elementContent.append(edgeOptionsString)
    elementContent.appendAll(edgeContent)
    connectionContent.appendAll(newConnectionContent)
}
/**
 * Append dotlines for a subgraph to the list of element lines so far.
 * @param opt The array of subgraph options
 * @param subelementContent The dotlines that belong to the subgraph
 * @param elementContent The element dotlines so far
 */
func DrawSubgraph(
    opt : Array<(String, String)>,
    subelementContent : ArrayList<DotLine>,
    elementContent : ArrayList<DotLine>
) : Unit {
    elementContent.append(DotLine("{", Indent))
    let opts = DrawOptions("graph", opt)
    elementContent.append(opts)
    elementContent.appendAll(subelementContent)
    elementContent.append(DotLine("}", Deindent))
}
/**
 * Append the dotlines for connections from vertices to an interface to a list of dotlines
 * @param list The array of interface vertices
 * @param vertexFirst If the connection is from the vertex to the interface (output) or vice versa (input)
 * @param content The list of dotlines so far
 */
func DrawInterfaceConnections(list : Array<InterfaceVertex>, vertexFirst : Bool, content : ArrayList<DotLine>) : Unit {
    for (i in 0..list.size){
        let v = list[i].GetVertex()
        let vText = "v${v.GetId()}"
        let str = if (vertexFirst) {
            let eText = "output:w${i}:w"
            DrawConnection(vText, eText, vertexFirst)
        } else {
            let eText = "input:e${i}:e"
            DrawConnection(vText, eText, vertexFirst)
        }
        content.append(DotLine(str, Preserve))
    }
}
/**
 * Append dotlines corresponding to an interface to the lists of lines so far.
 * Interfaces are drawn as subgraphs, so that inputs can be drawn at the far
 * left of the graph and outputs at the far right
 * @param vertices The array of vertices in the interface
 * @param ports The array of ports in the interface
 * @param sink Whether the interface should be drawn at the far right of the graph
 ( @param elementContent The list of element dotlines so far
 */
func DrawInterface(
    vertices : Array<InterfaceVertex>,
    ports : Array<Socket>,
    sink : Bool,
    elementContent : ArrayList<DotLine>
) : Unit {
    // The content of the interface edge depends on whether
    // it is a sink edge (output) or source edge (input)
    let (text, opts, sources, targets) = if (sink) {
        ("output", maxSubgraphOpts, vertices, Array<InterfaceVertex>())
    } else {
        ("input", minSubgraphOpts, Array<InterfaceVertex>(), vertices)
    }
    let subelementContent = ArrayList<DotLine>()
    let (sourcePorts, targetPorts) =
        if (sink) {
            (ports, Array<Socket>())
        } else {
            (Array<Socket>(), ports)
        }
    DrawEdgelikeNode(text, "", interfaceStyle, sources, sourcePorts, targets, targetPorts, subelementContent)
    DrawSubgraph(opts, subelementContent, elementContent)
    DrawInterfaceConnections(vertices, sink, elementContent)

}
/**
 * Append dotlines for the input and output edges of an interfaced hypergraph
 * to a list of existing dotlines.
 * @param f The interfaced hypergraph
 * @param content The existing graph content
 */
func DrawInterfaces(f : InterfacedHypergraph, content : ArrayList<DotLine>) : Unit {
    DrawInterface(f.GetInputVertices(), f.GetInputPorts(), false, content)
    DrawInterface(f.GetOutputVertices(), f.GetOutputPorts(), true, content)
}
/**
 * Generate a string of dot code corresponding to an interfaced hypergraph.
 * The maximum depth of subgraphs drawn can be specified: any subgraphs deeper
 * than this will be drawn as single edges.
 * @param f The interfaced hypergraph
 * @param depth The maximum depth of subgraphs to expand
 */
public func DotGraph(f : InterfacedHypergraph, depth : Int64) : String {
    let elementContent = ArrayList<DotLine>()
    // Declare the name of the graph
    let declaration = DotLine("graph ${f.GetName()} {", Indent)
    elementContent.append(declaration)
    // Declare the global graph options
    let graphOptionsString = DrawOptions("graph", graphOpts)
    elementContent.append(graphOptionsString)
    // Draw the hypergraph, the connections are drawn after declaring the vertices and edges
    let connectionContent = ArrayList<DotLine>()
    DrawHypergraph(
        f.GetGraph(),
        depth,
        HashMap<Int64,Int64>(),
        HashSet<Int64>(),
        elementContent,
        connectionContent
    )
    elementContent.appendAll(connectionContent)
    // Draw the inputs and the outputs
    DrawInterfaces(f, elementContent)
    // Close the opening brace
    let conclusion = DotLine("}", Deindent)
    elementContent.append(conclusion)
    // Generate the final string
    ConvertStringIndentListToString(elementContent)
}
/** Width of a tab */
let tab = "    "
/**
 * Indent a string by a given number of tabs
 * @param n The number of tabs to indent by
 * @param str The string to indent
 * @return The indented string
 */
func indentString(n : Int64, str : String) : String {
    var tabs = ""
    for (i in 0..n) {
        tabs = "${tabs}${tab}"
    }
    "${tabs}${str}"
}
/**
 * Convert a list of dotlines to a string with appropriate newlines
 * and indentation.
 * @param list The arraylist of dotlines
 * @return The corresponding dot code
 */
public func ConvertStringIndentListToString(list : ArrayList<DotLine>) : String {
    let (output, i) =
        fold_left(
            { acc : (String, Int64) , dl : DotLine =>
                // (previous lines, current indent)
                let (accString, accIndent) = acc
                // The instruction determines the current and next indent
                let (curIndent, nextIndent) = match(dl.instruction) {
                    // Indent the current line
                    case Indent => (accIndent, accIndent + 1)
                    // Deindent the next line
                    case Deindent => (accIndent - 1, accIndent - 1)
                    // Do nothing
                    case Preserve => (accIndent, accIndent)
                }
                let line = indentString(curIndent, dl.str)
                // Only make a newline if this is not the first line
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
/**
 * Write the dot graph for a graph to a file with a given name,
 * with the parent directory of the dot file specified in the settings.
 * @param f The interfaced hypergraph to draw
 * @param depth The maximum depth of subgraphs to draw
 * @param file The file name to write to
 */
public func WriteDotToFile(f : InterfacedHypergraph, depth : Int64, file : String) : Unit {
    let filename = GetDotFile(file)
    Info("WriteDotToFile", "Writing dot file ${filename}")
    let dot = DotGraph(f, depth)
    let fs = FileStream(filename, OpenMode.ForceCreate)
    if(fs.openFile()){
        fs.write(dot)
        fs.flush()
        fs.close()
    } else {
        fs.close()
        throw IOException("Could not open ${filename}")
    }
}