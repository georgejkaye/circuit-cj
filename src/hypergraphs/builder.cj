/**
 * builder.cj
 * 
 *This file contains the HypBuilder class to make hypergraph construction simpler and cleaner
 */

package hypergraphs

import debug.*

class HypBuilder <: HypergraphStructure {
    init(){
        super(
            ArrayList<Edge>(),
            ArrayList<Target>(),
            ArrayList<Source>(),
            MapBuilder<Target, Source>()
        )
    }
    init(
        edges : ArrayList<Edge>,
        inputs : ArrayList<Target>,
        outputs : ArrayList<Source>,
        conns   : MapBuilder<Target, Source>
    ){
        super(edges, inputs, outputs, conns)
    }
    init(dom : Int64, cod : Int64, wires : ArrayList<Wire>){
        // if(dom < 0){
        //     throw NegativeInputsException("HypBuilder", dom)
        // }
        // if(cod < 0){
        //     throw NegativeOutputsException("HypBuilder", cod)
        // }
        // if(wires.size() != cod){
        //     throw BadOutputLabelsException("HypBuilder", wires.size(), cod)
        // }
        super(
            ArrayList<Edge>(),
            ArrayList<Target>(dom, {x : Int64 => Target()}),
            ArrayList<Source>(cod, {x : Int64 => Source(wires.get(x))}),
            MapBuilder<Target,Source>()
        )
    }
    init(dom : Int64, cod : Int64, wires : List<Wire>){
        this(dom, cod, ArrayList<Wire>(wires))
    }
    init(dom : Int64, cod : Int64, output : String, elem : Int64){
        this(dom, cod, ArrayList<Wire>(cod, {x : Int64 => NewWire(output, elem + x)}))
    }
    init(dom : Int64, cod : Int64, output : String){
        this(dom, cod, ArrayList<Wire>(cod, {x : Int64 => NewWire(string: output)}))
    }
    /**
     * Get the graph that this builder defines
     * @return The hypergraph
     */
    func ToGraph() {
        Hypergraph(edges, inputs, outputs, connsr)
    } 
    /**
     * Get the graph that this builder defines and give it a name
     * @param name The name of this hypergraph
     * @return The hypergraph
     */
    func ToGraph(name : String){
        Hypergraph(name, edges, inputs, outputs, connsr)
    }
    /**
     * Add a connection from target to source to the builder
     * Also updates the source to target map
     * @param t The target vertex
     * @param s The source vertex
     */
    func AddConn(t : Target, s : Source) : Unit {
        connsr.add(t, s)
        connsl.add(s, t)
    }
    /**
     * Add an edge to the builder 
     */
    func AddEdge(e : Edge) {
        edges.add(e)
        for(i in 0..e.sources.size()){
            let s = e.sources[i]
            sources.add(s)
            rights.add(s, EdgePort(e, i))
        }
        for(i in 0..e.targets.size()){
            let t = e.targets[i]
            targets.add(t)
            lefts.add(t, EdgePort(e, i))
        }
    }
    /**
     * Perform an action for each connection in this builder
     * This is because I don't trust the for((t,s) in conns) appraoch
     * Sometimes it seems to miss pairs out
     * TODO: use the for((t,s) in conns) approach when it is sound
     * @param f The function to perform for each target-source pair in the conns map
     */
    func ForEachConn(f : (Target, Source) -> Unit){
        for(t in inputs){
            match(connsr.toMap().get(t)){
                case Some(s) => { f(t, s) }
                case $None   => {}
            }
        }
        for(e in edges){
            for(t in e.targets){
                match(connsr.toMap().get(t)){
                    case Some(s) => { f(t, s) }
                    case $None   => {}
                }
            }  
        }
    }
    /**
     * Create an edge and necessary infrastructure for a given generator 
     * Modifies the builder state
     * @param gen The generator
     * @return The newly made edge
     */ 
    func CreateEdge(gen : Generator) : Edge {
        let sources = ArrayList<Source>(Dom(gen), {x : Int64 => Source() })
        let targets = ArrayList<Target>(Cod(gen), {x : Int64 => Target() })
        let edge = Edge(gen, sources, targets)
        AddEdge(edge)
        edge
    }
    func CreateEdge(gen : Generator, sources : ArrayList<Source>) : Edge {
        if(sources.size() != Dom(gen)){
            throw BadDomainException("CreateEdge", sources.size(), Dom(gen))
        }
        let targets = ArrayList<Target>(Cod(gen), {x : Int64 => Target() })
        let edge = Edge(gen, sources, targets)
        AddEdge(edge)
        edge
    }
    /**
     * Create an edge and necessary infrastructure for a given generator, and connect it to some existing targets
     * Modifies the builder state
     * Throws BadDomainException if the length of the list of targets is not the same as the domain 
     * @param gen           The generator
     * @param incomingConns The list of targets to connect to the new edge on the left
     * @return The newly made edge
     */
    func CreateEdge(gen : Generator, incomingConns : ArrayList<Target>) : Edge {
        if(incomingConns.size() != Dom(gen)){
            throw BadDomainException("CreateEdge", incomingConns.size(), Dom(gen))
        }
        let edge = CreateEdge(gen)
        for(i in 0..Dom(gen)){
            AddConn(incomingConns[i], edge.sources[i])
        }
        edge
    }
    /**
     * Create an edge and necessary infrastructure for a given generator, and connect it to some existing targets
     * Modifies the builder state
     * Throws BadDomainException if the length of the list of targets is not the same as the domain 
     * @param gen           The generator
     * @param incomingConns The list of targets to connect to the new edge on the left
     * @return The newly made edge
     */
    func CreateEdge(gen : Generator, incomingConns : List<Target>) : Edge {
        CreateEdge(gen, ArrayList<Target>(incomingConns))
    }
    /**
     * Create an edge and necessary infrastructure for a given generator, and connect it to some existing targets on the left
     * and some existing sources on the right
     * Modifies the builder state
     * Throws BadDomainException if the length of the list of targets is not the same as the domain 
     * Throws BadCodomainException if the length of the list of sources is not the same as the codomain
     * @param gen           The generator
     * @param incomingConns The list of targets to connect to the new edge on the left
     * @param outgoingConns The list of sources to connect to the new edge on the right
     * @return The newly made edge
     */
    func CreateEdge(gen : Generator, incomingConns : ArrayList<Target>, outgoingConns : ArrayList<Source>) : Edge {
        if(outgoingConns.size() != Cod(gen)){
            throw BadCodomainException("CreateEdge", outgoingConns.size(), Cod(gen))
        }
        let edge = CreateEdge(gen, incomingConns)
        for(i in 0..Cod(gen)){
            AddConn(edge.targets[i], outgoingConns[i])
        }
        edge
    }
    /**
     * Create an edge and necessary infrastructure for a given generator, and connect it to some existing targets on the left
     * and some existing sources on the right
     * Modifies the builder state
     * Throws BadDomainException if the length of the list of targets is not the same as the domain 
     * Throws BadCodomainException if the length of the list of sources is not the same as the codomain
     * @param gen           The generator
     * @param incomingConns The list of targets to connect to the new edge on the left
     * @param outgoingConns The list of sources to connect to the new edge on the right
     * @return The newly made edge
     */
    func CreateEdge(gen : Generator, incomingConns : List<Target>, outgoingConns : List<Source>) : Edge {
        CreateEdge(gen, ArrayList<Target>(incomingConns), ArrayList<Source>(outgoingConns))
    }
    /**
     * Remove an edge from the graph, along with its sources and targets and any references in the connections map
     * @param edge The edge to remove
     */
    func RemoveEdge(edge : Edge){
        edges.removeIf({e : Edge => e == edge})
        sources.removeIf({s : Source => includes(edge.sources, s)})
        targets.removeIf({t : Target => includes(edge.targets, t)})
        let newConnsr = MapBuilder<Target, Source>()
        let newConnsl = MapBuilder<Source, Target>()
        let newLefts = MapBuilder<Target, Port>()
        let newRights = MapBuilder<Source, Port>()
        let f : (Target, Source) -> Unit = { t : Target, s : Source =>
            if(!includes(edge.sources, s) && !includes(edge.targets, t)){
                newConnsr.add(t, s)
                newConnsl.add(s, t)
                newLefts.add(t, GetEdge(t))
                newRights.add(s, GetEdge(s)) 
            }
        }
        // We need to refresh the connections to remove references to this edge
        ForEachConn(f)
        connsr = newConnsr
        connsl = newConnsl
        lefts = newLefts
        rights = newRights
    }
    /**
     * Remove an output from the graph
     * @param i The index of the output to remove
     */
    func RemoveOutput(i : Int64){
        if(i < 0 || i >= outputs.size()){
            throw BadOutputException("RemoveOutput", i, outputs.size())
        }
        outputs.removeAt(i)
    }
    /**
     * Remove a list of vertices from the outputs of the graph
     * @param outs The list of vertices to remove
     */
    func RemoveOutputs(outs : ArrayList<Source>){
        for(v in outs){
            match(position(outputs, v)){
                case Some(i) => RemoveOutput(i)  
                case $None   => throw BadOutputException("RemoveOutputs", v)
            }
        }
    }
    /**
     * Connect an edge to one of the outputs
     * @param outs  The indices of the outputs to connect to the new edge
     * @param gen   The generator of the new edge
     * @return The new edge
     */
    func ConnectOutputs(outs : ArrayList<Int64>, gen : Generator) : Edge {
        Debug("ConnectOutputs", "Connecting outputs ${PrintList(outs)} to generator ${gen}")
        if(Dom(gen) != outs.size()){
            throw BadDomainException("ConnectOutputs", outs.size(), Dom(gen))
        }
        // Grab the outputs that correspond to the indices provided 
        let chosenOutputs = ArrayList<Source>(outs.size(), {i : Int64 => 
            let j = outs[i]
            if(j < 0 || j >= outputs.size()){
                throw BadOutputException("ConnectOutputs", i, outputs.size())
            }
            outputs[j]
        })
        // Remove these vertices from the outputs
        RemoveOutputs(chosenOutputs)
        let edge = CreateEdge(gen, chosenOutputs)
        ConnectEdgeToOutputs(edge)
        edge
    }
    /**
     * Connect all the targets of an edge to the outputs of the graph
     * @param edge The edge to connect
     */
    func ConnectEdgeToOutputs(edge : Edge){
        for(t in edge.targets){
            let s = Source()
            AddConn(t,s)
            outputs.add(s)
        }
    }
}