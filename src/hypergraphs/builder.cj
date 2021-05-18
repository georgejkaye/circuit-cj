/**
 * builder.cj
 * 
 *This file contains the HypBuilder class to make hypergraph construction simpler and cleaner
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
    func AddConn(t : Target, s : Source) : Unit {
        connsr.add(t, s)
        connsl.add(s, t)
        s.conn = Some<Target>(t)
        t.conn = Some<Source>(s)
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
    /**
     * Remove an edge from the graph, along with its sources and targets and any references in the connections map
     * @param edge The edge to remove
     */
    func RemoveEdge(edge : Edge){
        edges.removeIf({e : Edge => e == edge})
        let newConnsr = MapBuilder<Target, Source>()
        let newConnsl = MapBuilder<Source, Target>()
        let f : (Target, Source) -> Unit = { t : Target, s : Source =>
            if(!includes(edge.sources, s) && !includes(edge.targets, t)){
                newConnsr.add(t, s)
                newConnsl.add(s, t)
            }
        }
        // We need to refresh the connections to remove references to this edge
        ForEachConn(f)
        connsr = newConnsr
        connsl = newConnsl
    }
    /**
     * Remove an output from the graph
     * @param i The index of the output to remove
     */
    func RemoveConcat(i : Int64){
        if(i < 0 || i >= outputs.size()){
            throw BadOutputException("RemoveOutput", i, outputs.size())
        }
        let sout = outputs.removeAt(i)
        let newConnsr = MapBuilder<Target, Source>()
        let newConnsl = MapBuilder<Source, Target>()
        let f : (Target, Source) -> Unit = { t : Target , s : Source => 
            if(s != sout){
                newConnsr.add(t,s)
            }
        }
        ForEachConn(f)
        connsr = newConnsr
        connsl = newConnsl
    }
    /**
     * Connect an edge to one of the outputs
     * @param outs  The indices of the outputs to connect to the new edge
     * @param gen   The generator of the new edge
     * @return The new edge
     */
    func ConnectOutputs(outs : ArrayList<Int64>, gen : Generator) : Edge {
        if(Dom(gen) != outs.size()){
            throw BadDomainException("ConnectOutputs", outs.size(), Dom(gen))
        }

        let chosenOutputs = ArrayList<Source>(outs.size(), {i : Int64 => 
            let j = outs[i]
            if(j < 0 || j >= outputs.size()){
                throw BadOutputException("ConnectOutputs", i, outputs.size())
            }
            outputs[j]
        })
        outputs.removeIf({s : Source => includes(chosenOutputs, s)})
        let edge = Edge(gen, chosenOutputs, ArrayList<Target>(Cod(gen), {x : Int64 => Target()}))
        edges.add(edge)
        edge
    }
}

append HypBuilder with ToString {
    func toString(hb : HypBuilder){
        let inputString = "inputs ${TargetListToString(hb.inputs)}"
        var edgeString = ""
        for(e in hb.edges){
            let id = "${e.id}"
            let gen = "${e.generator}"
            let sourceString = SourceListToString(e.sources)
            let targetString = TargetListToString(e.targets)
            edgeString = "${edgeString}${id} (${gen}) ${sourceString} ${targetString}\n"
        }
        let outputString = "outputs ${SourceListToString(hb.outputs)}"
        var connsString = "connections ${hb.GetConns().toMap().size()} "
        for((t,s) in hb.GetConns().toMap()){
            connsString = "${connsString}(${t.id} ${s.id}) "
        }
        "${inputString}\n${edgeString}${outputString}\n${connsString}"
    }
}