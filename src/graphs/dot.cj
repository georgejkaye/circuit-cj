/**
 * graphs/dot.cj
 *
 * Functions for generating dot graphs for hypergraphs
 *
 * @author George Kaye
 * @since 0.1
 */
package graphs
/**
 * Get the options for the entire graph. If debug is enabled then the graph
 * will have a grey background so the debug info can show up.
 *
 * @param debug
 * @return The options for the entire graph
 */
func GetGraphOpts(debug : Bool) : Array<(String, String)> {
    [
        ("rankdir", "LR"),
        ("bgcolor", if(debug) { "gray" } else { "white" })
    ]
}
/**
 * Style options for edge nodes
 */
let edgeNodeOpts = [
    ("shape", "plaintext"),
    ("fillcolor", "white"),
    ("fixedsize", "false"),
    ("fontcolor", "black")
]
/**
 * Style options for vertex nodes
 */
let vertexNodeOpts = [
    ("shape", "circle"),
    ("style", "filled"),
    ("fillcolor", "black"),
    ("height", "0.25"),
    ("fixedsize", "true"),
    ("fontcolor", "white")
]
/**
 * Height of a source or target port box on an edge
 */
let portHeight = 5
/**
 * Width of a source or target port box on an edge
 */
let portWidth = 5
/**
 * Get a background colour option.
 *
 * @param colour
 * @return The option ("bgcolor", colour)
 */
func bgColour(colour : String) : (String, String) {
    ("bgcolor", colour)
}
/**
 * The style for interface boxes
 */
let interfaceStyle = [
    bgColour("gray")
]
/**
 * The style for bundle boxes
 */
let bundleStyle = [
    bgColour("red")
]
/**
 * The style for primitive boxes
 */
let primitiveStyle = [
    bgColour("cyan")
]
/**
 * The style for composite boxes containing only combinational components
 */
let combinationalCompositeStyle = [
    bgColour("darkturquoise")
]
/**
 * The style for composite boxes containing sequential components
 */
let sequentialCompositeStyle = [
    bgColour("chartreuse4")
]
/**
 * The style for join boxes
 */
let joinStyle = [
    bgColour("violet"),
    ("width", "10")
]
/**
 * The style for delay boxes
 */
let delayStyle = [
    bgColour("yellow")
]
/**
 * The style for value or signal boxes representing entirely disconnected values
 */
let bottomStyle = [
    bgColour("aquamarine")
]
/**
 * The style for value boxes
 */
let valueStyle = [
    bgColour("darkolivegreen1")
]
/**
 * The style for signal boxes
 */
let signalStyle = [
    bgColour("green")
]
/**
 * The style for register boxes
 */
let registerStyle = [
    bgColour("yellowgreen")
]
/**
 * The style for open waveform boxes
 */
let openWaveformStyle = [
    bgColour("forestgreen")
]
/**
 * The style for closed waveform boxes
 */
let closedWaveformStyle = [
    bgColour("mediumseagreen")
]
/**
 * The style for infinite waveform boxes
 */
let infiniteWaveformStyle = [
    bgColour("lightseagreen")
]
/**
 * The style for blackboxes
 */
let blackboxStyle = [
    bgColour("white")
]
/**
 * The options for subgraphs that should be drawn as right as possible
 */
let maxSubgraphOpts = [
    ("rank", "max")
]
/**
 * The options for subgraphs that should be drawn as left as possible
 */
let minSubgraphOpts = [
    ("rank", "min")
]
/**
 * The options for feedback tentacles
 */
let feedbackStyle = [
    ("color", "red")
]
/**
 * Enum to give indentation instructions for the generated dot code.
 */
public enum IndentInstruction {
    | Preserve      // Keep the current indentation
    | Indent        // Indent one more starting from the next line
    | Deindent      // Indent one fewer starting from this line
    | SameLine      // Indent and toggle inline mode
}
/**
 * Record for storing a line of dot code along with a relevant
 * indentation instruction
 */
public struct DotLine {
    public DotLine(
        let str : String,
        let instruction : IndentInstruction
    ){}
}
/**
 * Create a string of the form "key1=val1 key2=val2 ... keyn=valn" for a given
 * array of key-value pairs, for use as options in an HTML element
 *
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
    let opener = DotLine(
        "<${tag}${optionStringSpaced}>",
        if(inline) { SameLine } else { Indent }
    )
    elementContent.append(opener)
    // Generate the dotlines for the content inside this element
    generateElemContents(elementContent, false)
    // Add the closing html tag
    let closer = DotLine(
        "</${tag}>",
        if(inline) { SameLine } else { Deindent }
    )
    elementContent.append(closer)
}
/**
 * Get a string of options in selector[key=val, key1=val1...] format
 *
 * @param selector The selector to apply the options to
 * @param opts The list of key-value pairs of options
 * @return The key-value string of the options
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
/**
 * Create a dotline of options
 *
 * @param selector The selector to apply the options to
 * @param opts The list of key-value pairs of options
 * @return The options dotline
 */
func DrawOptions(selector : String, opts : Array<(String, String)>) : DotLine {
    let options = GetOptions(opts)
    DotLine("${selector}${options}", Preserve)
}
/**
 * Convert an array of source or target ports into an HTML table in which each
 * cell contains the name of the port, if present, and the width of the port.
 * These ports can be used as the ports of a parent HTML node.
 *
 * @param ports The array of ports
 * @param id The id string of the parent edge
 * @param elementContent The element content arraylist to fill
 */
func MakePorts<T>(
    ports : Array<T>,
    prefix : String,
    elementContent : ArrayList<DotLine>
) : Unit where T <: HasPort {
    // The ports are contained in a cell in the single row box node
    MakeElem("td", [], elementContent, false, {elementContent, inline =>
        // The ports are a vertical table of table cells
        MakeElem("table", [], elementContent, false, {elementContent, inline =>
            for (i in 0..ports.size) {
                // Make a row for each port
                MakeElem("tr", [], elementContent, true,
                    {elementContent, inline =>
                        let portStyle =  [
                            ("height", "${portHeight}"),
                            ("width", "${portWidth}"),
                            ("port", "${prefix}${i}")
                        ]
                        // Make a single cell in each row for each port
                        MakeElem("td", portStyle, elementContent, false,
                            {elementContent, inline =>
                                let port = ports[i]
                                // The port contains the port name (if given)
                                // and the width of the port
                                let portText = match(port.GetName()){
                                    case None =>
                                        "${port.GetWidth()}"
                                    case Some(str) =>
                                        "${str}:${port.GetWidth()}"
                                }
                                elementContent.append(
                                    DotLine(portText, Preserve)
                                )
                            }
                        )
                    }
                )
            }
        })
    })
}
/**
 * Append dotlines for a subgraph to the list of element lines so far.
 *
 * @param opt The array of subgraph options
 * @param subelementContent The dotlines that belong to the subgraph
 * @param elementContent The element dotlines so far
 */
func DrawSubgraph(
    opt : Array<(String, String)>,
    elementContent : ArrayList<DotLine>,
    connectionContent : ArrayList<DotLine>,
    generateSubgraphContents : (ArrayList<DotLine>, ArrayList<DotLine>) -> Unit
) : Unit {
    elementContent.append(DotLine("{", Indent))
    let opts = DrawOptions("graph", opt)
    elementContent.append(opts)
    generateSubgraphContents(elementContent, connectionContent)
    elementContent.append(DotLine("}", Deindent))
}
/** Width of a tab */
let tab = "    "
/**
* Indent a string by a given number of tabs.
*
* @param n The number of tabs to indent by
* @param str The string to indent
* @return The indented string
*/
func indentString(n : Int64, str : String) : String {
    var tabs = ""
    for (_ in 0..n) {
        tabs = "${tabs}${tab}"
    }
    "${tabs}${str}"
}
/**
* Convert a list of dotlines to a string with appropriate newlines
* and indentation.
*
* @param list The arraylist of dotlines
* @return The corresponding dot code
*/
public func ConvertStringIndentListToString(
    list : ArrayList<DotLine>
) : String {
    let (output, _, _) =
        fold_left(
            { acc : (String, Int64, Bool) , dl : DotLine =>
                // (previous lines, current indent)
                let (accString, accIndent, accSameLine) = acc
                // The instruction determines the current and next indent
                let (curIndent, nextIndent, nextSameLine) =
                    match(dl.instruction) {
                        // Indent the next line
                        case Indent =>
                            (accIndent, accIndent + 1, accSameLine)
                        // Deindent the current line
                        case Deindent =>
                            (accIndent - 1, accIndent - 1, accSameLine)
                        // Do nothing
                        case Preserve =>
                            (accIndent, accIndent, accSameLine)
                        // Toggle newlines
                        case SameLine =>
                            let nextIndent = if(accSameLine) {
                                accIndent - 1
                            } else {
                                accIndent
                            }
                            let nextSameLine = if(!accSameLine) {
                                accIndent + 1
                            } else {
                                accIndent - 1
                            }
                            (nextIndent, nextSameLine, !accSameLine)
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
 * Append dotlines for an edge to a list of content dotlines
 * @param e The edge
 * @param content The list of dotlines to append to
 */
func DrawEdgeNode<V, G>(
    e : Edge<V, G>,elementContent : ArrayList<DotLine>,
    connectionContent : ArrayList<DotLine>,
    edgeLabelFn: (Label<V, G>) -> String, debug : Bool
) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let style = match(e.GetLabel()){
        case VALUE(v) =>
            if(v == V.GetDisconnected()) {
                bottomStyle
            } else {
                valueStyle
            }
        case SIGNAL(spec) =>
            if(spec.IsAll(V.GetDisconnected())) {
                bottomStyle
            } else {
                signalStyle
            }
        case REGISTER(_) =>
            registerStyle
        case OPEN_WAVEFORM(_) =>
            openWaveformStyle
        case CLOSED_WAVEFORM(_) =>
            closedWaveformStyle
        case INFINITE_WAVEFORM(_) =>
            infiniteWaveformStyle
        case BUNDLER(_,_) =>
            bundleStyle
        case JOIN(_) =>
            joinStyle
        case PRIMITIVE(_) =>
            primitiveStyle
        case ENHANCED_PRIMITIVE(eprim) =>
            combinationalCompositeStyle
        case COMPOSITE(_) =>
            if(e.GetSubgraph().getOrThrow().IsCombinational()) {
                combinationalCompositeStyle
            } else {
                sequentialCompositeStyle
            }
        case BLACKBOX(_) =>
            blackboxStyle
        case DELAY(_) =>
            delayStyle
    }
    let edgeLabelText = edgeLabelFn(e.GetLabel())
    DrawBoxNode(
        "e${e.GetId()}", style, e.GetSources(), e.GetInputPorts(),
        edgeLabelText, e.GetTargets(), e.GetOutputPorts(),
        elementContent, connectionContent, debug
    )
}
/**
 * Draw a box node (normally used to represent a hyperedge) which may have
 * sources, targets and a label.
 *
 * @param id The id of the edge
 * @param style The style to apply to this node
 * @param leftVertices The tentacles to connect to the left ports of the node
 * @param leftPorts The details of the left ports
 * @param label The optional label to put in the middle of the node
 * @param rightVertices The tentacles to connect to the right ports of the node
 * @param rightPorts The details of the right ports
 * @param elementContent The element content list
 * @param connectionContent The connection content list
 */
func DrawBoxNode<V, G, T1, U1, T2, U2>(
    id : String, style : Array<(String, String)>, leftVertices : Array<T1>,
    leftPorts : Array<U1>, label : Option<String>, rightVertices : Array<T2>,
    rightPorts : Array<U2>, elementContent : ArrayList<DotLine>,
    connectionContent : ArrayList<DotLine>, debug : Bool
) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T1 <: ContainsVertex<V, G>, T2 <: ContainsVertex<V, G>,
        U1 <: HasPort, U2 <: HasPort
{
    // Add the edge identifier
    let declaration = DotLine("${id} [label=<", Indent)
    elementContent.append(declaration)
    // Make the main table of the node
    MakeElem("table", style, elementContent, false, {elementContent, inline =>
        // There is one row in the node
        MakeElem("tr", [], elementContent, false, {elementContent, inline =>
            // Draw left ports, if there are any
            if(leftVertices.size > 0) {
                MakePorts(leftPorts, "w", elementContent)
            }
            // Draw the label, if there is one
            match(label) {
                case None => ()
                case Some(s) => MakeElem("td", [], elementContent, true,
                    {elementContent, inline =>
                        let text = if(debug){
                            "${id}: ${s}"
                        } else {
                            s
                        }
                        elementContent.append(DotLine(text, Preserve))
                    }
                )
            }
            // Draw right ports, if there are any
            if(rightVertices.size > 0) {
                MakePorts(rightPorts, "e", elementContent)
            }
        })
    })
    // Wrap everything up
    let conclusion = DotLine(">];", Deindent)
    elementContent.append(conclusion)
}
/**
 * Draw the connections from the sources and targets from a parent edge to
 * the interfaces of the subgraph.
 *
 * @param g The subgraph
 * @param parentVertices The sources or targets of the parent edge
 * @param vertexType The type of vertex
 * @param connectionContent The list of connection content
 */
func DrawSubgraphInterfaceConnections<V, G>(
    e : Edge<V, G>,
    g : InterfacedHypergraph<V, G>,
    parentVertices : Array<Vertex<V, G>>,
    vertexType : VertexType,
    connectionContent : ArrayList<DotLine>
) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    for(i in 0..parentVertices.size) {
        let v = parentVertices[i]
        let (interfaceText, portPrefix, vertexFirst, feedback) =
            match(vertexType) {
                case SOURCE =>
                    ("inputs", "e", true, v.GetGraph().IsFeedback(e, i))
                case TARGET =>
                    ("outputs", "w", false, false)
            }
        let eText = "\"${g.GetId()}_${interfaceText}\":${portPrefix}${i}"
        DrawConnection(
            v, eText, vertexFirst, connectionContent, feedback
        )
    }
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
func DrawEdge<V, G>(
    e : Edge<V, G>, depth : Int64, omittedEdges : HashSet<Int64>,
    elementContent : ArrayList<DotLine>, connectionContent : ArrayList<DotLine>,
    edgeLabelFn : (Label<V, G>) -> String, debug : Bool, expandSignals : Bool
) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let label = e.GetLabel()
    if (depth != 0 && label.IsExpandable(expandSignals: expandSignals)) {
        match (e.GetSubgraph()) {
            case None => DrawEdgeNode(
                e, elementContent, connectionContent, edgeLabelFn, debug
            )
            case Some(g) =>
                omittedEdges.put(e.GetId())
                DrawInterfacedHypergraph(
                    g, e, depth - 1, omittedEdges, elementContent, edgeLabelFn,
                    debug, expandSignals
                )
                DrawSubgraphInterfaceConnections(
                    e, g, e.GetSources(), SOURCE, connectionContent
                )
                DrawSubgraphInterfaceConnections(
                    e, g, e.GetTargets(), TARGET, connectionContent
                )
        }
    } else {
        DrawEdgeNode(e, elementContent, connectionContent, edgeLabelFn, debug)
    }
}
/**
 * Append the dotline for a vertex to a list
 * @param v The vertex
 * @param content The list of dotlines to append to
 * @param vertexMap A map sending vertices to vertices that have subsumed it
 */
func DrawVertex<V, G>(
    v : Vertex<V, G>, content : ArrayList<DotLine>, debug : Bool
) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let text = if(debug){
        "${v.GetId()}"
    } else {
        ""
    }
    let vertexOptions = [("label", "${v.GetWidth()}"), ("xlabel", text)]
    content.append(DrawOptions("v${v.GetId()}", vertexOptions))
}
/**
 * Get the connection text for a connection between a vertex and an edge
 *
 * @param vText The name of the vertex
 * @param eText The name of the edge
 * @param vertexFirst Whether the connection is from vertex to edge (i.e.
                        target) or vice versa (i.e. source)
 * @return The connection string
 */
func DrawConnection<V, G, T>(
    vertex : T, eText : String, vertexFirst : Bool,
    connectionContent : ArrayList<DotLine>, feedback : Bool
) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: ContainsVertex<V, G>
{
    let vText = "v${vertex.GetVertex().GetId()}"
    let connectionString = if(vertexFirst) {
        "${vText}:e -- ${eText}:w"
    } else {
        "${eText}:e -- ${vText}:w"
    }
    let fullConnectionString = if(feedback){
        "${connectionString} ${GetOptions(feedbackStyle)}"
    } else {
        connectionString
    }
    connectionContent.append(DotLine(fullConnectionString, Preserve))
}
/**
 * Draw an interface for a graph: a grey box with ports labelled by a width
 * and a name, if the latter is provided
 *
 * @param The id of the graph the interface is being made for
 * @param vertices The array of interface vertices that make up the interface
 * @param isInputs Whether this is an input interface
 * @param elementContent The list of element dot lines
 * @param connectionContent The list of connection dot lines
 */
func DrawInterface<V, G>(
    id : String,
    vertices : Array<InterfaceVertex<V, G>>,
    isInputs : Bool,
    elementContent : ArrayList<DotLine>,
    connectionContent : ArrayList<DotLine>,
    debug : Bool
) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let interfaceName =
        "\"${id}_${ if(isInputs) { "inputs" } else { "outputs" }}\""
    let (leftVertices, rightVertices) = if(isInputs) {
        (Array<InterfaceVertex<V, G>>(), vertices)
    } else {
        (vertices, Array<InterfaceVertex<V, G>>())
    }
    DrawBoxNode(
        interfaceName, interfaceStyle, leftVertices, leftVertices, None<String>,
        rightVertices, rightVertices, elementContent, connectionContent, debug
    )
    for(i in 0..vertices.size) {
        let v = vertices[i]
        let port = if(isInputs) { "e" } else { "w" }
        let eText = "${interfaceName}:${port}${i}"
        DrawConnection(v, eText, !isInputs, connectionContent, false)
    }
}
/**
 * Get the dot lines for beginning a graph. If this graph has a parent,
 * it will be denoted as a subgraph cluster; otherwise it will be an ordinary
 * graph.
 *
 * @param label The name of the graph
 * @param parent The optional parent edge
 * @param elementContent the list of element dotlines
 */
func DrawOpeningContent<V, G>(
    label : String, parent : Option<Edge<V, G>>,
    elementContent : ArrayList<DotLine>, debug : Bool
) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    // If there isn't a parent, declare that this is a graph
    // If there is a parent, then it is a subgraph and a cluster
    let (openingText, fullLabel) =
        match(parent) {
            case None =>
                ("graph \"${label}\" {", "${label}")
            case Some(p) =>
                let labelText = if(debug) {
                    "$e${p.GetId()}: ${label}"
                } else {
                    "${label}"
                }
                (
                    "subgraph \"cluster_${label}_${p.GetId()}\" {",
                    labelText
                )
        }
    let openingLine = DotLine(openingText, Indent)
    elementContent.append(openingLine)
    let graphOptions = "graph${GetOptions(GetGraphOpts(debug))}"
    elementContent.append(DotLine(graphOptions, Preserve))
    // Label the (sub)graph with its name
    let labelText = "label=\"${fullLabel}\""
    let labelLine = DotLine(labelText, Preserve)
    elementContent.append(labelLine)
}
/**
 * Get the closing content for a dot graph.
 *
 * @param elementContent The list of element dotlines
 */
func DrawClosingContent(
    elementContent : ArrayList<DotLine>
) : Unit {
    let closingText = DotLine("}", Deindent)
    elementContent.append(closingText)
}
/**
 * Draw the interfaces of an interfaced hypergraph as grey boxes,
 * labelled with the widths, and the port names if appropriate.
 *
 * @param f The interfaced hypergraph
 * @param elementContent The element dotlines
 * @param connectionContent The connection dotlines
 */
func DrawInterfaces<V, G>(
    f : InterfacedHypergraph<V, G>,
    elementContent : ArrayList<DotLine>,
    connectionContent : ArrayList<DotLine>,
    debug : Bool
) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    // Draw the inputs
    if(f.GetArity() > 0) {
        DrawSubgraph(
            minSubgraphOpts, elementContent, connectionContent,
            { elementContent, connectionContent =>
                DrawInterface(
                    "${f.GetId()}", f.GetInputs(), true,
                    elementContent, connectionContent, debug
                )
        })
    }
    // Draw the outputs
    if(f.GetCoarity() > 0){
        DrawSubgraph(
            maxSubgraphOpts, elementContent, connectionContent,
            { elementContent, connectionContent =>
                DrawInterface(
                    "${f.GetId()}", f.GetOutputs(), false,
                    elementContent, connectionContent, debug
                )
        })
    }
}
/**
 * Append dotlines corresponding to a subgraph to lists of existing graph content.
 * A subgraph is drawn as a cluster with a box around, indicating the extend of the
 * subgraph. A small node is used to 'mount' the interfaces at the left and the right
 * of the cluster box.
 *
 * @param f The interfaced hypergraph
 * @param parent The edge that this subgraph belongs to
 * @param depth The maximum depth of subgraphs to expand
 * @param vertexMap A map indicating which vertices have been subsumed by others
 * @param expandedEdges A list of edges that have been expanded
 * @param elementContent The list of graph element dotlines so far
 * @param connectionContent The list of connection element dotlines so far
 */
func DrawInterfacedHypergraph<V, G>(
    f : InterfacedHypergraph<V, G>,
    parent : Option<Edge<V, G>>,
    depth : Int64,
    omittedEdges : HashSet<Int64>,
    elementContent : ArrayList<DotLine>,
    edgeLabelFn : (Label<V, G>) -> String,
    debug : Bool, expandSignals : Bool
) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let id = f.GetId()
    let label = f.GetLabel()
    DrawOpeningContent(edgeLabelFn(label), parent, elementContent, debug)
    // The connections of this graph are kept within this graph
    let connectionContent = ArrayList<DotLine>()
    // Draw the content of the graph
    DrawHypergraph(
        f.GetGraph(), depth, omittedEdges, elementContent,
        connectionContent, edgeLabelFn, debug, expandSignals
    )
    // Draw the interfaces of this graph
    DrawInterfaces(f, elementContent, connectionContent, debug)
    // All the connections can now be written
    elementContent.appendAll(connectionContent)
    // Wrap everything up
    DrawClosingContent(elementContent)
}
/**
 * Append dotlines corresponding to a(n uninterfaced) hypergraph to lists of
 * element and connection dotlines, expanding subgraphs up to a given depth.
 * @param f                 The hypergraph
 * @param depth             The maximum depth to expand subgraphs
 * @param omittedEdges      A set of edges that have been expanded
 * @param elementContent    The list containing the element dotlines so far
 * @param connectionContent The list containing the connection dotlines so far
 */
public func DrawHypergraph<V, G>(
    f : Hypergraph<V, G>,
    depth : Int64,
    omittedEdges : HashSet<Int64>,
    elementContent : ArrayList<DotLine>,
    connectionContent : ArrayList<DotLine>,
    edgeLabelFn : (Label<V, G>) -> String,
    debug : Bool, expandSignals: Bool
) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let vertexOptionsString = DrawOptions("node", vertexNodeOpts)
    elementContent.append(vertexOptionsString)
    for(v in f.GetVertices()){
        DrawVertex(v, elementContent, debug)
        func ShouldDrawConnection(ec : EdgeConnection<V, G>) : Bool {
            depth == 0 || !ec.GetEdge().HasSubgraph() ||
                !ec.GetEdge().GetLabel().IsExpandable(
                    expandSignals: expandSignals
                )
        }
        func GetEdgeText(ec : EdgeConnection<V, G>) : String {
            let portText = match(ec.GetVertexType()) {
                case SOURCE => "w"
                case TARGET => "e"
            }
            "e${ec.GetEdge().GetId()}:${portText}${ec.GetIndex()}"
        }
        // Draw the connections to targets
        match(v.GetInEdge()) {
            case Some(ec) =>
                if(ShouldDrawConnection(ec)) {
                    let eText = GetEdgeText(ec)
                    DrawConnection(v, eText, false, connectionContent, false)
                }
            case None => ()
        }
        // Draw the connections to sources
        for(ec in v.GetOutEdges()) {
            if(ShouldDrawConnection(ec)) {
                let eText = GetEdgeText(ec)
                let isFeedback =
                    f.IsFeedback(ec.GetEdge(), ec.GetIndex())
                DrawConnection(v, eText, true, connectionContent, isFeedback)
            }
        }
    }
    let edgeOptionsString = DrawOptions("node", edgeNodeOpts)
    elementContent.append(edgeOptionsString)
    for (e in f.GetEdges()){
        DrawEdge(
            e, depth, omittedEdges, elementContent, connectionContent,
            edgeLabelFn, debug, expandSignals
        )
    }
}
func WriteDotFile(
    fileName : String, dotString : String
) : Unit {
    let fs = File("${fileName}.dot", CreateOrTruncate(false))
    Info("Writing dot file ${fileName}.dot")
    fs.write(dotString.toUtf8Array())
    fs.close()
}
/**
 * Interface for things that can generate dot code.
 */
public interface HasDot<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    func GetDotString(
        depth: Int64, edgeLabelFn: (Label<V, G>) -> String,
        debug: Bool, expandSignals: Bool
    ) : String
}
/**
 * Write an object's dot code to a file.
 *
 * @param f The drawer
 * @param fileName
 * @param edgeLabelFn
 * @param debug
 * @param expandSignals
 */
func WriteDotToFile<V, G, T>(
    f : T, fileName: String, depth: Int64,
    edgeLabelFn : (Label<V, G>) -> String, debug: Bool,
    expandSignals: Bool
) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>, T <: HasDot<V, G>
{
    let dotString = f.GetDotString(depth, edgeLabelFn, debug, expandSignals)
    WriteDotFile(fileName, dotString)
}
/**
 * Write an object's dot code to a file, labelling edges with their label names.
 *
 * @param f The drawer
 * @param fileName
 * @param depth
 * @param debug
 * @param expandSignals
 */
 func WriteDotToFile<V, G, T>(
    f : T, fileName: String, depth: Int64, debug: Bool,
    expandSignals: Bool
) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>, T <: HasDot<V, G>
{
    WriteDotToFile(
        f, fileName, depth, { l => l.GetName() }, debug, expandSignals
    )
}
/**
 * Write an object's dot code to a file, labelling signal edges with their
 * decimal representations.
 *
 * @param f The drawer
 * @param fileName
 * @param depth
 * @param signed
 * @param debug
 * @param expandSignals
 */
func WriteDotToFile<V, G, T>(
    f : T, fileName: String, depth: Int64, signed: Bool,
    debug: Bool, expandSignals: Bool
) : Unit
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>,
            T <: HasDot<V, G>
{
    WriteDotToFile(
        f, fileName, depth, { l => l.GetDecimalName(signed: signed) },
        debug, expandSignals
    )
}
extend Hypergraph<V, G> <: HasDot<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    public func GetDotString(
        depth: Int64, edgeLabelFn: (Label<V, G>) -> String,
        debug: Bool, expandSignals: Bool
    ) : String {
        let dotLines = ArrayList<DotLine>()
        let connectionContent = ArrayList<DotLine>()
        DrawOpeningContent("", None<Edge<V, G>>, dotLines, debug)
        DrawHypergraph(
            this, depth, HashSet(), dotLines, connectionContent, edgeLabelFn,
            debug, expandSignals
        )
        dotLines.appendAll(connectionContent)
        DrawClosingContent(dotLines)
        ConvertStringIndentListToString(dotLines)
    }
}
extend InterfacedHypergraph<V, G> <: HasDot<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    public func GetDotString(
        depth: Int64, edgeLabelFn: (Label<V, G>) -> String,
        debug: Bool, expandSignals: Bool
    ) : String {
        let elementContent = ArrayList<DotLine>()
        DrawInterfacedHypergraph(
            this, None<Edge<V, G>>, depth, HashSet<Int64>(), elementContent,
            edgeLabelFn, debug, expandSignals
        )
        ConvertStringIndentListToString(elementContent)
    }
}
/**
 * Interface for things that can be drawn as dot graphs
 */
public interface Drawable<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    /**
     * Write the dot graph for a graph to a file with a given name.
     *
     * @param file The file name to write to
     * @param depth The maximum depth of subgraphs to draw
     * @param debug Whether to print debug info on the graph
     * @param expandSignals Whether to expand signal and waveform subgraphs
     */
    func WriteDotToFile(
        file : String, depth!: Int64, debug!: Bool, expandSignals!: Bool
    ) : Unit
}
extend InterfacedHypergraph<V, G> <: Drawable<V, G> {
    public func WriteDotToFile(
        file: String, depth!: Int64 = 0, debug!: Bool = false,
        expandSignals!: Bool = false
    ) : Unit {
        WriteDotToFile(this, file, depth, debug, expandSignals)
    }
}
extend Hypergraph<V, G> <: Drawable<V, G> {
    public func WriteDotToFile(
        file: String, depth!: Int64 = 0, debug!: Bool = false,
        expandSignals!: Bool = false
    ) : Unit {
        WriteDotToFile(this, file, depth, debug, expandSignals)
    }
}
/**
 * Interface for things that have corresponding dot graphs and can be
 * represented in decimal.
 */
public interface DecimalDrawable {
    /**
     * Write the dot graph for a graph to a file with a given name, with the
     * option to toggle representing signals as decimal numbers.
     * @param depth The maximum depth of subgraphs to draw
     * @param file The file name to write to
     * @param signed Whether to interpret signals as signed or not
     * @param debug Whether to print debug info on the graph
     */
    func WriteDotToFile(
        file : String, depth!: Int64, signed!: Bool, debug!: Bool,
        expandSignals!: Bool
    ) : Unit
}
extend Hypergraph<V, G> <: DecimalDrawable
    where V <: Decimal<V> & ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    public func WriteDotToFile(
        file : String, depth!: Int64 = 0, signed!: Bool, debug!: Bool = false,
        expandSignals!: Bool = false
    ) : Unit {
        WriteDotToFile(
            this, file, depth, signed, debug, expandSignals
        )
    }
}
extend InterfacedHypergraph<V, G> <: DecimalDrawable
    where V <: Decimal<V> & ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    public func WriteDotToFile(
        file : String, depth!: Int64 = 0, signed!: Bool, debug!: Bool = false,
        expandSignals!: Bool = false
    ) : Unit {
        WriteDotToFile(
            this, file, depth, signed, debug, expandSignals
        )
    }
}