/**
 * builder.cj
 * 
 * This file contains the HypBuilder class to make hypergraph construction simpler and cleaner
 */

package hypergraphs

import debug.*

/**
 * A hyp builder is a hypergraph structure with associated functions for adding edges etc in a well-formed way
 * When creating hypergraphs, a hyp builder should be used rather than defining atoms explicitly
 * This makes the code more elegant and reduces the likelihood of introducing malformities
 */
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
    /**
     * Create a hyp builder with a certain number of inputs and outputs, with output wires assigned
     * @param dom   The number of inputs
     * @param cod   The number of outputs
     * @param wires The list of wires to assign to the outputs
     */
    init(dom : Int64, cod : Int64, wires : ArrayList<Wire>){
        super(
            ArrayList<Edge>(),
            ArrayList<Target>(dom, {x : Int64 => Target()}),
            ArrayList<Source>(cod, {x : Int64 => Source(wires.get(x))}),
            MapBuilder<Target,Source>()
        )
    }
    /**
     * Create a hyp builder with a certain number of inputs and outputs, with output wires assigned
     * @param dom   The number of inputs
     * @param cod   The number of outputs
     * @param wires The list of wires to assign to the outputs
     */
    init(dom : Int64, cod : Int64, wires : List<Wire>){
        this(dom, cod, ArrayList<Wire>(wires))
    }
    /**
     * Create a hyp builder with a certain number of inputs and outputs, with output wires assigned
     * @param dom    The number of inputs
     * @param cod    The number of outputs
     * @param output The name to assign to the output bus
     * @param elem   The index to start counting the bus wires from
     */
    init(dom : Int64, cod : Int64, output : String, elem : Int64){
        this(dom, cod, ArrayList<Wire>(cod, {x : Int64 => NewWire(output, elem + x)}))
    }
    /**
     * Create a hyp builder with a certain number of inputs and outputs, with output wires assigned
     * @param dom    The number of inputs
     * @param cod    The number of outputs
     */
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
     * Add an edge to the builder, adding it to the necessary maps
     * @param e the edge
     */
    func AddEdge(e : Edge) {
        busVertexMaps = MapBuilder<Bus, MapBuilder<Int64, Source> * ArrayList<Source>>()
        edges.add(e)
        for(i in 0..e.sources.size()){
            AddSource(e.sources[i], EdgePort(e, i), sources, rights, busMaps, busList, wireList)
        }
        for(i in 0..e.targets.size()){
            AddTarget(e.targets[i], EdgePort(e, i), targets, lefts, connsr, connsl)
        }
        UpdateBusVertexList(busList, busMaps, busVertexMaps)
    }
    /**
     * Add all the parts of another graph to this builder
     * @param f The new graph
     */
    func AddNewGraph(f : HypergraphStructure){
        for(e in f.GetEdges()){
            AddEdge(e)
        }
        for(t in f.GetTargets()){
            AddConn(t, f.GetConnR(t))
        }
        for(t in f.GetInputs()){
            AddInput(t)
        }
        for(t in f.GetOutputs()){
            AddOutput(t)
        }
    }
    /**
     * Set a target to be the next input
     * @param t the target to set as the next input
     */
    func AddInput(t : Target){
        inputs.add(t)
    }
    /**
     * Set a source to be the next output
     * @param s the source to set as the next output
     */
    func AddOutput(s : Source){
        outputs.add(s)
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
    /**
     * Create an edge and assign it to some already existing sources, creating the other necessary infrastructure
     * @param gen     The generator
     * @param sources The sources that will be assigned to this new edge
     * @return The newly made edge
     */
    func CreateEdgeFromExisting(gen : Generator, existingSources : ArrayList<Source>) : Edge {
        if(existingSources.size() != Dom(gen)){
            throw BadDomainException("CreateEdgeFromExisting", existingSources.size(), Dom(gen))
        }
        let targets = ArrayList<Target>(Cod(gen), {x : Int64 => Target() })
        let edge = Edge(gen, existingSources, targets)
        AddEdge(edge)
        edge
    }
    /**
     * Create an edge and assign it to some already existing targets, creating the other necessary infrastructure
     * @param gen     The generator
     * @param sources The sources that will be assigned to this new edge
     * @return The newly made edge
     */
    func CreateEdgeFromExisting(gen : Generator, existingTargets : ArrayList<Target>) : Edge {
        if(existingTargets.size() != Cod(gen)){
            throw BadDomainException("CreateEdgeFromExisting", existingTargets.size(), Dom(gen))
        }
        let sources = ArrayList<Source>(Dom(gen), {x : Int64 => Source() })
        let edge = Edge(gen, sources, existingTargets)
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
     * Purge some vertices from the graph, removing them from the connections and other lists
     * @param targets the targets to remove
     * @param sources the sources to remove
     */
    func RemoveVertices(removedSources : ArrayList<Source>, removedTargets : ArrayList<Target>){
        sources.removeIf({s : Source => includes(removedSources, s)})
        targets.removeIf({t : Target => includes(removedTargets, t)})
        let newConnsr = MapBuilder<Target, Source>()
        let newConnsl = MapBuilder<Source, Target>()
        let newLefts = MapBuilder<Target, Port>()
        let newRights = MapBuilder<Source, Port>()
        let f : (Target, Source) -> Unit = { t : Target, s : Source =>
                    if(!includes(removedSources, s) && !includes(removedTargets, t)){
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
     * Remove an edge from the graph, along with its sources and targets and any references in the connections map
     * @param edge The edge to remove
     */
    func RemoveEdge(edge : Edge){
        edges.removeIf({e : Edge => e == edge})
        RemoveVertices(edge.sources, edge.targets)
    }
    /**
     * Remove an output from the graph
     * @param i The index of the output to remove
     */
    func RemoveOutput(i : Int64){
        if(i < 0 || i >= outputs.size()){
            throw BadOutputException("RemoveOutput", i, outputs.size())
        }
        let s = outputs.removeAt(i)
        RemoveVertices(ArrayList<Source>([s]), ArrayList<Target>())
    }
    /**
     * Remove a list of vertices from the outputs of the graph
     * @param outs The list of vertices to remove
     */
    func RemoveOutputs(outs : ArrayList<Source>){
        // TODO for i in outs causes unknown error here
        for(i in 0..outs.size()){
            match(index(outputs, outs[i])){
                case Some(j) => RemoveOutput(j)
                case $None   => throw BadOutputException("RemoveOutputs", outs[i])
            }
        }
    }
    /**
    * Remove all outputs from the graph
    */
    func RemoveOutputs(){
        RemoveOutputs(ArrayList<Source>(outputs))
    }
    /**
     * Remove an input from the graph
     * @param i The index of the input to remove
     */
    func RemoveInput(i : Int64){
        if(i < 0 || i >= inputs.size()){
            throw BadInputException("RemoveInput", i, inputs.size())
        }
        let t = inputs.removeAt(i)
        RemoveVertices(ArrayList<Source>(), ArrayList<Target>([t]))
    }
    /**
     * Remove a list of vertices from the inputs of the graph
     * @param ins The list of vertices to remove
     */
    func RemoveInputs(ins : ArrayList<Target>){
        // TODO for i in outs causes unknown error here
        for(i in 0..ins.size()){
            match(index(inputs, ins[i])){
                case Some(j) => RemoveInput(j)  
                case $None   => throw BadInputException("RemoveInputs", ins[i])
            }
        }
    }
    /**
     * Remove all inputs from the graph
     */
    func RemoveInputs(){
        RemoveInputs(ArrayList<Target>(inputs))
    }
    /**
     * Set an output to be the source of a new edge
     * @param outs  The index of the output to connect to the new edge
     * @param gen   The generator of the new edge
     * @return The new edge
     */
    func ConnectOutputToEdge(out : Int64, gen : Generator) : Edge {
        ConnectOutputsToEdge(ArrayList<Int64>([out]), gen)
    }
    /**
     * Set some outputs to be the sources of a new edge
     * @param outs  The indices of the outputs to connect to the new edge
     * @param gen   The generator of the new edge
     * @return The new edge
     */
    func ConnectOutputsToEdge(outs : ArrayList<Int64>, gen : Generator) : Edge {
        Debug("ConnectOutputsToEdge", "Connecting outputs ${PrintList(outs)} to generator ${gen}")
        if(Dom(gen) != outs.size()){
            throw BadDomainException("ConnectOutputsToEdge", outs.size(), Dom(gen))
        }
        // Grab the outputs that correspond to the indices provided 
        let chosenOutputs = ArrayList<Source>(outs.size(), {i : Int64 => 
            let j = outs[i]
            if(j < 0 || j >= outputs.size()){
                throw BadOutputException("ConnectOutputsToEdge", i, outputs.size())
            }
            outputs[j]
        })
        // Remove these vertices from the outputs
        RemoveOutputs(chosenOutputs)
        let edge = CreateEdgeFromExisting(gen, chosenOutputs)
        // Connect the new edge to the outputs if necessary
        ConnectEdgeToOutputs(edge)
        edge
    }
    /**
     * Set an input to be the target of a new edge
     * @param outs  The index of the input to connect to the new edge
     * @param gen   The generator of the new edge
     * @return The new edge
     */
    func ConnectInputToEdge(ins : Int64, gen : Generator){
        ConnectInputsToEdge(ArrayList<Int64>([ins]), gen)
    }
    /**
     * Set some inputs to be the targets of a new edge
     * @param ins The indices of the inputs to connect to the new edge
     * @param gen The generator of the new edge
     * @return The new edge
     */
    func ConnectInputsToEdge(ins : ArrayList<Int64>, gen : Generator){
        Debug("ConnectInputsToEdge", "Connecting inputs ${PrintList(ins)} to generator ${gen}")
        if(Cod(gen) != ins.size()){
            throw BadCodomainException("ConnectInputsToEdge", ins.size(), Cod(gen))
        }
        let chosenInputs = ArrayList<Target>(ins.size(), {i : Int64 => 
            let j = ins[i]
            if(j < 0 || j >= inputs.size()){
                throw BadInputException("ConnectInputsToEdge", i, inputs.size())
            }
            inputs[j]
        })
        RemoveInputs(chosenInputs)
        let edge = CreateEdgeFromExisting(gen, chosenInputs)
        ConnectEdgeToInputs(edge)
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
            AddOutput(s)
        }
    }
    /**
     * Connect all the sources of an edge to the inputs of the graph
     * @param edge The edge to connect
     */
    func ConnectEdgeToInputs(edge : Edge){
        for(s in edge.sources){
            let t = Target()
            AddConn(t,s)
            AddInput(t)
        }
    }
}