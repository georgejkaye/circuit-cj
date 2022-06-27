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

/**
 * Unary gates
 */

public let BUF : Label = PRIMITIVE(GateSpecification("BUF", 1))
public let NOT : Label = PRIMITIVE(GateSpecification("NOT", 1))

/**
 * Binary gates
 */

public let AND  : Label = PRIMITIVE(GateSpecification("AND", 2))
public let OR   : Label = PRIMITIVE(GateSpecification("OR", 2))
public let NAND : Label = PRIMITIVE(GateSpecification("NAND", 2))
public let NOR  : Label = PRIMITIVE(GateSpecification("NOR", 2))
public let XOR  : Label = PRIMITIVE(GateSpecification("XOR", 2))
public let XNOR : Label = PRIMITIVE(GateSpecification("XNOR", 2))

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