package hypergraphs

import core.*

enum Value { BOTTOM | TRUE | FALSE | TOP }

append Value with ToString {
    func toString(v : Value) {
        match(v){
            case .BOTTOM => "⊥"
            case .TRUE   => "t"
            case .FALSE  => "f"
            case .TOP    => "⊤"
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
            throw NegativeWireException()
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
class LinkSpec <: Atom {
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

enum Generator { VALUE(Value) | STRUCTURAL(Label) | GATE(Label) | DELAY(Int64) | IDENTITY | INLINK(LinkSpec) | OUTLINK(LinkSpec) }
append Generator with ToString{
    func toString(gen : Generator){
        match(gen){
            case .VALUE(value)        => "value ${value}"
            case .STRUCTURAL(label)   => "structural ${label.name}"
            case .GATE(label)         => "gate ${label.name}"
            case .DELAY(dur)          => "delay ${dur}"
            case .IDENTITY            => "identity"
            case .INLINK(spec)        => "in link ${spec.name}"
            case .OUTLINK(spec)       => "out link ${spec.name}"
        }
    }
}

/**
 * Structural generators
 */

external let FORK : Generator = STRUCTURAL(Label("≺", 1, 2))
external let JOIN : Generator = STRUCTURAL(Label("≻", 2, 1))
external let STUB : Generator = STRUCTURAL(Label("~", 1, 0))

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