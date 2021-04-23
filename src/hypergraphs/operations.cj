package hypergraphs
import core.*

func Seq(f : Hypergraph, g : Hypergraph){
    var sourcesMap : MapBuilder<Source,Source>
    var targetsMap : MapBuilder<Target,Target>
    
    var edges : ArrayList<Edge> = []
    for (e in f.GetEdges()){
        
    }
    //edges.addAll(f.GetEdges())
    //edges.addAll(g.GetEdges())
    //print(AtomListToString(edges))
}

external func TestOps(){
    Seq(AndGate("and"), NotGate("not"))
}