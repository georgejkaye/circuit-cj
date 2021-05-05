/**
 * generators.cj
 *
 * This file contains the definition of generators (in the free categorical sense)
 * and also defines preset generators for the user
 */

package hypergraphs

/**
 * We use a value lattice with four values
 * ⊥ < t,f < ⊤
 */
enum Value { BOTTOM | TRUE | FALSE | TOP }
append Value with ToString {
    func toString(v : Value) {
        match(v){
            case $BOTTOM => "bot"
            case $TRUE   => "t"
            case $FALSE  => "f"
            case $TOP    => "top"
        }
    }
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
}
append Label with ToString {
    func toString(l : Label) { "Label ${l.id} - ${l.name} : ${l.dom} → ${l.cod}" }
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
}
append LinkSpec with ToString {
    func toString(spec : LinkSpec) { "LinkSpec ${spec.id} - ${spec.name} width ${spec.width}" }
}

/**
 * Enum for the different types of generators
 */
external enum Generator { 
    | VALUE(Value)            // A value 0 -> 1
    | STRUCTURAL(Label)       // A structural generator 
    | GATE(Label)             // A gate m -> 1
    | DELAY(Int64)            // A delay parameterised by a duration
    | IDENTITY                // An identity 1 -> 1
    | INLINK(LinkSpec)        // An in-link 0 -> m, where wires come into the graph
    | OUTLINK(LinkSpec)       // An out-link m -> 0, where wires come out of the graph
}
append Generator with ToString{
    func toString(gen : Generator){
        match(gen){
            case VALUE(value)        => "value (${value})"
            case STRUCTURAL(label)   => "structural (${label.name})"
            case GATE(label)         => "gate (${label.name})"
            case DELAY(dur)          => "delay (${dur})"
            case $IDENTITY           => "identity"
            case INLINK(spec)        => "in link (${spec.name} - ${spec.width})"
            case OUTLINK(spec)       => "out link (${spec.name} - ${spec.width})"
        }
    }
}

/**
 * Structural generators
 */

external let FORK : Generator = STRUCTURAL(Label("fork", 1, 2))
external let JOIN : Generator = STRUCTURAL(Label("join", 2, 1))
external let STUB : Generator = STRUCTURAL(Label("stub", 1, 0))

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