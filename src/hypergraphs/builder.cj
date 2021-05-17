/**
 * This file contains the HypBuilder class to make hypergraph construction simpler and cleaner
 */
package hypergraphs

class HypBuilder {
    var edges   : ArrayList<Edge>
    var inputs  : ArrayList<Target>
    var outputs : ArrayList<Source>
    private var connsr : MapBuilder<Target, Source>
    private var connsl : MapBuilder<Source, Target>
    init(){
        edges = ArrayList<Edge>()
        inputs = ArrayList<Target>()
        outputs = ArrayList<Source>()
        connsr = MapBuilder<Target, Source>() 
        connsl = MapBuilder<Source, Target>() 
    }
    init(f : Hypergraph){
        let newF = f.Clone()
        edges = newF.GetEdges()
        inputs = newF.GetInputs()
        outputs = newF.GetOutputs()
        connsr = newF.GetConnsR()
        connsl = newF.GetConnsL()
    }
    init(dom : Int64, cod : Int64, wires : ArrayList<Wire>){
        if(dom < 0){
            throw NegativeInputsException("HypBuilder", dom)
        }
        if(cod < 0){
            throw NegativeOutputsException("HypBuilder", cod)
        }
        if(wires.size() != cod){
            throw BadOutputLabelsException("HypBuilder", wires.size(), cod)
        }
        edges = ArrayList<Edge>()
        inputs = ArrayList<Target>(dom, {x : Int64 => Target()})
        outputs = ArrayList<Source>(cod, {x : Int64 => Source(wires.get(x))})
        connsr = MapBuilder<Target,Source>()
        connsl = MapBuilder<Source,Target>()
    }
    init(dom : Int64, cod : Int64, wires : List<Wire>){
        this(dom, cod, ArrayList<Wire>(wires))
    }
    init(dom : Int64, cod : Int64, output : String, elem : Int64){
        this(dom, cod, ArrayList<Wire>(cod, {x : Int64 => NewWire(output, elem + x)}))
    }
    func GetConns(){ connsr }
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
    func AddConn(t : Target, s : Source){
        connsr.add(t, s)
        connsl.add(s, t)
    }
    /**
     * Get the corresponding target for a source
     * Throws VertexNotInGraphException if no match (badly formed hypergraph)
     * @param s The source
     * @return The corresponding target
     */
    func GetConnL(s : Source){
        match(connsl.toMap().get(s)){
            case Some(t) => t
            case $None => throw VertexNotInGraphException("GetConnL", s)
        }
    }
    /**
     * Get the corresponding source for a target
     * Throws VertexNotInGraphException if no match (badly formed hypergraph)
     * @param s The target
     * @return The corresponding source
     */
    func GetConnR(t : Target){
        match(connsr.toMap().get(t)){
            case Some(s) => s
            case $None => throw VertexNotInGraphException("GetConnR", t)
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
        edges.add(edge)
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
}