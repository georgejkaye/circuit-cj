/**
 * generators.cj
 *
 * This file contains the definition of generators (in the free categorical sense)
 * and also defines preset generators for the user
 */

package circuits

/**
 * We use a value lattice with four values
 * ⊥ < t,f < ⊤
 */
enum Value { BOTTOM | TRUE | FALSE | TOP }
extend Value <: ToString {
    func toString() {
        match(this){
            case $BOTTOM => "bot"
            case $TRUE   => "t"
            case $FALSE  => "f"
            case $TOP    => "top"
        }
    }
}
append Value with Equatable {
    operator func ==(lhs : Value, rhs : Value){
        match(lhs){
            case $BOTTOM => {
                match(rhs){
                    case $BOTTOM => true
                    case _ => false
                }
            }
            case $TRUE => {
                match(rhs){
                    case $TRUE => true
                    case _ => false
                }
            }
            case $FALSE => {
                match(rhs){
                    case $FALSE => true
                    case _ => false
                }
            }
            case $TOP => {
                match(rhs){
                    case $TOP => true
                    case _ => false
                }
            }
        }
    }
    operator func !=(lhs : Value, rhs : Value) { !(lhs == rhs) }
}

enum Struct { ForkMorph | JoinMorph | StubMorph }
extend Struct <: ToString {
    func toString() {
        match(this){
            case $ForkMorph => "fork"
            case $JoinMorph => "join"
            case $StubMorph => "stub"
        }
    }
}
append Struct with Equatable {
    operator func ==(lhs : Struct, rhs: Struct){
        match(lhs){
            case $ForkMorph => {
                match(rhs) {
                    case $ForkMorph => true
                    case _ => false
                }
            }
            case $JoinMorph => {
                match(rhs) {
                    case $JoinMorph => true
                    case _ => false
                }
            }
            case $StubMorph => {
                match(rhs) {
                    case $StubMorph => true
                    case _ => false
                }
            }
        }
    }
    operator func !=(lhs : Struct, rhs: Struct) { !(lhs == rhs) }
}

/**
 * Labels have a name, domain and codomain
 */
class Label <: Atom {
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
    override func toString() { "Label ${id} - ${name} : ${dom} → ${cod}" }
}
append Label with Equatable {
    operator func ==(lhs: Label, rhs: Label) : Bool { lhs.name == rhs.name && lhs.dom == rhs.dom && lhs.cod == rhs.cod }
    operator func !=(lhs : Label, rhs: Label) : Bool { !(lhs == rhs) }
}

/**
 * A link spec contains information about a link
 * It has an id, a name, and a width 
 */
external class LinkSpec <: Atom {
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
    override func toString() { "LinkSpec ${id} - ${name} width ${width}" }
}
append LinkSpec with Equatable, Hashable {
    operator func ==(lhs : LinkSpec, rhs : LinkSpec) : Bool { lhs.id == rhs.id }
    operator func !=(lhs : LinkSpec, rhs : LinkSpec) : Bool { lhs.id != rhs.id }
    func hashCode(t : LinkSpec) : UInt64 { t.id }
}

/**
 * Enum for the different types of generators
 */
external enum Generator { 
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
append Generator with Equatable{
    operator func ==(g1 : Generator, g2 : Generator){
        match(g1){
            case VALUE(v1) => {
                match(g2){
                    case VALUE(v2) => v1 == v2
                    case _ => false
                }
            }
            case STRUCTURAL(s1) => {
                match(g2) {
                    case STRUCTURAL(s2) => s1 == s2
                    case _ => false
                }
            }
            case GATE(l1) => {
                match(g2) {
                    case GATE(l2) => l1 == l2
                    case _ => false
                }
            }
            case DELAY(d1) => {
                match(g2) {
                    case DELAY(d2) => d1 == d2
                    case _ => false
                }
            }
            case $IDENTITY => {
                match(g2) {
                    case $IDENTITY => true
                    case _ => false
                }
            }
            case INLINK(s1) => {
                match(g2) {
                    case INLINK(s2) => s1 == s2
                    case _ => false
                }
            }
            case OUTLINK(s1) => {
                match(g2) {
                    case OUTLINK(s2) => s1 == s2
                    case _ => false
                }
            }
        }
    }
    operator func !=(g1 : Generator, g2 : Generator) { !(g1 == g2) }
}

func Signature(gen : Generator){
    match(gen){
        case VALUE(val)         => (0,1)
        case STRUCTURAL(struct) => {
            match(struct) {
                case $ForkMorph => (1,2)
                case $JoinMorph => (2,1)
                case $StubMorph => (1,0)
            }
        }
        case GATE(label)        => (label.dom, label.cod)
        case DELAY(dur)         => (1,1)
        case $IDENTITY          => (1,1)
        case INLINK(spec)       => (0, spec.width)
        case OUTLINK(spec)      => (spec.width, 0)
    }
}

func Dom(gen : Generator){
    Signature(gen)[0]
}
func Cod(gen : Generator){
    Signature(gen)[1]
}

/**
 * Structural generators
 */

external let FORK : Generator = STRUCTURAL(ForkMorph)
external let JOIN : Generator = STRUCTURAL(JoinMorph)
external let STUB : Generator = STRUCTURAL(StubMorph)

func IsStub(e : Edge){
    match(e.generator){
        case STRUCTURAL(label) => {
            match(label){
                case $StubMorph => true
                case _          => false
            }
        }
        case _ => false
    }
}

/**
 * Unary gates
 */

external let BUF : Generator = GATE(Label("BUF", 1, 1))
external let NOT : Generator = GATE(Label("NOT", 1, 1))

/**
 * Binary gates
 */

external let AND  : Generator = GATE(Label("AND", 2, 1))
external let OR   : Generator = GATE(Label("OR", 2, 1))
external let NAND : Generator = GATE(Label("NAND", 2, 1))
external let NOR  : Generator = GATE(Label("NOR", 2, 1))
external let XOR  : Generator = GATE(Label("XOR", 2, 1))
external let XNOR : Generator = GATE(Label("XNOR", 2, 1))

/**
 * Ternary gates
 */
 
external let MUX : Generator = GATE(Label("mux", 3, 1))

/**
 * Check if a port is connected to a given generator 
 * @param p   The port
 * @param gen The generator to check for
 * @return The edge if it is the correct generator, or None otherwise.
 */
func PortToGenerator(p : Port, gen : Generator){
    match(p){
        case EdgePort(e, i) => {
            if(e.generator == gen){
                Some<Edge * Int64>((e, i))
            } else {
                None<Edge * Int64>
            }
        }
        case InterfacePort(i) => {
            None<Edge * Int64>
        }
    }
}

func IsPortToGenerator(p : Port, gen : Generator) {
    match(PortToGenerator(p, gen)){
        case Some((e, i)) => true
        case $None        => false
    }
}

func PortToEndpoint(p : Port){
    match(p) {
        case EdgePort(e, i) => {
            if(Cod(e.generator) == 0){
                Some<Edge * Int64>((e, i))
            } else {
                None<Edge * Int64>
            }
        }
        case InterfacePort(i) => {
            None<Edge * Int64>
        }
    }
}