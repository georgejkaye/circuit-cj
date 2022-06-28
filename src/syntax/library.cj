/**
 * gates.cj
 *
 * This file contains some predefined gates
 */

package syntax

/**
 * Signals
 */

public let BOTTOM : Label = VALUE([Bottom], false)
public let FALSE : Label = VALUE([False], false)
public let TRUE : Label = VALUE([True], false)
public let TOP : Label = VALUE([Top], false)

func MakeGateLabel(name : String, m : Int64, w : Int64, defaultInputs : Int64) {
    let spec = Specification("${name}${m}_${w}", Array<Int64>(m){ i : Int64 => w }, [w])
    if (m == defaultInputs && w == 1){
        PRIMITIVE(spec)
    } else {
        COMPOSITE(spec)
    }
}

/**
 * Unary gates
 */

func MakeUnaryGateLabel(name : String, m : Int64, w : Int64) : Label {
    MakeGateLabel(name, m, w, 1)
}

public func BUF(w : Int64) : Label {
    MakeUnaryGateLabel("BUF", 1, w)
}
public func NOT(w : Int64) : Label {
    MakeUnaryGateLabel("NOT", 1, w)
}

/**
 * Binary gates
 *
 * Each gate has two parameters:
 * - how many wires it takes as inputs
 * - the width of each wire
 */

func MakeBinaryGateLabel(name : String, m : Int64, w : Int64) : Label {
    MakeGateLabel(name, m, w, 2)
}

public func AND(m : Int64, w : Int64) : Label {
    MakeBinaryGateLabel("and", m, w)
}
public func OR(m : Int64, w : Int64) : Label {
    MakeBinaryGateLabel("or", m, w)
}
public func NAND(m : Int64, w : Int64) : Label {
    MakeBinaryGateLabel("nand", m, w)
}
public func NOR(m : Int64, w : Int64) : Label {
    MakeBinaryGateLabel("nor", m, w)
}
public func XOR(m : Int64, w : Int64) : Label {
    MakeBinaryGateLabel("xor", m, w)
}
public func XNOR(m : Int64, w : Int64) : Label {
    MakeBinaryGateLabel("xnor", m, w)
}


/**
 * Composite specifications
 */

public func MUX(n : Int64, c : Int64, w : Int64) : Label {
    COMPOSITE(
        Specification(
            "mux${n}_${c}_${w}", 
            Array<Int64>(n + 1){ 
                i : Int64 => if (i == 0) { c } else { w }
            }, 
            [w]
        )
    )
}