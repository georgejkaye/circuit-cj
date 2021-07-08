/**
 * structure.cj
 *
 * This file contains the base class that defines a hypergraph structure
 * There is no requirement for these to be well-formed
 */

package circuits

import debug.*

/**
 * A hypergraph structure is a collection of edges, inputs, outputs and connections
 * This structure may not necessarily be a well-formed hypergraph
 */
open class HypergraphStructure <: Identifiable {

    protected var edges    : ArrayList<Edge>
    protected var inputs   : ArrayList<Target>
    protected var outputs  : ArrayList<Source>

    protected var sourceGlobalIds : MapBuilder<UInt64, Source>
    protected var targetGlobalIds : MapBuilder<UInt64, Target>
    protected var edgeGlobalIds : MapBuilder<UInt64, Edge>

    protected var sources  : ArrayList<Source>
    protected var targets  : ArrayList<Target>

    protected var busMaps        : MapBuilder<Bus, MapBuilder<Int64, Source>>
    protected var busVertexMaps  : MapBuilder<Bus, MapBuilder<Int64, Source> * ArrayList<Source>>
    protected var busList        : ArrayList<Bus>
    protected var wireList       : ArrayList<Wire> 

    protected var inlinkMap  : MapBuilder<Link, ArrayList<Edge>>
    protected var outlinkMap : MapBuilder<Link, ArrayList<Edge>> 

    init(edges   : ArrayList<Edge>,
         inputs  : ArrayList<Target>,
         outputs : ArrayList<Source>
    )  {
        this.edges = edges
        this.inputs = inputs
        this.outputs = outputs

        this.edgeGlobalIds = MapBuilder<UInt64, Edge>()
        this.sourceGlobalIds = MapBuilder<UInt64, Source>()
        this.targetGlobalIds = MapBuilder<UInt64, Target>()

        this.sources = ArrayList<Source>()
        this.targets = ArrayList<Target>()

        this.busList = ArrayList<Bus>()
        this.wireList = ArrayList<Wire>()
        this.busMaps = MapBuilder<Bus, MapBuilder<Int64, Source>>()
        this.busVertexMaps = MapBuilder<Bus, MapBuilder<Int64, Source> * ArrayList<Source>>()

        this.inlinkMap = MapBuilder<Link, ArrayList<Edge>>()
        this.outlinkMap = MapBuilder<Link, ArrayList<Edge>>()

        SetUpHypergraph()
    }
    protected func SetUpHypergraph(){
        // Add all the inputs to the targets
        for(i in 0..inputs.size()){
            AddTarget(inputs[i]) //inputs[i], targets, targetGlobalIds)
            inputs[i].SetPort(i)
        }
        // Add all the sources and targets of edges
        for(i in 0..edges.size()){
            AddEdge(edges[i])
        }
        // Add all the outputs to the sources
        for(i in 0..outputs.size()){
            AddSource(outputs[i])
            outputs[i].SetPort(i)
        }
        // With all the buses in place, create lists containing the wires of each bus
        UpdateBusVertexList()
    }
    /**
     * Add a source to this graph and update the relevant data structures
     * @param s The source to add
     */
    protected func AddSource(s : Source){
        s.SetHypergraph(this)
        // Add to the sources list
        sources.add(s)
        sourceGlobalIds.add(s.globalId, s)
        // Update all the buses accordingly
        for(wire in s.wires){
            wireList.add(wire)
            let bus = wire.bus
            match(busMaps.get(bus)){
                case Some(ws) =>
                    ws.add(wire.i, s)
                    false
                case $None =>
                    let mb = MapBuilder<Int64, Source>()
                    mb.add(wire.i, s)
                    busMaps.add(bus, mb)
                    busList.add(bus)
                    true
            }
        }
    }
    /**
     * Add a target to this graph and update the relevant data structures
     * @param t The target to add
     */
    protected func AddTarget(t : Target){
        t.SetHypergraph(this)
        targets.add(t)
        targetGlobalIds.add(t.globalId, t)
    }
    /**
     * Add an edge and its sources and targets to this graph and update the relevant data structures
     * @param e The edge to add
     */
    protected func AddEdge(e : Edge){
        e.SetHypergraph(this)
        edgeGlobalIds.add(e.globalId, e)
        for(i in 0..e.sources.size()){
            AddSource(e.sources[i])
        }
        for(i in 0..e.targets.size()){
            AddTarget(e.targets[i])
        }
        if(IsInlink(e.generator)){

            UpdateInLinks(e)
        }
        if(IsOutlink(e.generator)){
            UpdateOutLinks(e)
        } 
    }
    /**
     * Update the structures involving buses
     */
    protected func UpdateBusVertexList(){
        for(bus in busList){
            match(busMaps.get(bus)){
                case $None => ()
                case Some(mb) =>
                    let vertexList = ArrayList<Source>()
                    let wires = bus.wires
                    for(wire in wires){
                        match(mb.get(wire.i)){
                            // Not all wires from a given bus may be in a graph
                            case $None   => ()
                            case Some(s) => let x = vertexList.add(s)
                        }
                    }
                    let x = busVertexMaps.add(bus, (mb, vertexList))
            }
        }
    }
    /** 
     * Update the inlinks map with the link of a new edge
     * Assumes the edge is a link edge
     * @param e The edge
     */
    protected func UpdateInLinks(e : Edge){
        UpdateLinks(e, inlinkMap)
    }
    /** 
     * Update the outlinks map with the link of a new edge
     * Assumes the edge is a link edge
     * @param e The edge
     */
    protected func UpdateOutLinks(e : Edge){
        UpdateLinks(e, outlinkMap)
    }
    /** 
     * Update a given links map with the link of a new edge
     * Assumes the edge is a link edge
     * @param e The edge
     */
    protected func UpdateLinks(e : Edge, linkMap : MapBuilder<Link, ArrayList<Edge>>){
        let link = e.GetLink()
        // TODO something going wrong with match
        let es : ArrayList<Edge>
        match(linkMap.get(link)){
            case Some(es2) => es = es2
            case $None =>
                let es2 = ArrayList<Edge>()
                linkMap.add(link, es2)
                es = es2
        }
        es.add(e)
    }

    func GetM() { inputs.size() }
    func GetN() { outputs.size() }
    func GetInputsWithProperty(p : (Target) -> Bool){
        let satisfyingTargets = ArrayList<Target>(inputs)
        satisfyingTargets.removeIf({t : Target => !p(t)})
        satisfyingTargets
    }
    func GetEdges(){ edges }
    func GetEdgesWithProperty(p : (Edge) -> Bool){
        let satisfyingEdges = ArrayList<Edge>(edges)
        satisfyingEdges.removeIf({e : Edge => !p(e)})
        satisfyingEdges
    }
    func GetEdgesWithGenerator(gen : Generator){
        GetEdgesWithProperty({e : Edge => e.generator == gen})
    }
    func GetGates(){
        GetEdgesWithProperty({e : Edge => e.IsGate()})
    }
    func GetAllOutLinks(){
        GetEdgesWithProperty({e : Edge => e.IsOutlink()})
    }
    func GetAllInLinks(){
        GetEdgesWithProperty({e : Edge => e.IsInlink()})
    }
    func GetAllIdentityEdges(){
        GetEdgesWithProperty({e : Edge => e.IsIdentity()})
    }
    func GetInputs() { inputs }
    func GetInput(i : Int64) { 
        if(i < 0 || i >= inputs.size()){
            throw BadInputException("GetInputs", i, inputs.size())
        }
        inputs[i] }
    func GetInputs(ins : ArrayList<Int64>){
        let chosenInputs = ArrayList<Target>(ins.size(), {i : Int64 => 
            let j = ins[i]
            if(j < 0 || j >= inputs.size()){
                throw BadInputException("GetInputs", i, inputs.size())
            }
            inputs[j]
        })
        chosenInputs
    }
    func GetOutputs() { outputs }
    func GetOutput(i : Int64) { 
        if(i < 0 || i >= outputs.size()){
            throw BadOutputException("GetOutputs", i, outputs.size())
        }
        outputs[i] 
    }
    func GetOutputs(outs : ArrayList<Int64>){
        let chosenOutputs = ArrayList<Source>(outs.size(), {i : Int64 => 
            let j = outs[i]
            if(j < 0 || j >= outputs.size()){
                throw BadOutputException("GetOutputs", i, outputs.size())
            }
            outputs[j]
        })
        chosenOutputs
    }
    func GetSources(){ sources }
    func GetTargets(){ targets }
    func GetEdgeGlobalIds(){ edgeGlobalIds }
    func GetSourceGlobalIds(){ sourceGlobalIds }
    func GetTargetGlobalIds(){ targetGlobalIds }
    func GetWires(){ wireList }
    func GetInlinkMap(){ inlinkMap }
    func GetOutlinkMap(){ outlinkMap }
    open func GetName(){ "hs${id}" }
    func GetId(){ id }
    /**
     * Does this hypergraph contain a given edge?
     * @param e the edge
     * @return Whether the edge is in this hypergraphs
     */
    func HasEdge(e : Edge){
        includes(edges, e)
    }
    /**
     * Perform an action for each edge
     * @param action The action to perform
     */
    func ForEachEdge(action : (Edge) -> Unit){
        for(e in edges){
            action(e)
        }
    }
    /**
     * Perform an action for each edge that satisfies a predicate
     * @param pred   The predicate 
     * @param action The action to perform
     */
    func ForEachEdgeWithProperty(pred : (Edge) -> Bool, action : (Edge) -> Unit){
        // TODO unknown error with for(e in edges)
        for(i in 0..edges.size()){
            let e = edges[i]
            if(pred(e)){
                action(e)
            }
        }
    }
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
    func GetWireVertexOption(w : Wire) : Option<Source> {
        // HACK because buses are a bit of a mess right now
        for(s in sources){
            if(includes(s.wires, w)){
                return Some<Source>(s)
            }
        }
        return None<Source>
    }
    /** 
     * Does this hypergraph contain a given bus?
     * @param b The name of the bus
     * @return If the bus is contained in the graph
     */
    func ContainsBus(b : String) {
        let b = GetBus(b)
        match(busVertexMaps.get(b)){
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
        match(busVertexMaps.get(b)){
            case Some(vms) => vms
            case $None => throw BusNotInGraphException("GetBusVertexMap", b)
        }
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
        match(busVertexMaps.get(b)){
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
     * Check if this hypergraph is productive
     * i.e. its output is a join of a value and a delayed circuit
     * @return Whether this circuit is in a productive form
     */
    func IsProductive() : Bool {
        for(s in outputs){
            match(s.GetLeftPort()){
                case EdgePort(e, i) =>
                    if(e.generator == JOIN){
                        let lhs = e.GetSource(0).GetLeftPort()
                        let rhs = e.GetSource(1).GetLeftPort()
                        if(!((IsValue(lhs) && IsDelay(rhs)) || (IsValue(rhs) && IsDelay(lhs)))){
                            return false
                        } 
                    } else {
                        return false
                    }
                case InterfacePort(i) => return false
            }
        }
        return true
    }
    /**
     * Perform a well-formedness check on this hypergraph
     * @return The wellformedness status of this hypergraph
     */
    func WellFormedCheck() : WellformednessStatus {
        let encounteredTargets = ArrayList<Target>()
        let encounteredTargetGlobalIds = ArrayList<UInt64>()
        for(t in targets){
            if(includes(encounteredTargets, t)){
                return DuplicateTarget(t)
            }
            if(includes(encounteredTargetGlobalIds, t.globalId)){
                return DuplicateTargetGlobalId(t.globalId)
            }
            encounteredTargets.add(t)
            encounteredTargetGlobalIds.add(t.globalId)
            if(!t.HasPort()){
                return TargetNotAssociated(t)   
            }
            if(!t.HasConn()){
                return TargetNotConnected(t)
            }
            if(!includes(sources, t.GetConn())){
                return ConnectionNotInGraph(t, t.GetConn())
            }
            match(t.GetLeftPort()){
                case EdgePort(e, i) =>
                    if(!includes(edges, e)){
                        return EdgeNotInGraph(t, e)
                    }
                    if(e.GetTarget(i) != t){
                        return IncorrectTargetAssignment(t, t.GetLeftPort())
                    }
                case InterfacePort(i) =>
                    if(i >= GetM() || GetInput(i) != t){
                        return IncorrectTargetAssignment(t, t.GetLeftPort())
                    }
            }
        }
        let encounteredSources = ArrayList<Source>()
        let encounteredSourceGlobalIds = ArrayList<UInt64>()
        for(s in sources){
            if(includes(encounteredSources, s)){
                return DuplicateSource(s)
            }
            if(includes(encounteredSourceGlobalIds, s.globalId)){
                return DuplicateSourceGlobalId(s.globalId)
            }
            encounteredSources.add(s)
            encounteredSourceGlobalIds.add(s.globalId)
            if(!s.HasPort()){
                return SourceNotAssociated(s)
            }
            if(!s.HasConn()){
                return SourceNotConnected(s)
            }
            if(!includes(targets, s.GetConn())){
                return ConnectionNotInGraph(s, s.GetConn())
            }
            match(s.GetRightPort()){
                case EdgePort(e, i) =>
                    if(!includes(edges, e)){
                        return EdgeNotInGraph(s, e)
                    }
                    if(e.GetSource(i) != s){
                        return IncorrectSourceAssignment(s, s.GetRightPort())
                    }
                case InterfacePort(i) =>
                    if(i >= GetN() || GetOutput(i) != s){
                        return IncorrectSourceAssignment(s, s.GetRightPort())
                    }
            }
        }
        let encounteredGlobalIds = ArrayList<UInt64>()
        for(e in edges){
            if(includes(encounteredGlobalIds, e.globalId)){
                return DuplicateEdgeGlobalId(e.globalId)
            }
            encounteredGlobalIds.add(e.globalId)
            if(e.sources.size() != Dom(e.generator)){
                return IncorrectDomain(e, e.sources.size())
            }
            if(e.targets.size() != Cod(e.generator)){
                return IncorrectCodomain(e, e.targets.size())
            }
        }
        return Okay
    }
    /**
     * Get a truth value representing whether this hypergraph is well formed
     * @return A tuple of whether the hypergraph is well formed and the well formed status
     */
    func IsWellFormed(){
        let wf = WellFormedCheck()
        match(wf){
            case $Okay => (true, wf)
            case _     => (false, wf)
        }
    }
    open func GetString() {
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
extend HypergraphStructure <: ToString {
    func toString(){
        this.GetString()
    }
}
/** 
 * An enum to represent if a hypergraph structure is well formed or if there is a problem with it
 */
enum WellformednessStatus {
    | Okay                                    // Well formed hypergraph
    | TargetNotConnected(Target)              // This target does not connect to a source vertex
    | SourceNotConnected(Source)              // This source does not connect to a target vertex
    | TargetNotAssociated(Target)             // This target is not associated with an edge
    | SourceNotAssociated(Source)             // This source is not associated with an edge
    | IncorrectTargetAssignment(Target, Port) // This target has been assigned to a port but in reality it is not
    | IncorrectSourceAssignment(Source, Port) // This source has been assigned to a port but in reality it is not
    | DuplicateTarget(Target)                 // This target is associated with multiple edges
    | DuplicateSource(Source)                 // This source is associated with multiple edges
    | DuplicateTargetGlobalId(UInt64)         // This target global id is used multiple times in this graph
    | DuplicateSourceGlobalId(UInt64)         // This source global id is used multiple times in this graph
    | DuplicateEdgeGlobalId(UInt64)           // This edge global id is used multiple times in this graph
    | ConnectionNotInGraph(Vertex, Vertex)    // The connection of the first vertex is not in the graph
    | EdgeNotInGraph(Vertex, Edge)            // This vertex is associated with an edge not in this graph
    | IncorrectDomain(Edge, Int64)            // This edge has the incorrect number of sources
    | IncorrectCodomain(Edge, Int64)          // This edge has the incorrect number of targets
}

extend WellformednessStatus <: ToString {
    func toString(){
        match(this){
            case TargetNotConnected(t)           => "Target ${t} not connected"
            case SourceNotConnected(s)           => "Source ${s} not connected"
            case TargetNotAssociated(t)          => "Target ${t} not associated"
            case SourceNotAssociated(s)          => "Source ${s} not associated"
            case IncorrectTargetAssignment(t, p) => "Incorrect target assignment of ${t} to ${p}"
            case IncorrectSourceAssignment(s, p) => "Incorrect source assignment of ${s} to ${p}"
            case DuplicateTarget(t)              => "Duplicated target ${t}"
            case DuplicateSource(s)              => "Duplicated source ${s}"
            case DuplicateTargetGlobalId(i)      => "Duplicate target global id ${i}"
            case DuplicateSourceGlobalId(i)      => "Duplicate source global id ${i}"
            case DuplicateEdgeGlobalId(i)        => "Duplicate edge global id ${i}"
            case ConnectionNotInGraph(v1,v2)     => "Connection of ${v1} which is ${v2} not in the graph"
            case EdgeNotInGraph(v, e)            => "The edge of vertex ${v} which is ${e} not in the graph"
            case IncorrectDomain(e, n)           => "Incorrect domain of ${e}"
            case IncorrectCodomain(e, n)         => "Incorrect codomain of ${e}"
            case $Okay                           => "All okay"
        }
    }
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
        match(this.WellFormedCheck()){
            case $Okay => () 
            case wf    =>
                throw BadHypergraphException(this, wf)
        }
    }
    /**
     * Get the name of this hypergraph
     * @return the name
     */
    override func GetName() { name }
    func Overwrite(hb : HypBuilder){
        edges = ArrayList<Edge>()
        inputs = ArrayList<Target>()
        outputs = ArrayList<Source>()
        sources = ArrayList<Source>()
        targets = ArrayList<Target>()
        sourceGlobalIds = MapBuilder<UInt64, Source>()
        targetGlobalIds = MapBuilder<UInt64, Target>()
        edgeGlobalIds = MapBuilder<UInt64, Edge>()
        edges.addAll(hb.GetEdges())
        inputs.addAll(hb.GetInputs())
        outputs.addAll(hb.GetOutputs())
        SetUpHypergraph()
    }
    /**
     * Create a deep clone of this hypergraph for future manipulation
     * @return A HypBuilder with deep copies of all elements in this hypergraph
     */
    func Clone(deep!: Bool = false) {
        let cr = Cloner(this, deep)
        let newEdges = ArrayList<Edge>()
        var newInputs = ArrayList<Target>(inputs.size(), {i : Int64 => CloneTarget(cr, inputs[i])})
        var newOutputs = ArrayList<Source>(outputs.size(), {i : Int64 => CloneSource(cr, outputs[i])})
        for(e in edges){
            let newSources = ArrayList<Source>(e.sources.size(), {i : Int64 => CloneSource(cr, e.sources[i])})
            let newTargets = ArrayList<Target>(e.targets.size(), {i : Int64 => CloneTarget(cr, e.targets[i])})
            let newEdge = if(deep){
                Edge(e.generator, newSources, newTargets)
            } else {
                Edge(e.globalId, e.generator, newSources, newTargets)
            }
            newEdges.add(newEdge)
        }
        let hb = HypBuilder(newEdges, newInputs, newOutputs)
        hb
    }
    /**
     * Get this hypergraph with just the nth output exposed
     * @param n The index of the output to expose
     * @return The hypergraph with the given output exposed
     */
    func Get(n : Int64){
        Get(this, n)
    }
    /**
     * Get this hypergraph with just a list of outputs exposed
     * @param ns The list of indices of outputs to expose
     * @return The hypergraph with the given outputs exposed
     */
    func Get(ns : List<Int64>){
        Get(this, ArrayList<Int64>(ns))
    }
    /**
     * Get this hypergraph with just the bus exposed
     * @param bus The name of the bus to expose
     * @return The hypergraph with the given bus exposed
     */
    func Get(bus : String){
        Get(this, bus)
    }
    /**
     * Get this hypergraph with the nth output stubbed
     * @param n The index of the output to stub
     * @return The hypergraph with the given output stubbed
     */
    func Drop(n : Int64){
        Drop(this, n)
    }
    /**
     * Seqentially compose this hypergraph with another
     * @param g The hypergraph to compose with this one
     * @return The result of the sequential composition
     */
    func Seq(g : Hypergraph){
        Seq(this, g)
    }
    /**
     * Compose this hypergraph with another in parallel
     * @param g The hypergraph to compose with this one
     * @return The result of the parallel composition
     */
    func Par(g : Hypergraph){
        Par(this, g)
    }
    /** 
     * Trace this hypergraph with n wires
     * @param n The number of wires to trace
     * @return The hypergraph traced with n wires
     */
    func Tr(n : Int64){
        Trace(this, n)
    }
    /**
     * Feed back all outputs to a given link
     * This modifies all hypergraphs containing the corresponding link: we traverse back from the current outputs of 
     * this graph and add everything that contributes to this link, effectively adding the future to these graphs
     * @param link The link to feedback to
     * @param output If the original outputs should be preserved as well as fed back
     * @param index The particular index to feed back, None means all
     * @return The graph with feedback
     */
    func Feedback(link : Link, output!: Bool = false, index!: Option<Int64> = None<Int64>){
        Debug("Feedback", "Feeding back all outputs to ${link}")
        let width = match(index){
            case Some(i) => 1
            case $None   => GetN()
        } 
        if(link.width != width){
            throw BadCodomainException("Feedback", GetN(), width)
        }
        let inEdges = ArrayList<Edge>(link.inEdges)
        let doneGraphs = ArrayList<UInt64>()
        let linked = this.Clone()
        match(index){
            case Some(i) => 
                if(output){
                    let link = linked.CreateEdge(OUTLINK(link))
                    let s = linked.GetOutput(i)
                    linked.InjectFork(s, link.GetSource(0))
                    ()
                } else {
                    linked.ConnectOutputToEdge(i, OUTLINK(link))
                    ()
                }
            case $None => 
                if(output){
                    let link = linked.CreateEdge(OUTLINK(link))
                    for(i in 0..linked.GetN()){
                        let s = linked.GetOutput(i)
                        linked.InjectFork(s, link.GetSource(i))
                    }
                    ()
                } else {
                    linked.ConnectOutputsToEdge(OUTLINK(link))
                    ()
                }
        }
        let g = linked.ToGraph()
        for(e in inEdges){
            let f = match(e.GetHypergraph()){
                case f : Hypergraph => f
                case _              => break
            }
            if(!includes(doneGraphs, f.GetId())){
                doneGraphs.add(f.GetId())
                // We need to add everything the links depend on to the original graph
                let newf = AddMissingGraph(f.Clone(), g.Clone())
                // Add in the new bits to the original f
                f.Overwrite(newf)
            }
        }
        g
    }
    /**
     * Feed back all outputs to a given link, but preserve the original outputs as well
     * This corresponds to the classic iteration pattern
     * This modifies all graphs that contain this link
     * @param link The link to feed back to
     * @return The graph with the feedback and outputs
     */
    func FeedbackAndOutput(link : Link){
        Feedback(link, output: true)
    }
    /**
     * Feed back a particular output to a given link
     * This modifies all graphs that contain this link
     * @param i The index of the output to feed back
     * @param link The link to feed back to
     * @return The graph with one output fed back
     */
    func Feedback(i : Int64, link : Link){
        Feedback(link, index: Some(i))
    }
     /**
     * Feed back a particular output to a given link, but preserve the original output as well
     * This corresponds to the classic iteration pattern
     * This modifies all graphs that contain this link
     * @param link The link to feed back to
     * @return The graph with the feedback and outputs
     */
    func FeedbackAndOutput(i : Int64, link : Link){
        Feedback(link, output: true, index: Some(i))
    }
    /**
     * Syntax sugar for sequential composition
     * @param f The lhs of the sequential composition
     * @param g The rhs of the sequential composition
     * @return The result of the sequential composition
     */
    operator func +(g : Hypergraph) : Hypergraph {
        SeqBuilder(this.Clone(), g.Clone())
    }
    /**
     * Syntax sugar for parallel composition
     * @param f The lhs of the parallel composition
     * @param g The rhs of the parallel composition
     * @return The result of the parallel composition
     */
    operator func *(g : Hypergraph) : Hypergraph {
        ParBuilder(this.Clone(), g.Clone())
    }
    /**
     * Syntax sugar for composing n copies of a hypergraph in parallel
     * @param f The lhs of the parallel composition
     * @param g The rhs of the parallel composition
     * @return The result of the parallel composition
     */
    operator func ^(n : Int64) : Hypergraph {
        ParBuilder(this, n)
    }
    /**
     * Syntax sugar for getting the nth output of a hypergraph
     * @param n The index of the output to preserve
     * @return The hypergraph with all outputs except the nth stubbed off
     */
    operator func [](n : Int64){
        GetBuilder(this.Clone(), n)
    }  
    /**
     * Syntax sugar for getting a given bus from a hypergraph
     * @param bus The bus to extract
     * @return The hypergraph with the given bus extracted
     */
    operator func [](bus : String){
        GetBuilder(this.Clone(), bus)
    }
    /**
    * Get a rewriter for this hypergraph
    * @return The rewritied for this hypergraph
    */
    func GetRewriter(){
        Rewriter(this)
    }

    override func GetString() : String {
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
    var sourceMap : MapBuilder<Source, Source> = MapBuilder<Source, Source>()
    var targetMap : MapBuilder<Target, Target> = MapBuilder<Target, Target>()
    init(original : Hypergraph, deep : Bool){
        this.original = original
        for(s in original.GetSources()){
            let newS = if(deep){
                Source(ArrayList<Wire>(s.wires))
            } else {
                Source(s.globalId, ArrayList<Wire>(s.wires))
            }
            sourceMap = sourceMap.add(s, newS)    
        }
        for(t in original.GetTargets()){
            let newT = if(deep){
                Target()
            } else {
                Target(t.globalId)
            }
            targetMap = targetMap.add(t, newT)
        }
    }
    /**
     * Get the cloned source that corresponds to an original source
     * @param s The original source
     * @return The cloned source
     */
    func GetNewSource(s : Source){
        match(sourceMap.get(s)){
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
        match(targetMap.get(t)){
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
/**
 * Alias for circuits
 * TODO find out why this doesn't compile
 */
// type Circuit = Hypergraph

func main(){
    SetDotDir("dot")

    // let circ = Delay()
    // WriteDotToFile(circ, "delay")

    // let circ2 = Register(width: 1, initial: 0)
    // WriteDotToFile(circ2, "reg")

    // let wf = WaveformFromList([0,1,2,3], width: 2)
    // WriteDotToFile(wf, "wf")

    // let iwf = InfiniteWaveform(2, width: 2)
    // WriteDotToFile(iwf, "iwf")

    //let v1 = UnsignedValueFromInt(6, width: 4)
    //let v2 = SignedValueFromInt(-6, width: 4)
    //WriteDotToFile(v1, "v1")
    //WriteDotToFile(v2, "v2")

    let a = Input()
    let b = Input()
    let sum = XorGate(a, b)
    let carry = AndGate(a, b)
    Concat([sum, carry])
    //let circ = sum * carry
    //WriteDotToFile(circ, "circ")

    //let cpu = SimpleCPU()
    //WriteDotToFile(cpu, "cpu", resolve: false)

    0   
}