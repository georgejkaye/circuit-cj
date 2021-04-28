package hypergraphs

class InaccessibleCodeException <: Exception {
    init(){
        print("This code should not be accessible")
    }
}

class BadOutputPortsException <: Exception {
    init(){
        print("Length of port ports list is not the same as the number of ports")
    }
}
class BadDomainException <: Exception {
    init(){
        print("Number of inputs does not match the domain of the label")
    }
}
class BadCodomainException <: Exception {
    init(){
        print("Number of ports does not match the codomain of the label")
    }
}
class BadOutputsException <: Exception {
    init(f : Hypergraph, n : Int64){
        print("Hypergraph '${f.GetName()}' has ${f.GetN()} ports but requires ${n}")
    }
}

func OpMToN(m : Int64, n : Int64, generator : Generator,  input : Hypergraph, ports : ArrayList<String>, name: String){

    let (dom, cod) = match(generator){
        case VALUE(val)        => (0,1)
        case STRUCTURAL(label) => (label.dom, label.cod)
        case GATE(label)       => (label.dom, label.cod)
        case DELAY(dur)        => (1,1)
        case IDENTITY          => (1,1)
        case INLINK(spec)      => (spec.width, 0)
        case OUTLINK(spec)     => (0, spec.width)
    }

    if(m != dom || m < 0){
        throw BadDomainException()
    }
    if(n != cod || n < 0){
        throw BadCodomainException()
    }
    if(ports.size() != n){
        throw BadOutputPortsException()
    }
    if(input.GetN() != m){
        throw BadOutputsException(input, m)
    }

    let busMap = MapBuilder<String, Bus>()

    let inputs = ArrayList<Target>(m, {x => Target()})
    let sources = ArrayList<Source>(m, {x => Source()})
    let targets = ArrayList<Target>(n, {x => Target()})
    let outputs = ArrayList<Source>(n, {x => 
        let port = ports.get(x)
        if(port == ""){
            Source(Wire())
        } else {
            let bus = match(busMap.toMap().get(port)){
                case Some(bus) => bus
                case $None => {
                    let newBus = Bus(port)
                    busMap.add(port, newBus)
                    newBus
                }
            }
            Source(Wire(bus, bus.AddWire()))
        }
    })

    let op = Edge(generator, sources, targets)

    let conns = MapBuilder<Target, Source>()
    for (i in 0..m) {
        conns.add(inputs.get(i), sources.get(i))
    }
    for (i in 0..n) {
        conns.add(targets.get(i), outputs.get(i))
    }

    let graph = Hypergraph(name, ArrayList<Edge>([op]), inputs, outputs, conns.toMap())
    Seq(input, graph)
}

func OpZeroToOne(gen : Generator, out : String, name : String){ 
    OpMToN(0,1, gen, Empty(), ArrayList<String>([out]), name) 
}
func OpOneToZero(gen : Generator, input : Hypergraph, name : String){ 
    if(input.GetN() != 1){
        throw BadOutputException(input, 1)
    }
    OpMToN(1, 0, gen, input, ArrayList<String>(), name) 
}
func OpOneToOne(gen : Generator, input : Hypergraph, out : String, name : String){
    if(input.GetN() != 1){
        throw BadOutputException(input, 1)
    }
    OpMToN(1, 1, gen, input, ArrayList<String>([out]), name) 
}
func OpTwoToOne(gen : Generator, input : Hypergraph, out : String, name : String){ 
    if(input.GetN() != 2){
        throw BadOutputException(input, 2)
    }
    OpMToN(2, 1, gen, input, ArrayList<String>([out]), name) 
}
func OpTwoToOne(gen : Generator, lhs : Hypergraph, rhs : Hypergraph, out : String, name : String){
    if(lhs.GetN() != 1){
        throw BadOutputException(lhs, 1)
    }
    if(rhs.GetN() != 1){
        throw BadOutputException(rhs, 1)
    }
    OpMToN(2, 1, gen, Par(lhs,rhs), ArrayList<String>([out]), name)
}
func OpThreeToOne(gen : Generator, input : Hypergraph, out : String, name : String){ 
    if(input.GetN() != 3){
        throw BadOutputException(input, 3)
    }
    OpMToN(3, 1, gen, input, ArrayList<String>([out]), name) 
}
func OpThreeToOne(gen : Generator, x : Hypergraph, y : Hypergraph, z : Hypergraph, out : String, name : String){
    if(x.GetN() != 1){
        throw BadOutputException(x, 1)
    }
    if(y.GetN() != 1){
        throw BadOutputException(y, 1)
    }
    if(y.GetN() != 1){
        throw BadOutputException(z, 1)
    }
    OpMToN(3, 1, gen, Par([x,y,z]), ArrayList<String>([out]), name)
}

func OpOneToTwo(gen : Generator, input : Hypergraph, lhs : String, rhs : String, name : String){ 
    if(input.GetN() != 1){
        throw BadOutputException(input, 2)
    }
    OpMToN(1,2, gen, input, ArrayList<String>([lhs, rhs]), name) 
}

func Bottom(port!: String = "", name!: String = "") { 
    OpZeroToOne(VALUE(BOTTOM), port, name) 
}
func Top(port!: String = "", name!: String = ""){
    OpZeroToOne(VALUE(TOP), port, name)
}
func True(port!: String = "", name!: String = "") { 
    OpZeroToOne(VALUE(TRUE), port, name) 
}
func False(port!: String = "", name!: String = ""){
    OpZeroToOne(VALUE(FALSE), port, name)
}


external func Fork(input!: Hypergraph = Identity(1), lhs!: String = "", rhs!: String = "", name!: String = "") { 
    OpOneToTwo(FORK, input, lhs, rhs, name) 
}
external func Join(input!: Hypergraph = Identity(2), port!: String = "", name!: String = ""){ 
    OpTwoToOne(JOIN, input, port, name) 
}
external func Join(lhs!: Hypergraph, rhs!: Hypergraph, port!: String = "", name!: String = ""){
    OpTwoToOne(JOIN, lhs, rhs, port, name)
}
external func Stub(input!: Hypergraph = Identity(1), name!: String = ""){ 
    OpOneToZero(STUB, input, name) 
}

external func Copy(n : Int64) : Hypergraph {
    if(n < 0){
        throw NegativeWireException()
    }
    if(n == 0){
        Empty()
    } else {
        Seq(Par(Copy(n-1), Fork()), Par(ArrayList<Hypergraph>([Identity(n-1), Swap(n-1,1), Identity(1)])))
    }
}

external func Erase(n : Int64) : Hypergraph {
    if(n == 0){
        Empty()
    } else {
        Par(Stub(), Erase(n-1))
    }
}

external func Merge(n : Int64) : Hypergraph {
    if(n < 0){
        throw NegativeWireException()
    }
    if(n == 0){
        Empty()
    } else {
        Seq(Par(ArrayList<Hypergraph>([Identity(n-1), Swap(n-1,1), Identity(1)])), Par(Merge(n-1), Join()))
    }
}

external func Init(n : Int64) : Hypergraph {
    if(n == 0){
        Empty()
    } else {
        Par(Bottom(), Init(n-1))
    }
}

external func NotGate(input!: Hypergraph = Identity(1), port!: String = "", name!: String = "") { OpOneToOne(NOT, input, port, name) }

external func AndGate(input!: Hypergraph = Identity(2), port!: String = "", name!: String = "") { OpTwoToOne(AND, input, port, name) }
external func AndGate(lhs!: Hypergraph, rhs!: Hypergraph, port!: String = "", name!: String = ""){ OpTwoToOne(AND, lhs, rhs, port, name) }

external func OrGate(input!: Hypergraph = Identity(2), port!: String = "", name!: String = "") { OpTwoToOne(OR, input, port, name) }
external func OrGate(lhs!: Hypergraph, rhs!: Hypergraph, port!: String = "", name!: String = ""){ OpTwoToOne(OR, lhs, rhs, port, name) }

external func XorGate(input!: Hypergraph = Identity(2), port!: String = "", name!: String = "") { OpTwoToOne(XOR, input, port, name) }
external func XorGate(lhs!: Hypergraph, rhs!: Hypergraph, port!: String = "", name!: String = ""){ OpTwoToOne(XOR, lhs, rhs, port, name) }

external func NandGate(input!: Hypergraph = Identity(2), port!: String = "", name!: String = "") { OpTwoToOne(NAND, input, port, name) }
external func NandGate(lhs!: Hypergraph, rhs!: Hypergraph, port!: String = "", name!: String = ""){ OpTwoToOne(NAND, lhs, rhs, port, name) }

external func NorGate(input!: Hypergraph = Identity(2), port!: String = "", name!: String = "") { OpTwoToOne(NOR, input, port, name) }
external func NorGate(lhs!: Hypergraph, rhs!: Hypergraph, port!: String = "", name!: String = ""){ OpTwoToOne(NOR, lhs, rhs, port, name) }

external func XnorGate(input!: Hypergraph = Identity(2), port!: String = "", name!: String = "") { OpTwoToOne(XNOR, input, port, name) }
external func XnorGate(lhs!: Hypergraph, rhs!: Hypergraph, port!: String = "", name!: String = ""){ OpTwoToOne(XNOR, lhs, rhs, port, name) }

external func Delay(n : Int64, input!: Hypergraph = Identity(1), port!: String = "", name!: String = "") { OpOneToOne(DELAY(n), input, port, name) }

external func InLink(spec : LinkSpec, input!: Hypergraph = Identity(spec.width), name!:String = "") { OpOneToZero(INLINK(spec), input, name) }
external func OutLink(spec : LinkSpec, port!: String, name!:String = "") { OpZeroToOne(INLINK(spec), port, name) }


external func Input(port!: String, width!: Int64 = 1){
    if(width < 1){
        throw NegativeWireException()
    }
    Identity(width, port: port)
}

external func TestComponents() {
    let n = 3
    let fs : ArrayList<Hypergraph> = ArrayList<Hypergraph>([Copy(n), Par(Erase(n), Identity(n)), Par(Identity(n), Init(n)), Merge(n)])
    let graph = Seq(fs)
    print(DotGraph(graph))
    return 0
}

