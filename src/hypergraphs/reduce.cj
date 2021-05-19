package hypergraphs

class RewriteRule {
    let entryPoint : Generator
    let rewriter   : (Hypergraph, Edge) -> Hypergraph
    init(entryPoint : Generator, rewriter : (Hypergraph, Edge) -> Hypergraph){
        this.entryPoint = entryPoint
        this.rewriter = rewriter 
    }
}



// external func TestRewrites(){

//     let forkStub = RewriteRule(FORK, {f : Hypergraph, e : Edge =>
//         let left = f.NextEdge(e.targets[0])
//         let right = f.NextEdge(e.targets[1])

//         var leftStub = false
//         var rightStub = false

//         match(PortToGenerator() f.NextEdge(e.targets[0])){
//             case EdgePort((e, i)) => {
//                 match(PortG)
//             }
//         }

//     })

//     let hb = HypBu



// }