/**
 * syntax/variable.cj
 *
 * Contains the definition of Variable inputs, which can take multiple values.
 *
 * @author George Kaye
 * @since 0.3
 */
package syntax
/**
 * A variable that could be multiple signals.
 */
public struct Variable<V> where V <: ValueSymbol<V> {
    static var nextId : Int64 = 0
    public let id : Int64
    public let width : Int64
    public Variable(
        public let possibleSignals : HashSet<Signal<V>>
    ){
        this.id = nextId
        this.width = AssertAllHaveSameWidth(possibleSignals)
        nextId++
    }
}
extend Variable<V> <: Hashable {
    public func hashCode() : Int64 {
        this.id
    }
}
extend Variable<V> <: ToString {
    public func toString() : String {
        let setString = collectionToString(
            this.possibleSignals, openingBracket: "{", closingBracket: "}"
        )
        "v${this.id}: ${setString}"
    }
}
extend Variable<V> <: HasName {
    public func GetName() : String {
        this.toString()
    }
}
extend Variable<V> <: HasWidth {
    public func GetWidth() : Int64 {
        this.width
    }
}
extend Variable<V> <: Equatable<Variable<V>> {
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
        public let variable : Variable<V>,
        public let index : Int64
    ){}
}
extend VariableValue<V> <: HasWidth {
    public func GetWidth() : Int64 {
        1
    }
}
extend VariableValue<V> <: ToString {
    public func toString() : String {
        "${this.variable.toString()}[${this.index}]"
    }
}
extend VariableValue<V> <: HasName {
    public func GetName() : String {
        this.toString()
    }
}
extend VariableValue<V> <: Equatable<VariableValue<V>> {
    public operator func ==(rhs : VariableValue<V>) : Bool {
        this.variable == rhs.variable && this.index == rhs.index
    }
    public operator func !=(rhs : VariableValue<V>) : Bool {
        !(this == rhs)
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
) : HashSet<Variable<V>> where V <: ValueSymbol<V> {
    let dependentVariables = HashSet<Variable<V>>()
    for(value in values) {
        let variable = value.variable
        dependentVariables.put(variable)
    }
    dependentVariables
}
/**
 * Given a set of variables, generate all the combinations they can be
 * concretely instantiated to. Since we assign an arbitrary order to the
 * variables in the set, we also create a map from variable ids to their place
 * in the order.
 *
 * @param dependentVariables
 * @return (the combinations, the variable id map)
 */
func GetSignalCombinations<V>(
    dependentVariables : HashSet<Variable<V>>
) : (Array<Array<Signal<V>>>, HashMap<Int64, Int64>)
    where V <: ValueSymbol<V>
{
    let dependentVariablesArray = dependentVariables.toArray()
    let dependentVariableMap = HashMap<Int64, Int64>()
    let signalArray = mapi(
        { dvs : Variable<V>, i : Int64 =>
            dependentVariableMap.put(dvs.id, i)
            dvs.possibleSignals.toArray()
        }, dependentVariablesArray
    )
    (GetAllCombinations(signalArray), dependentVariableMap)
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
    assignment : Array<Signal<V>>,
    dependentVariablesMap : HashMap<Int64, Int64>
) : Signal<V> where V <: ValueSymbol<V> {
    let values = mapi(
        { pv : VariableValue<V>, i : Int64 =>
            let id = pv.variable.id
            let variableIndex =
                dependentVariablesMap.get(id).getOrThrow()
            assignment[variableIndex].GetBit(pv.index)
        }, variableValues
    )
    Signal(values)
}
/**
 * A signal in which each bit is a variable value
 */
public struct VariableSignal<V> where V <: ValueSymbol<V> {
    // The set of variables that this signal depends on
    let dependentVariables : HashSet<Variable<V>>
    // The set of signals that this variable could be instantiated to
    let potentialSignals : HashSet<Signal<V>> = HashSet()
    public VariableSignal(
        let variableValues : Array<VariableValue<V>>
    ){
        let dependentVariables = GetDependentVariables(variableValues)
        this.dependentVariables = dependentVariables
        // Assign an arbitrary order to the shifting variables
        let (combinations, dependentVariablesMap) =
            GetSignalCombinations(dependentVariables)
        for(assg in combinations) {
            let signal = ComputePotentialSignal(
                variableValues, assg, dependentVariablesMap
            )
            potentialSignals.put(signal)
        }
    }
    public func GetValues() : Array<VariableValue<V>> {
        this.variableValues
    }
    public func GetPotentialSignals() : HashSet<Signal<V>> {
        this.potentialSignals
    }
}
extend VariableSignal<V> <: HasWidth {
    public func GetWidth() : Int64 {
        this.variableValues.size
    }
}
extend VariableSignal<V> <: ToString {
    public func toString() : String {
        collectionToString(
            this.GetPotentialSignals(), openingBracket: "{",
            closingBracket: "}", delimiter: "/"
        )
    }
}
extend VariableSignal<V> <: HasName {
    public func GetName() : String {
        this.toString()
    }
}
extend VariableSignal<V> <: Equatable<VariableSignal<V>> {
    public operator func ==(rhs : VariableSignal<V>) : Bool {
        this.variableValues == rhs.GetValues()
    }
    public operator func !=(rhs : VariableSignal<V>) : Bool {
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
extend CycleInput<V> <: HasWidth {
    public func GetWidth() {
        match(this) {
            case DEFINITE(s) => s.GetWidth()
            case PARTIAL(pi) => pi.GetWidth()
        }
    }
}
extend CycleInput<V> <: HasName {
    public func GetName() : String {
        match(this) {
            case DEFINITE(s) => s.GetName()
            case PARTIAL(pi) => pi.GetName()
        }
    }
}
extend CycleInput<V> <: ToString {
    public func toString() : String {
        match(this) {
            case DEFINITE(s) => "definitely ${s.GetName()}"
            case PARTIAL(p) => "maybe ${p.GetName()}"
        }
    }
}