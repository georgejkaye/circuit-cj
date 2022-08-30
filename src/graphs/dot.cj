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

let tableStyle = [
    ("border", "0"),
    ("cellborder", "1"),
    ("cellspacing", "0")
]
func GetGraphOpts(){
    [
        ("rankdir", "LR"),
        ("bgcolor", if(IsDebugDot()) { "gray" } else { "white" })
    ]
}
let edgeNodeOpts = [
    ("shape", "plaintext"),
    ("fillcolor", "white"),
    ("fixedsize", "false"),
    ("fontcolor", "black")
]
let interfaceVertexOpts = [
    ("shape", "circle"),
    ("style", "filled"),
    ("height", "0.05"),
    ("fixedsize", "true"),
    ("label", "")
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
let valuesStyle = [
    bgColour("forestgreen")
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
let feedbackStyle = [
    ("color", "red")
]
/**
 * Enum to give indentation hints for the generated dot code.
 */
public enum IndentInstruction {
    | Preserve      // Keep the current indentation
    | Indent        // Indent one more starting from the next line
    | Deindent      // Indent one fewer starting from this line
    | SameLine      // Indent and toggle inline mode
}
extend IndentInstruction <: ToString {
    public func toString() : String {
        match(this) {
            case Preserve => "Preserve"
            case Indent => "Indent"
            case Deindent => "Deindent"
            case SameLine => "SameLine"
        }
    }
}
/**
 * Record for storing a line of dot code along with a relevant
 * indentation instruction
 */
public class DotLine <: ToString {
    public DotLine(
        let str : String,
        let instruction : IndentInstruction
    ){}
    public func toString() : String {
       "(${str}, ${instruction})"
    }

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
 * @param insideElem    The actions to perform when inside this element
 * @param inline        Whether or not to force this element to occupy one line
 * @param elementContent  The list to add the element lines to
 */
func MakeElem(
    tag : String,
    options : Array<(String, String)>,
    elementContent : ArrayList<DotLine>,
    inline : Bool,
    generateElemContents: (ArrayList<DotLine>, Bool) -> Unit
) : Unit {
    let optionString = CreateElemOptionsString(options)
    let optionStringSpaced = if (optionString == "") {
        optionString
    } else {
        " ${optionString}"
    }
    // Add the opening html tag
    let opener = DotLine("<${tag}${optionStringSpaced}>", if(inline) { SameLine } else { Indent })
    elementContent.append(opener)
    // Generate the dotlines for the content inside this element
    generateElemContents(elementContent, false)
    // Add the closing html tag
    let closer = DotLine("</${tag}>", if(inline) { SameLine } else { Deindent })
    elementContent.append(closer)
}
/**
 * Convert an array of source or target ports into an HTML table in which each cell
 * contains the name of the port, if present, and the width of the port. These ports
 * can be used as the ports of a parent HTML node.
 * @param ports The array of ports
 * @param id The id string of the parent edge
 * @param elementContent The element content arraylist to fill
 */
func MakePorts<T>(
    ports : Array<T>,
    prefix : String,
    elementContent : ArrayList<DotLine>
) : Unit where T <: Socket {
    MakeElem("td", [], elementContent, false, {elementContent, inline =>
        MakeElem("table", [], elementContent, false, {elementContent, inline =>
            MakeElem("tr", [], elementContent, true, {elementContent, inline =>
                for (i in 0..ports.size()) {
                    let portStyle =  [
                        ("height", "${portHeight}"),
                        ("width", "${portWidth}"),
                        ("port", "${prefix}${i}")
                    ]
                    MakeElem("td", portStyle, elementContent, false, {elementContent, inline =>
                        let port = ports[i]
                        // The port contains the port name (if one is given)
                        // and the width of the port
                        let portText = match(port.GetName()){
                            case None => "${port.GetWidth()}"
                            case Some(str) => "${str}:${port.GetWidth()}"
                        }
                        elementContent.append(DotLine(portText, Preserve))
                    })
                }
            })
        })
    })
}
/**
 * Append dotlines for an edge to a list of content dotlines
 * @param e The edge
 * @param content The list of dotlines to append to
 */
func DrawEdgeNode(e : Edge, content : ArrayList<DotLine>) : Unit {
    let style = match(e.GetLabel()){
        case VALUE(v) =>
            valueStyle
        case VALUES(spec) =>
            valuesStyle
        case BUNDLER(ms,ns) =>
            compressorStyle
        case JOIN(width) =>
            structuralStyle
        case PRIMITIVE(spec) =>
            primitiveStyle
        case COMPOSITE(spec) =>
            compositeStyle
        case BLACKBOX(spec) =>
            blackboxStyle
        case DELAY(dur, width) =>
            delayStyle
    }
    DrawBoxNode(
        "e${e.GetId()}",
        style,
        e.GetInputPorts(),
        e.GetLabel().GetName(),
        e.GetOutputPorts(),
        content
    )
}
func DrawBoxNode<T, U>(
    id : String,
    style : Array<(String, String)>,
    leftPorts : Array<T>,
    label : Option<String>,
    rightPorts : Array<U>,
    elementContent : ArrayList<DotLine>
) : Unit where T <: Socket, U <: Socket {
    // Add the edge identifier
    let declaration = DotLine("${id} [label=<", Indent)
    elementContent.append(declaration)
    // Make the main table of the node
    MakeElem("table", style, elementContent, false, {elementContent, inline =>
        // There is one row in the node
        MakeElem("tr", [], elementContent, false, {elementContent, inline =>
            // Draw left ports, if there are any
            if(leftPorts.size() > 0) {
                MakePorts(leftPorts, "w", elementContent)
            }
            // Draw the label, if there is one
            match(label) {
                case None => ()
                case Some(s) => MakeElem("td", [], elementContent, true, {elementContent, inline =>
                    let text = if(IsDebugDot()){
                        "${id}: ${s}"
                    } else {
                        s
                    }
                    elementContent.append(DotLine(text, Preserve))
                })
            }
            // Draw right ports, if there are any
            if(rightPorts.size() > 0) {
                MakePorts(leftPorts, "e", elementContent)
            }
        })
    })
    // Wrap everything up
    let conclusion = DotLine(">];", Deindent)
    elementContent.append(conclusion)
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
    omittedEdges : HashSet<Int64>,
    elementContent : ArrayList<DotLine>
) : Unit {
    if (depth != 0) {
        match (e.GetSubgraph()) {
            case None => DrawEdgeNode(e, elementContent)
            case Some(g) =>
                omittedEdges.put(e.GetId())
                DrawInterfacedHypergraph(
                    g,
                    e,
                    depth,
                    omittedEdges,
                    elementContent
                )
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
func GetOptions(opts : Array<(String, String)>) : String {
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
    "[${options}]"
}
func DrawOptions(selector : String, opts : Array<(String, String)>) : DotLine {
    let options = GetOptions(opts)
    DotLine("${selector}${options}", Preserve)
}
/**
 * Append the dotline for a vertex to a list
 * @param v The vertex
 * @param content The list of dotlines to append to
 * @param vertexMap A map sending vertices to vertices that have subsumed it
 */
func DrawVertex(
    v : Vertex,
    content : ArrayList<DotLine>
) : Unit {
    let text = if(IsDebugDot()){
        "${v.GetId()}"
    } else {
        ""
    }
    let vertexOptions = [("label", "${v.GetWidth()}"), ("xlabel", text)]
    content.append(DrawOptions("v${v.GetId()}", vertexOptions))
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
    func DrawConnectionsForArray(array : Array<Tentacle>, port : String, vertexFirst : Bool) : Unit {
        for (i in 0..array.size()) {
            let v = array[i].vertex
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
    let connectionString = if(vertexFirst) {
        "${vText}:e -- ${eText}"
    } else {
        "${eText} -- ${vText}:w"
    }
    connectionString
}
func DrawInterface1(
    id : String,
    vertices : Array<InterfaceVertex>,
    isInputs : Bool,
    elementContent : ArrayList<DotLine>
) : Unit {
    let interfaceName = "\"${id}_${ if(isInputs) { "inputs" } else { "otputs" }}\""
    DrawBoxNode(
        interfaceName,
        interfaceStyle,
        vertices,
        None<String>,
        Array<Port>(),
        elementContent
    )
}
/**
 * Append dotlines corresponding to a subgraph to lists of existing graph content.
 * A subgraph is drawn as a cluster with a box around, indicating the extend of the
 * subgraph. A small node is used to 'mount' the interfaces at the left and the right
 * of the cluster box.
 *
 * TODO: generalise sufficiently so that this can be used on the shallowest graph
 *
 * @param f The interfaced hypergraph
 * @param parent The edge that this subgraph belongs to
 * @param depth The maximum depth of subgraphs to expand
 * @param vertexMap A map indicating which vertices have been subsumed by others
 * @param expandedEdges A list of edges that have been expanded
 * @param elementContent The list of graph element dotlines so far
 * @param connectionContent The list of connection element dotlines so far
 */
func DrawInterfacedHypergraph(
    f : InterfacedHypergraph,
    parent : Option<Edge>,
    depth : Int64,
    omittedEdges : HashSet<Int64>,
    elementContent : ArrayList<DotLine>
) : Unit {
    let id = f.GetId()
    let label = f.GetLabel()
    // If there isn't a parent, declare that this is a graph
    // If there is a parent, then it is a subgraph and a cluster
    let openingText = match(parent) {
        case None => "graph \"${label}\" {"
        case Some(p) => "subgraph \"cluster_${label}_${id}\" {"
    }
    let openingLine = DotLine(openingText, Indent)
    elementContent.append(openingLine)
    // Label the (sub)graph with its name
    let labelText = "label=\"${label}\""
    let labelLine = DotLine(labelText, Preserve)
    elementContent.append(labelLine)
    // Draw the inputs
    DrawSubgraph(minSubgraphOpts, elementContent, { elementContent =>
        DrawInterface1("${id}", f.GetInputVertices(), true, elementContent)
    })
    // Draw the content of the graph
    DrawHypergraph(
        f.GetGraph(),
        depth - 1,
        omittedEdges,
        elementContent
    )
    // Draw the outputs
    DrawSubgraph(maxSubgraphOpts, elementContent, { elementContent =>
        DrawInterface1("${id}", f.GetOutputVertices(), true, elementContent)
    })
    // Wrap everything up
    let closingText = DotLine("}", Deindent)
    elementContent.append(closingText)
}
/**
 * Append dotlines corresponding to a(n uninterfaced) hypergraph to lists of
 * element and connection dotlines, expanding subgraphs up to a given depth.
 * @param f                 The hypergraph
 * @param depth             The maximum depth to expand subgraphs
 * @param omittedEdges      A set of edges that have been expanded
 * @param elementContent    The list containing the existing element dotlines so far
 * @param connectionContent The list containing the existing connection dotlines so far
 */
public func DrawHypergraph(
    f : Hypergraph,
    depth : Int64,
    omittedEdges : HashSet<Int64>,
    elementContent : ArrayList<DotLine>
) : Unit {
    let vertexOptionsString = DrawOptions("node", vertexNodeOpts)
    elementContent.append(vertexOptionsString)
    for(v in f.GetVertices()){
        DrawVertex(v, elementContent)
    }
    let edgeOptionsString = DrawOptions("node", edgeNodeOpts)
    elementContent.append(edgeOptionsString)
    for (e in f.GetEdges()){
        DrawEdge(e, depth, omittedEdges, elementContent)
    }
}
/**
 * Append dotlines for a subgraph to the list of element lines so far.
 * @param opt The array of subgraph options
 * @param subelementContent The dotlines that belong to the subgraph
 * @param elementContent The element dotlines so far
 */
func DrawSubgraph(
    opt : Array<(String, String)>,
    elementContent : ArrayList<DotLine>,
    generateSubgraphContents : (ArrayList<DotLine>) -> Unit
) : Unit {
    elementContent.append(DotLine("{", Indent))
    let opts = DrawOptions("graph", opt)
    elementContent.append(opts)
    generateSubgraphContents(elementContent)
    elementContent.append(DotLine("}", Deindent))
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
    DrawInterfacedHypergraph(
        f,
        None<Edge>,
        depth,
        HashSet<Int64>(),
        elementContent
    )
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
    println(list)
    let (output, _, _) =
        fold_left(
            { acc : (String, Int64, Bool) , dl : DotLine =>
                // (previous lines, current indent)
                let (accString, accIndent, accSameLine) = acc
                // The instruction determines the current and next indent
                let (curIndent, nextIndent, nextSameLine) = match(dl.instruction) {
                    // Indent the next line
                    case Indent => (accIndent, accIndent + 1, accSameLine)
                    // Deindent the current line
                    case Deindent => (accIndent - 1, accIndent - 1, accSameLine)
                    // Do nothing
                    case Preserve => (accIndent, accIndent, accSameLine)
                    // Toggle newlines
                    case SameLine => (
                        if(accSameLine) { accIndent - 1 } else { accIndent },
                        if(!accSameLine) { accIndent + 1 } else { accIndent - 1},
                        !accSameLine
                    )
                }
                let line = if(accSameLine) {
                    dl.str
                } else {
                    indentString(curIndent, dl.str)
                }
                // Only make a newline if this is not the first line
                let nextAcc = if(accString == "") {
                    line
                } else {
                    let newlineString = if(accSameLine){
                        ""
                    } else {
                        "\n"
                    }
                    "${accString}${newlineString}${line}"
                }
                (nextAcc, nextIndent, nextSameLine)
            },
            ("", 0, false),
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
    Info("Writing dot file ${filename}")
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