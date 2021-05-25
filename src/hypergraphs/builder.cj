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
            ArrayList<Source>()
        )
    }
    init(
        edges : ArrayList<Edge>,
        inputs : ArrayList<Target>,
        outputs : ArrayList<Source>
    ){
        super(edges, inputs, outputs)
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
            ArrayList<Source>(cod, {x : Int64 => Source(wires.get(x))})
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
     * @param output The name to assign the output bus
     */
    init(dom : Int64, cod : Int64, output : String){
        this(dom, cod, ArrayList<Wire>(cod, {x : Int64 => NewWire(string: output)}))
    }
    /**
     * Create a hyp builder with a certain number of inputs and outputs, with no given output wire name
     * @param dom    The number of inputs
     * @param cod    The number of outputs
     */
    init(dom : Int64, cod : Int64){
        this(dom, cod, "")
    }
    /**
     * Get the graph that this builder defines
     * @return The hypergraph
     */
    func ToGraph() {
        Hypergraph(edges, inputs, outputs)
    } 
    /**
     * Get the graph that this builder defines and give it a name
     * @param name The name of this hypergraph
     * @return The hypergraph
     */
    func ToGraph(name : String){
        Hypergraph(name, edges, inputs, outputs)
    }
    /**
     * Add a connection from target to source to the builder
     * Also updates the source to target map
     * @param t The target vertex
     * @param s The source vertex
     */
    func AddConn(t : Target, s : Source) : Unit {
        t.SetConn(s)
        s.SetConn(t)
    }
    /**
     * Add a new source vertex
     * @param s The new source vertex
     */
    func AddNewSource(s : Source){
        AddSource(s, sources, busMaps, busList, wireList)
    }
    /**
     * Add a new target vertex
     * @param t The new target vertex
     */
    func AddNewTarget(t : Target){
        AddTarget(t, targets)
    }
    /**
     * Update the bus lists, maps, and vertex maps
     */
    func UpdateBuses(){
        UpdateBusVertexList(busList, busMaps, busVertexMaps)
    }
    /**
     * Add an edge to the builder, adding it to the necessary maps
     * @param e the edge
     */
    func AddEdge(e : Edge) {
        busVertexMaps = MapBuilder<Bus, MapBuilder<Int64, Source> * ArrayList<Source>>()
        edges.add(e)
        for(i in 0..e.sources.size()){
            AddNewSource(e.sources[i])
        }
        for(i in 0..e.targets.size()){
            AddNewTarget(e.targets[i])
        }
        UpdateBuses()
    }
    /**
     * Add a list of edges to the builder, adding things to the necessary maps
     * @param es the list of edges
     */
    func AddEdges(es : ArrayList<Edge>){
        for(e in es){
            AddEdge(e)
        }
    }
    /**
     * Add all the parts of another graph to this builder
     * @param f The new graph
     */
    func AddNewGraph(f : HypergraphStructure){
        // HACK if for some reason f is empty the lists aren't initialised
        if(edges.size() == 0){
            edges = ArrayList<Edge>()
        }
        for(e in f.GetEdges()){
            AddEdge(e)
        }
        // HACK if for some reason f is empty the lists aren't initialised
        if(inputs.size() == 0){
            inputs = ArrayList<Target>()
        }
        for(t in f.GetInputs()){
            AddInput(t)
        }
        // HACK if for some reason f is empty the lists aren't initialised
        if(outputs.size() == 0){
            outputs = ArrayList<Source>()
        }
        for(t in f.GetOutputs()){
            AddOutput(t)
        }
    }
    /** 
     * Create a new source vertex, assign it to a port, and connect it to an existing target
     * @param p The port to assign the source to
     * @param t The target to connect this source to
     */
    func NewSource(p : Port, t : Target){
        let s = Source()
        AddNewSource(s)
        match(p){
            case EdgePort(e, i) => SetSource(e, i, s)
            case InterfacePort(i) => SetOutput(i, s)
        }
        AddConn(t, s)
    }
    /** 
     * Create a new target vertex, assign it to a port, and connect it to an existing source
     * @param p The port to assign the source to
     * @param t The target to connect this source to
     */
    func NewSource(p : Port, s : Source){
        let t = Target()
        AddNewTarget(t)
        match(p){
            case EdgePort(e, i) => SetTarget(e, i, t)
            case InterfacePort(i) => SetInput(i, t)
        }
        AddConn(t, s)
    }
    /**
     * Set a target to be the next input
     * @param t the target to set as the next input
     */
    func AddInput(t : Target){
        t.SetPort(inputs.size())
        inputs.add(t)
        AddNewTarget(t)
    }
    /**
     * Set an input to be a different vertex
     * @param i The index of the input to replace
     * @param t The new input
     */
    func SetInput(i : Int64, t : Target){
        inputs.set(i, t)
        t.SetPort(i)
    }
    /**
     * Add a list of outputs to this builder
     * @param ts the list of targets
     */
    func AddInputs(ts : ArrayList<Target>){
        for(t in ts){
            AddInput(t)
        }
    }
    /**
     * Set a source to be the next output
     * @param s the source to set as the next output
     */
    func AddOutput(s : Source){
        s.SetPort(outputs.size())
        outputs.add(s)
        AddNewSource(s)
    }
    /**
     * Add a list of outputs to this builder
     * @param ss the list of sources
     */
    func AddOutputs(ss : ArrayList<Source>){
        for(s in ss){
            AddOutput(s)
        }
    }
    /** 
     * Create a new output and return it
     * @return the new outputs
     */
    func NewOutput(){
        let s = Source()
        s.SetPort(InterfacePort(outputs.size()))
        outputs.add(s)
        s
    }
    /**
     * Set an output to be a different vertex
     * @param i The index of the output to replace
     * @param s The new output
     */
    func SetOutput(i : Int64, s : Source){
        outputs.set(i, s)
        s.SetPort(InterfacePort(i))
    }
    /**
     * Set a source of an edge to be a different vertex
     * @param edge The edge
     * @param i    The index of the source to replace
     * @param s    The new source
     */
    func SetSource(edge : Edge, i : Int64, s : Source){
        edge.sources.set(i, s)
        s.SetPort(edge, i)
    }
    func SetSource(s : Source, p : Port){
        match(p){
            case EdgePort(e, i) => SetSource(e, i , s)
            case InterfacePort(i) => SetOutput(i, s)
        }
    }
    /**
     * Set a target of an edge to be a different vertex
     * @param edge The edge
     * @param i    The index of the target to replace
     * @param s    The new target
     */
    func SetTarget(edge : Edge, i : Int64, t : Target){
        edge.targets.set(i, t)
        t.SetPort(edge, i)
    }
    func SetTarget(t : Target, p : Port){
        match(p){
            case EdgePort(e, i) => SetTarget(e, i, t)
            case InterfacePort(i) => SetInput(i, t)
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
     * Create an edge and assign it to some already existing sources, creating the other necessary infrastructure
     * @param gen     The generator
     * @param sources The sources that will be assigned to this new edge
     * @return The newly made edge
     */
    func CreateEdgeFromExisting(gen : Generator, existingSources : List<Source>) : Edge {
        CreateEdgeFromExisting(gen, ArrayList<Source>(existingSources))
    }
    /**
     * Create an edge and assign it to some already existing targets, creating the other necessary infrastructure
     * @param gen     The generator
     * @param targets The targets that will be assigned to this new edge
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
     * Create an edge and assign it to some already existing targets, creating the other necessary infrastructure
     * @param gen     The generator
     * @param targets The targets that will be assigned to this new edge
     * @return The newly made edge
     */
    func CreateEdgeFromExisting(gen : Generator, existingTargets : List<Target>) : Edge {
        CreateEdgeFromExisting(gen, ArrayList<Target>(existingTargets))
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
     * Detach some vertices from the edges or interface they are connected to
     * This doesn't delete their connections, as we may still want to reassign them later
     * @param targets the targets to remove
     * @param sources the sources to remove
     */
    func DetachVertices(removedSources : ArrayList<Source>, removedTargets : ArrayList<Target>){
        sources.removeIf({s : Source => includes(removedSources, s)})
        targets.removeIf({t : Target => includes(removedTargets, t)})
        inputs.removeIf({t : Target => includes(removedTargets, t)})
        outputs.removeIf({s : Source => includes(removedSources, s)})
        for(s in removedSources){
            s.RemovePort()
        }
        for(t in removedTargets){
            t.RemovePort()
        }
    }
    /**
     * Remove an edge from the graph, along with its sources and targets and any references in the connections map
     * @param edge The edge to remove
     */
    func RemoveEdge(edge : Edge){
        edges.removeIf({e : Edge => e == edge})
        DetachVertices(edge.sources, edge.targets)
    }
    /** 
     * Remove a list of edges from the graph
     * @param es the list of edges
     */
    func RemoveEdges(es : ArrayList<Edge>){
        for(e in es){
            RemoveEdge(e)
        }
    }
    /**
     * Remove an output from the graph
     * @param i The index of the output to remove
     */
    func RemoveOutput(i : Int64){
        if(i < 0 || i >= outputs.size()){
            throw BadOutputException("RemoveOutput", i, outputs.size())
        }
        DetachVertices(ArrayList<Source>([outputs[i]]), ArrayList<Target>())
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
        DetachVertices(ArrayList<Source>(), ArrayList<Target>([inputs[i]]))
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
     * Set an output to be the source of a new edge
     * @param outs  The index of the output to connect to the new edge
     * @param gen   The generator of the new edge
     * @return The new edge
     */
    func ConnectOutputToEdge(out : Source, gen : Generator) : Edge {
        ConnectOutputsToEdge(ArrayList<Source>([out]), gen)
    }
    /**
     * Set some outputs to be the sources of a new edge
     * @param outs  The indices of the outputs to connect to the new edge
     * @param gen   The generator of the new edge
     * @return The new edge
     */
    func ConnectOutputsToEdge(outs : ArrayList<Int64>, gen : Generator) : Edge {
        Debug("ConnectOutputsToEdge", "Connecting outputs ${PrintList(outs, {n : Int64 => "${n}"})} to generator ${gen}")
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
       
        ConnectOutputsToEdge(chosenOutputs, gen)
    }
    func ConnectOutputsToEdge(outs : ArrayList<Source>, gen : Generator) : Edge {
        // Remove these vertices from the outputs
        RemoveOutputs(outs)
        let edge = CreateEdgeFromExisting(gen, outs)
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
        Debug("ConnectInputsToEdge", "Connecting inputs to generator ${gen}")
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
     * Connect a given target from an edge to the outputs
     * @param edge The edge to connect to the outputs
     * @param i    The index of the target to connect
     */
    func ConnectEdgeToOutputs(edge : Edge, i : Int64){
        if(i < 0 || i >= Cod(edge.generator)){
            throw BadCodomainException("ConnectEdgeToOutputs", i, Cod(edge.generator))
        }
        let s = Source()
        AddConn(edge.targets[i], s)
        AddOutput(s)
    }
    /**
     * Connect all the targets of an edge to the outputs of the graph
     * @param edge The edge to connect
     */
    func ConnectEdgeToOutputs(edge : Edge){
        for(i in 0..Cod(edge.generator)){
            ConnectEdgeToOutputs(edge, i)
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