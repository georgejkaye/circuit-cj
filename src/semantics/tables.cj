/**
 * semantics/tables.cj
 *
 * Definition of truth tables for evaluating gates
 *
 * @author George Kaye
 * @since 0.1
 */

package semantics

import syntax.*
import assertions.*

/**
 * Truth table class, to store the results of applying arguments to gates
 */
class TruthTable {
    let generator : Label
    let table : (Array<Value>) -> Array<Value>
    init(generator : Label, table : (Array<Value>) -> Array<Value>) {
        this.generator = generator
        this.table = table
    }
    /**
     * Evaluate a list of value arguments according to this truth table
     * Throws an exception if the number of arguments is incompatible with this truth table
    * @param args The list of arguments
     */
    func Eval(args : Array<Value>) : Value {
        AssertArrayHasLength(args, generator.GetNoInputs())
        table(args)
    }
}

let bufTable  = TruthTable(PRIMITIVE(BUF) , {args : Array<Value> => [args[0]]})
let notTable  = TruthTable(PRIMITIVE(NOT) , {args : Array<Value> => [not(args[0])]})
let andTable  = TruthTable(PRIMITIVE(AND) , {args : Array<Value> => [and(args[0], args[1])]})
let orTable   = TruthTable(PRIMITIVE(OR)  , {args : Array<Value> => [or(args[0], args[1])]})
let nandTable = TruthTable(PRIMITIVE(NAND), {args : Array<Value> => [not(and(args[0], args[1]))]})
let norTable  = TruthTable(PRIMITIVE(NOR) , {args : Array<Value> => [not(or(args[0], args[1]))]})
let xorTable  = TruthTable(PRIMITIVE(XOR) , {args : Array<Value> => [xor(args[0], args[1])]})
let xnorTable = TruthTable(PRIMITIVE(XNOR), {args : Array<Value> => [not(xor(args[0], args[1]))]})