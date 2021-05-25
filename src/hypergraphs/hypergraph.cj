/**
 * structure.cj
 *
 * This file contains the base class that defines a hypergraph structure
 * There is no requirement for these to be well-formed
 */

package hypergraphs

import debug.*

func AddTarget(t : Target, targets : ArrayList<Target>){
    // Add to the targets list
    targets.add(t)
}

func AddSource(s : Source, sources : ArrayList<Source>, busMaps : MapBuilder<Bus, MapBuilder<Int64, Source>>, busList : ArrayList<Bus>, wireList : ArrayList<Wire>){
    // Add to the sources list
    sources.add(s)
    // Update all the buses accordingly
    for(wire in s.wires){
        wireList.add(wire)
        let bus = wire.bus
        match(busMaps.toMap().get(bus)){
            case Some(ws) => {
                ws.add(wire.i, s)
                false
            }
            case $None => {
                let mb = MapBuilder<Int64, Source>()
                mb.add(wire.i, s)
                busMaps.add(bus, mb)
                busList.add(bus)
                true
            }
        }
    }
}

func UpdateBusVertexList(busList : ArrayList<Bus>, busMaps : MapBuilder<Bus, MapBuilder<Int64, Source>>, busVertexMaps : MapBuilder<Bus, MapBuilder<Int64, Source> * ArrayList<Source>>){
    for(bus in busList){
        match(busMaps.toMap().get(bus)){
            case $None => {}
            case Some(mb) => {
                let vertexList = ArrayList<Source>()
                let wires = bus.wires
                for(wire in wires){
                    match(mb.toMap().get(wire.i)){
                        // Not all wires from a given bus may be in a graph
                        case $None   => {}
                        case Some(s) => vertexList.add(s)
                    }
                }
                let x = busVertexMaps.add(bus, (mb, vertexList))
            }
        }
    }
}

/**
 * A hypergraph structure is a collection of edges, inputs, outputs and connections
 * This structure may not necessarily be a well-formed hypergraph
 */
open class HypergraphStructure <: Atom {
    protected var edges    : ArrayList<Edge>
    protected var inputs   : ArrayList<Target>
    protected var outputs  : ArrayList<Source>

    protected let sources  : ArrayList<Source>
    protected let targets  : ArrayList<Target>

    protected let busMaps        : MapBuilder<Bus, MapBuilder<Int64, Source>>
    protected var busVertexMaps  : MapBuilder<Bus, MapBuilder<Int64, Source> * ArrayList<Source>>
    protected let busList        : ArrayList<Bus>
    protected let wireList       : ArrayList<Wire> 

    init(edges   : ArrayList<Edge>,
         inputs  : ArrayList<Target>,
         outputs : ArrayList<Source>
    )  {
        this.edges = edges
        this.inputs = inputs
        this.outputs = outputs

        this.sources = ArrayList<Source>()
        this.targets = ArrayList<Target>()

        this.busList = ArrayList<Bus>()
        this.wireList = ArrayList<Wire>()
        this.busMaps = MapBuilder<Bus, MapBuilder<Int64, Source>>()
        this.busVertexMaps = MapBuilder<Bus, MapBuilder<Int64, Source> * ArrayList<Source>>()

        // Add all the inputs to the targets
        for(i in 0..inputs.size()){
            AddTarget(inputs[i], targets)
            inputs[i].SetPort(i)
    }
        // Add all the sources and targets of edges
        for(e in edges){
            for(i in 0..e.sources.size()){
                AddSource(e.sources[i], sources, busMaps, busList, wireList)
            }
            for(i in 0..e.targets.size()){
                AddTarget(e.targets[i], targets)
            }
        }
        // Add all the outputs to the sources
        for(i in 0..outputs.size()){
            AddSource(outputs[i], sources, busMaps, busList, wireList)
            outputs[i].SetPort(i)
        }
        // With all the buses in place, create lists containing the wires of each bus
        UpdateBusVertexList(busList, busMaps, busVertexMaps)
    }
    
    func GetM() { inputs.size() }
    func GetN() { outputs.size() }
    func GetEdges(){ edges }
    func GetInputs() { inputs }
    func GetInput(i : Int64) { inputs[i] }
    func GetOutputs() { outputs }
    func GetOutput(i : Int64) { outputs[i] }
    func GetSources(){ sources }
    func GetTargets(){ targets }
    func GetWires(){ wireList }
    
    open func GetName(){ "hs${id}" }

    /**
     * Get the vertex that corresponds to this wire, or throw an exception if it doesn't exist
     * @param w The wire
     * @return The vertex that corresponds to this wire
     */
    func GetWireVertex(w : Wire) { 
        match(GetWireVertexOption(w)){
            case Some(v) => v
            case $None   => throw WireNotInGraphException("GetWireVertex", w)
        }
    }   
    /**
     * Get an option containing either the vertex that corresponds to this wire, or None
     * @param w The wire
     * @return Some(vertex) if it exists in this graph, or None otherwise
     */
    func GetWireVertexOption(w : Wire){
        match(busVertexMaps.toMap().get(w.bus)){
             case Some((mb, vs)) => {
                 mb.toMap().get(w.i)
             }
             case $None    => None<Source>
        }
    }
    /** 
     * Does this hypergraph contain a given bus?
     * @param b The name of the bus
     * @return If the bus is contained in the graph
     */
    func ContainsBus(b : String) {
        let b = GetBus(b)
        match(busVertexMaps.toMap().get(b)){
            case Some(x) => return true
            case $None   => return false
        }
    }
    /**
     * Get the index-vertex map of vertices belonging to a given bus 
     * @param s The bus
     * @return  The index-vertex map of vertices belonging to this bus
     */  
    func GetBusVertexMap(b : Bus){
        busVertexMaps.toMap().get(b)
    }
    /**
     * Get the index-vertex map of vertices belonging to a given bus 
     * @param s The name of the bus
     * @return  The index-vertex map of vertices belonging to this bus
     */  
    func GetBusVertexMap(s : String) {
        let b = GetBus(s)
        GetBusVertexMap(b)
    }
    /**
     * Get the list of vertices belonging to a given bus and append them to an existing list
     * @param b  The bus
     * @param vs The list of vertices to append to
     * @return The list of vertices that belong to this bus
     */
    func GetBusVertexList(b : Bus, vs : ArrayList<Source>){
        match(busVertexMaps.toMap().get(b)){
            case Some((mb, ss)) => vs.addAll(ss)
            case $None          => throw BusNotInGraphException("GetBusVertexList", b)
        }
    }
    /**
     * Get the list of vertices belonging to a given bus and append them to an existing list
     * @param s  The name of the bus
     * @param vs The list of vertices to append to
     * @return The list of vertices that belong to this bus
     */
    func GetBusVertexList(s : String, vs : ArrayList<Source>){
        let b = GetBus(s)
        GetBusVertexList(b, vs)
    }
    /**
     * Get the list of vertices belonging to a given bus 
     * @param b The bus
     * @return The list of vertices that belong to this bus
     */
    func GetBusVertexList(b : Bus){
        let vs = ArrayList<Source>()
        GetBusVertexList(b, vs)
        vs
    }
    /**
     * Get the list of vertices belonging to a given bus 
     * @param s The name of the bus
     * @return The list of vertices that belong to this bus
     */
    func GetBusVertexList(s : String){
        let vs = ArrayList<Source>()
        GetBusVertexList(s, vs)
        vs
    }
    /**
     * Is this hypergraph structure a well formed hypergraph?
     * @return The wellformedness status of this hypergraph
     */
    func IsWellFormed(){
        Debug("IsWellFormed", "Checking if graph is well formed")
        let encounteredTargets = ArrayList<Target>()
        for(t in targets){
            if(includes(encounteredTargets, t)){
                return DuplicateTarget(t)
            }
            encounteredTargets.add(t)
            if(!t.HasPort()){
                return TargetNotAssociated(t)   
            }
            if(!t.HasConn()){
                return TargetNotConnected(t)
            }
            if(!includes(sources, t.GetConn())){
                return ConnectionNotInGraph(t, t.GetConn())
            }
        }
        let encounteredSources = ArrayList<Source>()
        for(s in sources){
            if(includes(encounteredSources, s)){
                return DuplicateSource(s)
            }
            encounteredSources.add(s)
            if(!s.HasPort()){
                return SourceNotAssociated(s)
            }
            if(!s.HasConn()){
                return SourceNotConnected(s)
            }
            if(!includes(targets, s.GetConn())){
                return ConnectionNotInGraph(s, s.GetConn())
            }
        }
        for(e in edges){
            if(e.sources.size() != Dom(e.generator)){
                return IncorrectDomain(e, e.sources.size())
            }
            if(e.targets.size() != Cod(e.generator)){
                return IncorrectCodomain(e, e.targets.size())
            }
        }
        return Okay
    }
    open override func toString() {
        let sourceString = PrintList(sources, {s : Source => "${s.id}"})
        let targetString = PrintList(targets, {t : Target => "${t.id}"})
        var edgeString = ""
        let inputString = PrintList(inputs, {t : Target => "${t.id}"})
        for(e in edges){
            let edgeSources = SourceListToString(e.sources)
            let edgeTargets = TargetListToString(e.targets)
            edgeString = "${edgeString}e${e.id} - ${e.generator} ${edgeSources} ${edgeTargets}\n"
        }
        let outputString = PrintList(outputs, {s : Source => "${s.id}"})
        var connsRString = ""
        var leftString = ""
        for(t in targets){
            let s = if(t.HasConn()){
                "${t.GetConn().id}"
            } else {
                "?"
            }
            connsRString = "${connsRString}(${t.id} ${s}) "
            let ps = if(t.HasPort()){
                match(t.GetPort()){
                    case EdgePort(e, i)   => "${e.id}[${i}]"
                    case InterfacePort(i) => "in[${i}]"
                }
            } else {
                "?"
            }
            leftString = "${leftString}(${t.id} ${ps}) "
        }
        var connsLString = ""
        var rightString = ""
        for(s in sources){
            let t = if(s.HasConn()){
                "${s.GetConn().id}"
            } else {
                "?"
            }
            connsLString = "${connsLString}(${s.id} ${t}) "
            let ps = if(s.HasPort()){
                match(s.GetPort()){
                    case EdgePort(e, i)   => "${e.id}[${i}]"
                    case InterfacePort(i) => "out[${i}]"
                }
            } else {
                "?"
            }
            rightString = "${rightString}(${s.id} ${ps}) "
        }
        "====\nsources ${sourceString}\ntargets ${targetString}\ninputs ${inputString}\n${edgeString}outputs ${outputString}\nconnsr ${connsRString}\nconnsl ${connsLString}\nlefts ${leftString}\nrights ${rightString}\n===="
    }
}

/** 
 * An enum to represent if a hypergraph structure is well formed or if there is a problem with it
 */
enum WellformednessStatus {
    | Okay                                  // Well formed hypergraph
    | TargetNotConnected(Target)            // This target does not connect to a source vertex
    | SourceNotConnected(Source)            // This source does not connect to a target vertex
    | TargetNotAssociated(Target)           // This target is not associated with an edge
    | SourceNotAssociated(Source)           // This source is not associated with an edge
    | DuplicateTarget(Target)               // This target is associated with multiple edges
    | DuplicateSource(Source)               // This source is associated with multiple edges
    | ConnectionNotInGraph(Vertex, Vertex)  // The connection of the first vertex is not in the graph
    | IncorrectDomain(Edge, Int64)          // This edge has the incorrect number of sources
    | IncorrectCodomain(Edge, Int64)        // This edge has the incorrect number of targets
}

/**
 * Hypergraph definition
 * All objects of this class *must* be well-formed
 */
external class Hypergraph <: HypergraphStructure {
    private let name : String
   
    init(edges    : ArrayList<Edge>, 
         inputs   : ArrayList<Target>,
         outputs  : ArrayList<Source>
    ) {
         this("", edges, inputs, outputs)
    }

    init(name    : String,
         edges   : List<Edge>, 
         inputs  : List<Target>, 
         outputs : List<Source>
    ){
        this(name, ArrayList<Edge>(edges), ArrayList<Target>(inputs), ArrayList<Source>(outputs))
    }

    init(name     : String,
         edges    : ArrayList<Edge>, 
         inputs   : ArrayList<Target>,
         outputs  : ArrayList<Source>
    ){
        super(edges, inputs, outputs)
        this.name = if(name == ""){ "h${this.id}" } else { name }
        match(IsWellFormed()){
            case $Okay => {}
            case wf    => throw BadHypergraphException(this, wf)
        }
    }
    /**
     * Get the name of this hypergraph
     * @return the name
     */
    override func GetName() { name }
    /**
     * Create a deep clone of this hypergraph for future manipulation
     * @return A HypBuilder with deep copies of all elements in this hypergraph
     */
    func Clone() {
        let cr = Cloner(this)
        let newEdges = ArrayList<Edge>()
        var newInputs = ArrayList<Target>(inputs.size(), {i : Int64 => CloneTarget(cr, inputs[i])})
        var newOutputs = ArrayList<Source>(outputs.size(), {i : Int64 => CloneSource(cr, outputs[i])})
        for(e in edges){
            let newSources = ArrayList<Source>(e.sources.size(), {i : Int64 => CloneSource(cr, e.sources[i])})
            let newTargets = ArrayList<Target>(e.targets.size(), {i : Int64 => CloneTarget(cr, e.targets[i])})
            let newEdge = Edge(e.generator, newSources, newTargets)
            newEdges.add(newEdge)
        }
        let hb = HypBuilder(newEdges, newInputs, newOutputs)
        hb
    }
    /**
    * Syntax sugar for sequential composition
    * @param g The rhs of the sequential composition
    * @return The result of the sequential composition
    */
    operator func *(f : Hypergraph, g : Hypergraph) : Hypergraph {
        Debug("Seq", "Composing ${f.GetName()} and ${g.GetName()} in sequence")
        Seq(f.Clone(), g.Clone())
    }

    /**
     * Syntax sugar for parallel composition
     * @param g The rhs of the parallel composition
     * @return The result of the parallel composition
     */
    operator func +(f : Hypergraph, g : Hypergraph) : Hypergraph {
        Debug("Par", "Composing ${f.GetName()} and ${g.GetName()} in parallel")
        Par(f.Clone(), g.Clone())
    }
    /**
     * Syntax sugar for getting the nth output of a hypergraph
     * @param n The index of the output to preserve
     * @return The hypergraph with all outputs except the nth stubbed off
     */
    operator func [](f : Hypergraph, n : Int64){
        Get(f.Clone(), n)
    }  
    /**
     * Syntax sugar for getting a given bus from a hypergraph
     * @param bus The bus to extract
     * @return The hypergraph with the given bus extracted
     */
    operator func [](f : Hypergraph, bus : String){
        Get(f.Clone(), bus)
    }
    override func toString() : String {
        var str = ""
        let inputString = "inputs ${TargetListToString(inputs)}"
        for (e in edges) {
            let id = "e${e.id}"
            let gen = "${e.generator}"
            let sourceString = SourceListToString(e.sources)
            let targetString = TargetListToString(e.targets)
            str = "${str}${id} (${gen}) ${sourceString} ${targetString}\n"
        }
        let outputString = "outputs ${SourceListToString(outputs)}"
        var connstr = "connections "
        for (t in targets) {
           connstr = "${connstr}(${t.id} ${t.GetConn().id}) "
        }
        "${name}\n${inputString}\n${str}${outputString}\n${connstr}"
    }
}
/**
 * Cloner class: used to keep track of the correspondence between original and cloned atoms
 */
class Cloner {
    let original : Hypergraph
    let sourceMap : MapBuilder<Source, Source> = MapBuilder<Source, Source>()
    let targetMap : MapBuilder<Target, Target> = MapBuilder<Target, Target>()
    init(original : Hypergraph){
        this.original = original
        for(s in original.GetSources()){
            let newS = Source(ArrayList<Wire>(s.wires))
            sourceMap.add(s, newS)    
        }
        for(t in original.GetTargets()){
            let newT = Target()
            targetMap.add(t, newT)
        }
    }
    /**
     * Get the cloned source that corresponds to an original source
     * @param s The original source
     * @return The cloned source
     */
    func GetNewSource(s : Source){
        match(sourceMap.toMap().get(s)){
            case $None => throw VertexNotInGraphException("GetNewSource", s)
            case Some(s1) => s1
        }
    }
    /**
     * Get the cloned target that corresponds to an original target
     * @param s The original target
     * @return The cloned target
     */
    func GetNewTarget(t : Target){
        match(targetMap.toMap().get(t)){
            case $None => throw VertexNotInGraphException("GetNewTarget", t)
            case Some(t1) => t1
        }
    }
}
/**
 * Get the newly cloned source for a given source
 * @param cr  the cloner to use
 * @param s   the source vertex to get the corresponding clone of
 * @return the clone of the source
 */
func CloneSource(cr : Cloner, s : Source){
    cr.GetNewSource(s)
}
/**
 * Get the newly cloned target for a given target
 * @param cr  the cloner to use
 * @param t   the target vertex to get the corresponding clone of
 * @return the clone of the target
 */
func CloneTarget(cr : Cloner, t : Target){
    let newT = cr.GetNewTarget(t)
    let oldConn = t.GetConn()
    newT.SetConn(cr.GetNewSource(oldConn))
    newT
}