/**
 * generators.cj
 *
 * This file contains the definition of generators (in the free categorical sense)
 * and also defines preset generators for the user
 */

package circuits

/**
 * Truth table class, to store the results of applying arguments to gates
 */
class TruthTable {
    let generator : Generator
    let table : (ArrayList<Value>) -> Value
    init(generator : Generator, table : (ArrayList<Value>) -> Value) {
        this.generator = generator
        this.table = table
    }
    /**
     * Evaluate a list of value arguments according to this truth table
     * Throws an exception if the number of arguments is incompatible with this truth table
     * @param args The list of arguments
     */
    func Eval(args : ArrayList<Value>){
        if(args.size() != Dom(generator)){
            throw BadDomainException("Eval", args.size(), Dom(generator))
        }
        table(args)
    }
}
/**
 * There are three types of structural morphisms to fork, join and stub wires
 */
enum Struct { ForkMorph | JoinMorph | StubMorph }
extend Struct <: ToString {
    func toString() : String {
        match(this){
            case $ForkMorph => "fork"
            case $JoinMorph => "join"
            case $StubMorph => "stub"
        }
    }
}
extend Struct <: Equatable {
    operator func ==(rhs: Struct){
        match(this){
            case $ForkMorph =>
                match(rhs) {
                    case $ForkMorph => true
                    case _ => false
                }
            case $JoinMorph =>
                match(rhs) {
                    case $JoinMorph => true
                    case _ => false
                }
            case $StubMorph =>
                match(rhs) {
                    case $StubMorph => true
                    case _ => false
                }
        }
    }
    operator func !=(rhs: Struct) { !(this == rhs) }
}
/**
 * Labels have a name, domain and codomain
 */
class Label {
    let name : String
    let dom : Int64
    let cod : Int64
    init(name : String, dom : Int64, cod : Int64) {
        if(dom < 0 || cod < 0){
            throw NegativeWireException("Label")
        }
        this.name = name
        this.dom = dom
        this.cod = cod
    }
    func GetString() { "Label ${name} : ${dom} → ${cod}" }
}
extend Label <: Equatable {
    operator func ==(rhs: Label) : Bool { this.name == rhs.name && this.dom == rhs.dom && this.cod == rhs.cod }
    operator func !=(rhs: Label) : Bool { !(this == rhs) }
}

/**
 * A link spec contains information about a link
 * It has an id, a name, and a width 
 */
class LinkSpec <: Identifiable {
    let name : String
    let width : Int64
    init(name : String, width : Int64) {
        this.name = name
        this.width = width
    }
    init(width : Int64) {
        this.name = "ls${this.id}"
        this.width = width
    }
}
extend LinkSpec <: Equatable {
    operator func ==(rhs : LinkSpec){
        this.name == rhs.name && this.width == rhs.width
    }
    operator func !=(rhs : LinkSpec){
        !(this == rhs)
    }
}
extend LinkSpec <: ToString{
    func toString(){
        "LinkSpec - ${name} width ${width}"
    }
}
/**
 * Enum for the different types of generators
 */
enum Generator { 
    | VALUE(Value)            // A value 0 -> 1
    | STRUCTURAL(Struct)      // A structural generator 
    | GATE(Label)             // A gate m -> 1
    | DELAY(Int64)            // A delay parameterised by a duration
    | IDENTITY                // An identity 1 -> 1
    | INLINK(LinkSpec)        // An in-link 0 -> m, where wires come into the graph
    | OUTLINK(LinkSpec)       // An out-link m -> 0, where wires come out of the graph
}
extend Generator <: ToString {
    func toString(){
        match(this){
            case VALUE(value)        => "value (${value})"
            case STRUCTURAL(struct)  => "structural (${struct})"
            case GATE(label)         => "gate (${label.name})"
            case DELAY(dur)          => "delay (${dur})"
            case $IDENTITY           => "identity"
            case INLINK(spec)        => "in link (${spec.name} - ${spec.width})"
            case OUTLINK(spec)       => "out link (${spec.name} - ${spec.width})"
        }
    }
}
// TODO I believe enums will come with Equatable out of the box at some point
extend Generator <: Equatable {
    operator func ==(g2 : Generator) : Bool {
        match(this){
            case VALUE(v1) =>
                match(g2){
                    case VALUE(v2) => v1 == v2
                    case _ => false
                }
            case STRUCTURAL(s1) =>
                match(g2) {
                    case STRUCTURAL(s2) => s1 == s2
                    case _ => false
                }
            case GATE(l1) =>
                match(g2) {
                    case GATE(l2) => l1 == l2
                    case _ => false
                }
            case DELAY(d1) =>
                match(g2) {
                    case DELAY(d2) => d1 == d2
                    case _ => false
                }
            case $IDENTITY =>
                match(g2) {
                    case $IDENTITY => true
                    case _ => false
                }
            case INLINK(s1) =>
                match(g2) {
                    case INLINK(s2) => s1 == s2
                    case _ => false
                }
            case OUTLINK(s1) =>
                match(g2) {
                    case OUTLINK(s2) => s1 == s2
                    case _ => false
                }
        }
    }
    operator func !=(g2 : Generator) { !(this == g2) }
}
/** 
 * Get the signature of a generator, the pair of its domain and codomain
 */
func Signature(gen : Generator) : Int64 * Int64 {
    match(gen){
        case VALUE(val)         => (0,1)
        case STRUCTURAL(struct) =>
            match(struct) {
                case $ForkMorph => (1,2)
                case $JoinMorph => (2,1)
                case $StubMorph => (1,0)
            }
        case GATE(label)        => (label.dom, label.cod)
        case DELAY(dur)         => (1,1)
        case $IDENTITY          => (1,1)
        case INLINK(spec)       => (0, spec.width)
        case OUTLINK(spec)      => (spec.width, 0)
    }
}
/**
 * Get the domain of a generator
 */
func Dom(gen : Generator){
    Signature(gen)[0]
}
/**
 * Get the codomain of a generator
 */
func Cod(gen : Generator){
    Signature(gen)[1]
}
/**
 * Check if a port is connected to a given generator 
 * @param p   The port
 * @param gen The generator to check for
 * @return The edge if it is the correct generator, or None otherwise.
 */
func PortToGenerator(p : Port, gen : Generator) : Option<Edge * Int64> {
    match(p){
        case EdgePort(e, i) =>
            if(e.generator == gen){
                Some<Edge * Int64>((e, i))
            } else {
                None<Edge * Int64>
            }
        case InterfacePort(i) =>
            None<Edge * Int64>
    }
}
/**
 * Check if a port is on a given generator
 * @param p   The port
 * @param gen The desired generator
 * @return Whether port p connects to an edge with generator gen
 */
func IsPortToGenerator(p : Port, gen : Generator) {
    match(PortToGenerator(p, gen)){
        case Some((e, i)) => true
        case $None        => false
    }
}
/**
 * Check if a port connects to an endpoint: a generator with codomain of 0
 * @param p The port
 * @return Either the edge and its index if it is an endpoint, or None otherwise
 */
func PortToEndpoint(p : Port){
    match(p) {
        case EdgePort(e, i) =>
            if(Cod(e.generator) == 0){
                Some<Edge * Int64>((e, i))
            } else {
                None<Edge * Int64>
            }
        case InterfacePort(i) => None<Edge * Int64>

    }
}
/**
 * Check if a given generator is an inlink
 * @param gen The generator
 * @return Whether the generator is an inlink
 */
func IsInlink(gen : Generator){
    match(gen){
        case INLINK(spec) => true
        case _ => false
    }
}
/**
 * Check if a given generator is an outlink
 * @param gen The generator
 * @return Whether the generator is an outlink
 */
func IsOutlink(gen : Generator){
    match(gen){
        case OUTLINK(spec) => true
        case _ => false
    }
}
/**
 * Check if a given generator is a value
 * @param gen The generator
 * @return Whether the generator is a value
 */
func IsValue(gen : Generator){
    match(gen){
        case VALUE(v) => true
        case _        => false
    }
}
/**
 * Check if a given generator is a gate
 * @param gen The generator
 * @return Whether the generator is a gate
 */
func IsGate(gen : Generator){
    match(gen){
        case GATE(k) => true
        case _       => false
    }
}

/**
 * Structural generators
 */

let FORK : Generator = STRUCTURAL(ForkMorph)

let JOIN : Generator = STRUCTURAL(JoinMorph)
let joinTable = TruthTable(JOIN, {args : ArrayList<Value> => join(args[0], args[1])})

let STUB : Generator = STRUCTURAL(StubMorph)

func IsStub(e : Edge){
    match(e.generator){
        case STRUCTURAL(label) =>
            match(label){
                case $StubMorph => true
                case _          => false
            }
        case _ => false
    }
}

/**
 * Unary gates
 */

let BUF : Generator = GATE(Label("BUF", 1, 1))
let NOT : Generator = GATE(Label("NOT", 1, 1))

/**
 * Binary gates
 */

let AND : Generator = GATE(Label("AND", 2, 1))
let andTable = TruthTable(AND, {args : ArrayList<Value> => and(args[0], args[1])})

let OR : Generator = GATE(Label("OR", 2, 1))
let orTable = TruthTable(OR, {args : ArrayList<Value> => or(args[0], args[1])})

let NAND : Generator = GATE(Label("NAND", 2, 1))
let nandTable = TruthTable(NAND, {args : ArrayList<Value> => not(and(args[0], args[1]))})

let NOR  : Generator = GATE(Label("NOR", 2, 1))
let norTable = TruthTable(NOR, {args : ArrayList<Value> => not(or(args[0], args[1]))})

let XOR  : Generator = GATE(Label("XOR", 2, 1))
let xorTable = TruthTable(XOR, {args : ArrayList<Value> => xor(args[0], args[1])})

let XNOR : Generator = GATE(Label("XNOR", 2, 1))
let xnorTable = TruthTable(XNOR, {args : ArrayList<Value> => not(xor(args[0], args[1]))})

/**
 * Ternary gates
 */
 
let MUX : Generator = GATE(Label("mux", 3, 1))