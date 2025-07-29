/**
 * syntax/variable.cj
 *
 * Contains the definition of Variable inputs, which can take multiple values.
 *
 * @author George Kaye
 * @since 0.3
 */
package circuitcj.syntax

import std.collection.{HashSet,HashMap}

import circuitcj.utils.{collectionToString,arrayToString,map,GetAllCombinations,IncompatibleVariantException,mapi}
/**
 * A variable that could be multiple signals.
 */
public struct Variable<V> where V <: ValueSymbol<V> {
    static var nextId : Int64 = 0
    let id : Int64
    let width : Int64
    public Variable(
        public let possibleSignals : HashSet<Signal<V>>
    ){
        this.id = nextId
        this.width = AssertAllHaveSameWidth(possibleSignals)
        nextId++
    }
    public func GetId() : Int64 {
        this.id
    }
}
extend<V> Variable<V> <: Hashable {
    public func hashCode() : Int64 {
        this.id
    }
}
extend<V> Variable<V> <: ToString {
    public func toString() : String {
        let setString = collectionToString(
            this.possibleSignals, openingBracket: "{", closingBracket: "}"
        )
        "v${this.id}: ${setString}"
    }
}
extend<V> Variable<V> <: HasName {
    public func GetName() : String {
        this.toString()
    }
}
extend<V> Variable<V> <: HasWidth {
    public func GetWidth() : Int64 {
        this.width
    }
}
extend<V> Variable<V> <: Equatable<Variable<V>> {
    public operator func ==(rhs : Variable<V>) {
        this.id == rhs.id
    }
    public operator func !=(rhs : Variable<V>) {
        !(this == rhs)
    }
}
/**
 * A value that depends on a single index of a variable.
 */
public struct VariableValue<V> where V <: ValueSymbol<V> {
    public VariableValue(
        let dependentVariables : HashMap<Int64, Variable<V>>,
        let variableFn : (HashMap<Int64, Signal<V>>) -> V
    ){}
    public init(
        dependentVariables : HashSet<Variable<V>>,
        variableFn : (HashMap<Int64, Signal<V>>) -> V
    ){
        this.dependentVariables = HashMap()
        for(variable in dependentVariables) {
            this.dependentVariables.put(variable.id, variable)
        }
        this.variableFn = variableFn
    }
    public func GetVariableFn() : (HashMap<Int64, Signal<V>>) -> V {
        this.variableFn
    }
}
extend<V> VariableValue<V> <: HasWidth {
    public func GetWidth() : Int64 {
        1
    }
}
extend<V> VariableValue<V> <: ToString {
    public func toString() : String {
        "depends on ${this.dependentVariables}"
    }
}
extend<V> VariableValue<V> <: HasName {
    public func GetName() : String {
        this.toString()
    }
}
/**
 * Given a list of variable values, get a set of variables that they depend on.
 *
 * @param values
 * @return the set
 */
func GetDependentVariables<V>(
    values : Array<VariableValue<V>>
) : HashMap<Int64, Variable<V>> where V <: ValueSymbol<V> {
    let dependentVariables = HashMap<Int64, Variable<V>>()
    for(value in values) {
        dependentVariables.putAll(value.dependentVariables)
    }
    dependentVariables
}
/**
 * Given an array of varaible values and an assignment of a set of variables,
 * compute the concrete signal.
 *
 * @param variableValues
 * @param assignment
 * @param dependentVariablesMap
 * @return the signal
 */
func ComputePotentialSignal<V>(
    variableValues : Array<VariableValue<V>>,
    assignment : HashMap<Int64, Signal<V>>
) : Signal<V> where V <: ValueSymbol<V> {
    let values = mapi<VariableValue<V>, V>(
        { pv : VariableValue<V>, i : Int64 =>
            pv.variableFn(assignment)
        }, variableValues
    )
    Signal(values)
}
/**
 * A signal in which each bit is a variable value
 */
public struct VariableSignal<V> where V <: ValueSymbol<V> {
    // The set of variables that this signal depends on
    let dependentVariables : HashMap<Int64, Variable<V>>
    // The set of signals that this variable could be instantiated to
    let potentialSignals : HashSet<Signal<V>> = HashSet()
    public VariableSignal(
        let variableValues : Array<VariableValue<V>>
    ){
        let dependentVariables = GetDependentVariables(variableValues)
        this.dependentVariables = dependentVariables
        // Assign an arbitrary order to the shifting variables
        let combinations =
            GetAllCombinations(
                dependentVariables, { v : Variable<V> => v.possibleSignals }
            )
        for(assg in combinations) {
            let signal = ComputePotentialSignal(variableValues, assg)
            potentialSignals.put(signal)
        }
    }
    public func GetValues() : Array<VariableValue<V>> {
        this.variableValues
    }
    public func GetDependentVariables() :  HashMap<Int64, Variable<V>> {
        this.dependentVariables
    }
    public func GetPotentialSignals() : HashSet<Signal<V>> {
        this.potentialSignals
    }
    /**
     * Given an assignment of variables, produce the signal for this assignment.
     *
     * @param assignment
     */
    public func GetSignalForAssignment(
        assignment : HashMap<Int64, Signal<V>>
    ) : Signal<V> {
        let values = map({
            v : VariableValue<V> => v.GetVariableFn()(assignment)
        }, this.variableValues)
        Signal(values)
    }
}
extend<V> VariableSignal<V> <: HasWidth {
    public func GetWidth() : Int64 {
        this.variableValues.size
    }
}
extend<V> VariableSignal<V> <: ToString {
    public func toString() : String {
        collectionToString(
            this.GetPotentialSignals(), openingBracket: "{",
            closingBracket: "}", delimiter: "/"
        )
    }
}
extend<V> VariableSignal<V> <: HasName {
    public func GetName() : String {
        this.toString()
    }
}
extend<V> VariableSignal<V> <: Equatable<VariableSignal<V>> {
    public operator func ==(rhs : VariableSignal<V>) {
        this.dependentVariables == rhs.dependentVariables
    }
    public operator func !=(rhs : VariableSignal<V>) {
        !(this == rhs)
    }
}
/**
 * Inputs we can provide to perform a cycle
 */
public enum CycleInput<V> where V <: ValueSymbol<V> {
    | DEFINITE(Signal<V>)
    | PARTIAL(VariableSignal<V>)
}
extend<V> CycleInput<V> <: HasWidth {
    public func GetWidth() {
        match(this) {
            case DEFINITE(s) => s.GetWidth()
            case PARTIAL(pi) => pi.GetWidth()
        }
    }
}
extend<V> CycleInput<V> <: HasName {
    public func GetName() : String {
        match(this) {
            case DEFINITE(s) => s.GetName()
            case PARTIAL(pi) => pi.GetName()
        }
    }
}
extend<V> CycleInput<V> <: ToString {
    public func toString() : String {
        match(this) {
            case DEFINITE(s) => "definitely ${s.GetName()}"
            case PARTIAL(p) => "maybe ${p.GetName()}"
        }
    }
}
extend<V> CycleInput<V> <: Equatable<CycleInput<V>> {
    public operator func ==(rhs : CycleInput<V>) : Bool {
        match(this) {
            case DEFINITE(s) => match(rhs) {
                case DEFINITE(t) => s == t
                case _ => false
            }
            case PARTIAL(p) => match(rhs) {
                case PARTIAL(q) => p == q
                case _ => false
            }
        }
    }
    public operator func !=(rhs : CycleInput<V>) : Bool {
        !(this == rhs)
    }
}
extend<V> CycleInput<V> {
    public func GetDefinite() : Signal<V> {
        match(this) {
            case DEFINITE(s) => s
            case PARTIAL(_) =>
                throw IncompatibleVariantException(this, "DEFINITE")
        }
    }
    public func GetSignalForAssignment(
        assignment : HashMap<Int64, Signal<V>>
    ) : Signal<V> {
        match(this) {
            case DEFINITE(s) => s
            case PARTIAL(p) => p.GetSignalForAssignment(assignment)
        }
    }
}
public func GetDefinite<V>(ci : CycleInput<V>) : Signal<V>
    where V <: ValueSymbol<V>
{
    ci.GetDefinite()
}
public func GetSignalForAssignment<V>(
    assignment : HashMap<Int64, Signal<V>>, ci : CycleInput<V>
) : Signal<V> where V <: ValueSymbol<V> {
    ci.GetSignalForAssignment(assignment)
}