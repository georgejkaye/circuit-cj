/**
 * structure.cj
 *
 * This file contains the base class that defines a hypergraph structure
 * There is no requirement for these to be well-formed
 */

package hypergraphs

import debug.*

func AddTarget(t : Target, p : Port, targets : ArrayList<Target>, lefts : MapBuilder<Target, Port>, connsr : MapBuilder<Target, Source>, connsl : MapBuilder<Source, Target>){
    // Add to the targets list
    targets.add(t)
    // Add the target and its port to the lefts map
    lefts.add(t, p)
    // Use the connsr map to define the connsl map of sources to targets
    // If the source doesn't exist, we just ignore it
    match(connsr.toMap().get(t)){
        case Some(s) => let x = connsl.add(s, t)
        case $None => {}
    }
    (targets, lefts, connsl)
}

func AddSource(s : Source, p : Port, 
               sources : ArrayList<Source>, 
               rights : MapBuilder<Source, Port>,
               busMaps : MapBuilder<Bus, MapBuilder<Int64, Source>>,
               busList : ArrayList<Bus>,
               wireList : ArrayList<Wire>
){
    // Add to the sources list
    sources.add(s)
    // Add the source and its port to the rights map
    rights.add(s, p)
    // Update all the buses accordingly
    for(wire in s.wires){
        wireList.add(wire)
        let bus = wire.bus
        match(busMaps.toMap().get(bus)){
            case Some(ws) => {
                let x = ws.add(wire.i, s)
            }
            case $None => {
                let mb = MapBuilder<Int64, Source>()
                mb.add(wire.i, s)
                busMaps.add(bus, mb)
                let x = busList.add(bus)
            }
        }
    }

    (sources, rights, busMaps, busList, wireList)
}

open class HypergraphStructure <: Atom {
    protected var edges    : ArrayList<Edge>
    protected var inputs   : ArrayList<Target>
    protected var outputs  : ArrayList<Source>
    protected var connsr   : MapBuilder<Target, Source>
    protected var connsl   : MapBuilder<Source, Target>
 
    protected var m        : Int64
    protected var n        : Int64

    protected var sources  : ArrayList<Source>
    protected var targets  : ArrayList<Target>
    protected var lefts    : MapBuilder<Target, Port>
    protected var rights   : MapBuilder<Source, Port>

    protected var busVertexMaps  : MapBuilder<Bus, MapBuilder<Int64, Source> * ArrayList<Source>>
    protected var busList        : ArrayList<Bus>
    protected var wireList       : ArrayList<Wire> 

    init(edges   : ArrayList<Edge>,
         inputs  : ArrayList<Target>,
         outputs : ArrayList<Source>,
         conns   : MapBuilder<Target, Source>
    )  {
        this.edges = edges
        this.inputs = inputs
        this.outputs = outputs
        this.connsr = conns
        this.connsl = MapBuilder<Source, Target>()

        this.m = inputs.size()
        this.n = outputs.size()

        this.sources = ArrayList<Source>()
        this.targets = ArrayList<Target>()
        this.lefts = MapBuilder<Target, Port>()
        this.rights = MapBuilder<Source, Port>()

        this.busList = ArrayList<Bus>()
        this.wireList = ArrayList<Wire>()
        this.busVertexMaps = MapBuilder<Bus, MapBuilder<Int64, Source> * ArrayList<Source>>()

        var busMaps = MapBuilder<Bus, MapBuilder<Int64, Source>>()

        // Add all the inputs to the targets
        for(i in 0..inputs.size()){
            (targets, lefts, connsl) = AddTarget(inputs[i], InterfacePort(i), targets, lefts, connsr, connsl)
        }
        // Add all the sources and targets of edges
        for(e in edges){
            for(i in 0..e.sources.size()){
                (sources, rights, busMaps, busList, wireList) = AddSource(e.sources[i], EdgePort(e, i), sources, rights, busMaps, busList, wireList)
            }
            for(i in 0..e.targets.size()){
                (targets, lefts, connsl) = AddTarget(e.targets[i], EdgePort(e, i), targets, lefts, connsr, connsl)
            }
        }
        // Add all the outputs to the sources
        for(i in 0..outputs.size()){
            (sources, rights, busMaps, busList, wireList) = AddSource(outputs[i], InterfacePort(i), sources, rights, busMaps, busList, wireList)
        }
        // With all the buses in place, create lists containing the wires of each bus
        for(bus in busList){
            match(busMaps.toMap().get(bus)){
                // This shouldn't happen
                case $None    => throw InaccessibleCodeException("Hypergraph")
                case Some(mb) => {
                    let vertexList = ArrayList<Source>()
                    let wires = bus.wires
                    for(wire in wires){
                        let v = match(mb.toMap().get(wire.i)){
                            // This shouldn't happen
                            case $None   => throw InaccessibleCodeException("Hypergraph")
                            case Some(s) => s
                        }
                        vertexList.add(v)
                    }
                    busVertexMaps.add(bus, (mb, vertexList))
                }
            }
        }
    }
    
    func GetM() { m }
    func GetN() { n }
    func GetEdges(){ edges }
    func GetInputs() {inputs }
    func GetOutputs() { outputs }
    func GetConnsR(){ connsr }
    func GetSources(){ sources }
    func GetTargets(){ targets }
    func GetWires(){ wireList }
    
    /**
     * Get the corresponding target for a source, or None if connection not present
     * @param s The source
     * @return The corresponding target, or None
     */
    func GetConnLOpt(s : Source){
        connsl.toMap().get(s)
    }
    /**
     * Get the corresponding source for a target, or None if connection not present
     * @param t The target
     * @return The corresponding source, or None
     */
    func GetConnROpt(t : Target){
        connsr.toMap().get(t)
    }
    func GetConnR(t : Target) {
       match(connsr.toMap().get(t)){
           case Some(s) => s
           case $None   => throw MissingConnectionException("GetConnR", t)
       }
    }
    func GetConnL(s : Source) {
        match(connsl.toMap().get(s)){
           case Some(t) => t
           case $None   => throw MissingConnectionException("GetConnL", s)
       }
    }
    func GetEdge(s : Source) { 
        match(rights.get(s)){
            case $None => throw VertexNotInGraphException("GetEdge (source)", s)
            case Some(p) => p 
        }
    }
    func GetEdge(t : Target) { 
        match(lefts.get(t)){
            case $None => throw VertexNotInGraphException("GetEdge (target)", t)
            case Some(p) => p
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
    func GetWireVertexOption(w : Wire){
        match(busVertexMaps.get(w.bus)){
             case Some((mb, vs)) => mb.toMap().get(w.i)
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
        busVertexMaps.get(b)
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
        vs
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
    }
    /**
     * Get the list of vertices belonging to a given bus 
     * @param s The name of the bus
     * @return The list of vertices that belong to this bus
     */
    func GetBusVertexList(s : String){
        let vs = ArrayList<Source>()
        GetBusVertexList(s, vs)
    }
        /** Follow the path from a target vertex to find its successor edge 
        * @param target The vertex to traverse from
        * @return The port reached by following this target
        */
    func NextEdge(target : Target){
        GetEdge(GetConnR(target))
    }
    /**
        * Follow the path from the ith target of an edge to find its successor edge
        * @param edge The edge to traverse from
        * @param i    The index of the target
        * @return The port reached by following this target.
        */
    func NextEdge(edge : Edge, i : Int64){
        if(i < 0 || i >= edge.targets.size()){
            throw BadTargetsException("NextEdge", edge, i)
        }
        NextEdge(edge.targets[i])
    }
    /** Follow the path from a source vertex to find its predecessor edge 
        * @param source The vertex to traverse from
        * @return The port reached by following this target
        */
    func PreviousEdge(source : Source){
        GetEdge(GetConnL(source))
    }
    /**
        * Follow the path from the ith source of an edge to find its predecessor edge
        * @param edge The edge to traverse from
        * @param i    The index of the source
        * @return The port reached by following this source.
        */
    func PreviousEdge(edge : Edge, i : Int64){
        if(i < 0 || i >= edge.sources.size()){
            throw BadSourcesException("NextEdge", edge, i)
        }
        PreviousEdge(edge.sources[i])
    }
    func IsWellFormed(){
        for(t in targets){
            match(GetConnROpt(t)){
                case Some(s) => {}
                case $None   => return TargetNotConnected(t)
            }
        }
        for(s in sources){
            match(GetConnLOpt(s)){
                case Some(t) => {}
                case $None   => return SourceNotConnected(s)
            }
        }
        return Okay
    }
}

append HypergraphStructure with ToString {
    func toString(f : HypergraphStructure) {
        var edgeString = ""
        let inputString = PrintList(f.GetInputs(), {t : Target => "${t.id}"})
        for(e in f.GetEdges()){
            let edgeSources = PrintList(e.sources, {s : Source => "${s.id}"})
            let edgeTargets = PrintList(e.targets, {t : Target => "${t.id}"})
            edgeString = "${edgeString}e${e.id} - ${e.generator}\n  sources ${edgeSources}\n  targets ${edgeTargets}\n"
        }
        let outputString = PrintList(f.GetOutputs(), {s : Source => "${s.id}"})
        var connsRString = ""
        for(t in f.GetTargets()){
            let s = match(f.GetConnROpt(t)){
                case Some(s) => "${s.id}"
                case $None    => "?"
            }
            connsRString = "${connsRString}(${t.id} ${s}) "
        }
        var connsLString = ""
        for(s in f.GetSources()){
            let t = match(f.GetConnLOpt(s)){
                case Some(t) => "${t.id}"
                case $None    => "?"
            }
            connsLString = "${connsLString}(${s.id} ${t}) "
        }
        "====\ninputs ${inputString}\n${edgeString}outputs ${outputString}\nconnsr ${connsRString}\nconnsl ${connsLString}\n===="
    }
}

enum WellformednessStatus {
    | Okay
    | TargetNotConnected(Target)
    | SourceNotConnected(Source)
}

external class Hypergraph <: HypergraphStructure {
    private let name : String
   
    init(edges    : ArrayList<Edge>, 
         inputs   : ArrayList<Target>,
         outputs  : ArrayList<Source>,
         conns    : MapBuilder<Target, Source>
    ) {
         this("", edges, inputs, outputs, conns)
    }

    init(name    : String,
         edges   : List<Edge>, 
         inputs  : List<Target>, 
         outputs : List<Source>, 
         conns   : MapBuilder<Target,Source>
    ){
        this(name, ArrayList<Edge>(edges), ArrayList<Target>(inputs), ArrayList<Source>(outputs), conns)
    }

    init(name     : String,
         edges    : ArrayList<Edge>, 
         inputs   : ArrayList<Target>,
         outputs  : ArrayList<Source>,
         conns    : MapBuilder<Target, Source>
    ){
        super(edges, inputs, outputs, conns)
        this.name = if(name == ""){ "h${this.id}" } else { name }
        match(IsWellFormed()){
            case TargetNotConnected(t) => throw BadHypergraphException("Hypergraph", this, t)
            case SourceNotConnected(s) => throw BadHypergraphException("Hypergraph", this, s)
            case $Okay => {}
        }
    }
    /**
     * Get the name of this hypergraph
     * @returns the name
     */
    func GetName() { name }
    /**
     * Create a deep clone of this hypergraph for future manipulation
     * @return A HypBuilder with deep copies of all elements in this hypergraph
     */
    func Clone() {

        let cr = Cloner(sources, targets)
        let newEdges = ArrayList<Edge>()
        var newInputs = ArrayList<Target>()
        var newOutputs = ArrayList<Source>()
        var newConns = MapBuilder<Target, Source>()

        for(t1 in inputs){
            (targets, newConns) = CloneTarget(t1, cr, newInputs, connsr, newConns)
        }
        for(e in edges){
            var sources = ArrayList<Source>()
            var targets = ArrayList<Target>()
            for(s1 in e.sources){
                sources = CloneSource(s1, cr, sources)
            }
            for(t1 in e.targets){
                (targets, newConns) = CloneTarget(t1, cr, targets, connsr, newConns)
            }
        }
        for(s1 in outputs){
            sources = CloneSource(s1, cr, newOutputs)
        }
        HypBuilder(newEdges, newInputs, newOutputs, newConns)
    }
}
func CloneSource(s1 : Source, cr : Cloner, sources : ArrayList<Source>){
    let s2 = cr.GetNewSource(s1)
    sources.add(s2)
    sources
}
func CloneTarget(t1 : Target, cr : Cloner, targets : ArrayList<Target>, connsr : MapBuilder<Target, Source>, newConns : MapBuilder<Target, Source>){
    let t2 = cr.GetNewTarget(t1)
    targets.add(t2)
    // Update the conns map while we're here
    let s1 = match(connsr.toMap().get(t1)){
        case Some(s2) => s2
        case $None    => throw VertexNotInGraphException("CloneTarget", t1)
    }
    let s2 = cr.GetNewSource(s1)
    newConns.add(t2, s2)
    (targets, newConns)
}

append Hypergraph with ToString {
    func toString(f : Hypergraph) : String {
        var str = ""
        let inputString = "inputs ${TargetListToString(f.GetInputs())}"
        for (e in f.GetEdges()) {
            let id = "e${e.id}"
            let gen = "${e.generator}"
            let sourceString = SourceListToString(e.sources)
            let targetString = TargetListToString(e.targets)
            str = "${str}${id} (${gen}) ${sourceString} ${targetString}\n"
        }
        let outputString = "outputs ${SourceListToString(f.GetOutputs())}"
        var connstr = "connections "
        for (t in f.GetTargets()) {
           connstr = "${connstr}(${t.id} ${f.GetConnR(t).id}) "
        }
        "${f.GetName()}\n${inputString}\n${str}${outputString}\n${connstr}"
    }
}

class Cloner {
    let sourceMap : MapBuilder<Source, Source> = MapBuilder<Source, Source>()
    let targetMap : MapBuilder<Target, Target> = MapBuilder<Target, Target>()
    init(sources : ArrayList<Source>, targets : ArrayList<Target>){
        for(s in sources){
            sourceMap.add(s, Source(ArrayList<Wire>(s.wires)))    
        }
        for(t in targets){
            targetMap.add(t, Target())
        }
    }
    func GetNewSource(s : Source){
        match(sourceMap.toMap().get(s)){
            case $None => throw VertexNotInGraphException("GetNewSource", s)
            case Some(s1) => s1
        }
    }
    func GetNewTarget(t : Target){
        match(targetMap.toMap().get(t)){
            case $None => throw VertexNotInGraphException("GetNewTarget", t)
            case Some(t1) => t1
        }
    }
}
