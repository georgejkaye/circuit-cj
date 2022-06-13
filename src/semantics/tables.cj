package semantics

import syntax.*

/**
 * Truth table class, to store the results of applying arguments to gates
 */
class TruthTable {
    let generator : Label
    let table : (ArrayList<Value>) -> Value
    init(generator : Label, table : (ArrayList<Value>) -> Value) {
        this.generator = generator
        this.table = table
    }
    /**
     * Evaluate a list of value arguments according to this truth table
     * Throws an exception if the number of arguments is incompatible with this truth table
    * @param args The list of arguments
     */
    func Eval(args : ArrayList<Value>){
        if(args.size() != generator.GetInputs()){
            throw BadDomainException("Eval", generator, args.size(), generator.GetInputs())
        }
        table(args)
    }
}

let bufTable = TruthTable(BUF, {args : ArrayList<Value> => args[0]})
let notTable = TruthTable(NOT, {args : ArrayList<Value> => not(args[0])})
let andTable = TruthTable(AND, {args : ArrayList<Value> => and(args[0], args[1])})
let orTable = TruthTable(OR, {args : ArrayList<Value> => or(args[0], args[1])})
let nandTable = TruthTable(NAND, {args : ArrayList<Value> => not(and(args[0], args[1]))})
let norTable = TruthTable(NOR, {args : ArrayList<Value> => not(or(args[0], args[1]))})
let xorTable = TruthTable(XOR, {args : ArrayList<Value> => xor(args[0], args[1])})
let xnorTable = TruthTable(XNOR, {args : ArrayList<Value> => not(xor(args[0], args[1]))})