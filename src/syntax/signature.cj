/**
 * syntax/signature.cj
 *
 * Definition of signatures, containing components in a circuit
 *
 * @author George Kaye
 * @since 0.3
 */
package syntax
from std import collection.HashSet, collection.HashMap
import debug.*
/**
 * Interface for symbols that represent values.
 *
 * HACK: Ideally we don't want to have to specify the generic V: it should
 * always be the same type that is being extended by ValueSymbol i.e.
 * Value <: ValueSymbol<Value>, but I don't know if this is possible.
 */
public interface ValueSymbol<V>
    <: Hashable & Equatable<V> & LessOrEqual<V> & HasName & ToString
{
    /**
     * Get the distinguished value that marks the disconnected value.
     *
     * @return The disconnected value
     */
    static func GetDisconnected() : V
    /**
     * Get the level at which this value should be drawn in waveform
     * visualisation. The higher the number, the higher on the screen the value
     * will be drawn. If None, the value will not be drawn in the waveform and
     * the screen will be left blank (this value is not interesting for
     * visualisation).
     *
     * @return The waveform level, or None
     */
    func GetWaveformLevel() : Option<Int64>
    /**
     * Get the highest point at which a value can be drawn in waveform
     * visualisation.
     *
     * @return The highest waveform level
     */
    static func GetWaveformHeight() : Int64
}
public interface PrimitiveSymbol<V, G>
    <: Hashable & Equatable<G> & HasName & ToString & Specifiable
    where V <: ValueSymbol<V>
{}
/**
 * Check that a truth table is monotone with relation to the information order,
 * i.e. if v <= w then f(v) <= f(w).
 *
 * Throws a NonMonotoneFunctionException if it is not.
 *
 * @param lattice
 * @param ports
 * @param table
 */
func AssertTableMonotone<V>(
    lattice : FiniteLattice<V>,
    ports : Array<Port>,
    table : (Array<Signal<V>>) -> (Array<Signal<V>>)
) : Unit where V <: ValueSymbol<V> {
    let inputs = lattice.EnumerateInputs(ports)
    for(input1 in inputs) {
        for(input2 in inputs) {
            if (lattice.LTE(input1, input2)) {
                let result1 = table(input1)
                let result2 = table(input2)
                if(!lattice.LTE(result1, result2)){
                    throw IncompatibleParameterException(
                        "Assertion failed: table must be monotone." +
                        "${input1} is less than ${input2} but f(${input1}) = " +
                        "${result1} is not less than f(${input2}) = ${result2}."
                    )
                }
            }
        }
    }
}
/**
 * Struct for storing data about an annihilator, a particular input to a gate
 * that forces its output to be constant regardless of the other inputs
 */
public struct Annihilator<V, G> <: ToString
     where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    public Annihilator(
        public let gate : G,
        public let input : Signal<V>,
        public let index : Int64,
        public let output : Array<Signal<V>>
    ){}
    public func toString() {
        var string = "${this.gate.GetName()}("
        for(i in 0..index) {
            string = "${string}-, "
        }
        string = "${string}${input}, "
        let afterEndIndex = this.gate.GetCoarity() -
            if(index == this.gate.GetCoarity() - 1) {
                2
            } else {
                1
            }
        for(i in (this.index + 1)..afterEndIndex){
            string = "${string} -, "
        }
        "${string}-) = ${this.output}"
    }
}
/**
 * Struct for storing data about an identifier, a particular input to a gate
 * that forces its behaviour to be the identity on the other inputs.
 */
public struct Identifier<V, G> <: ToString
     where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    public Identifier(
        public let gate : G,
        public let input : Signal<V>,
        public let index : Int64
    ){}
    public func toString() {
        var string = "${this.gate.GetName()}("
        var beforeIndexString = ""
        for(i in 0..index) {
            beforeIndexString = "${beforeIndexString}x${i}, "
        }
        var afterIndexString = ""
        let afterEndIndex = this.gate.GetCoarity() -
            if(index == this.gate.GetCoarity() - 1) {
                2
            } else {
                1
            }
        for(i in this.index+1..afterEndIndex){
            afterIndexString = "${afterIndexString}x${i}, "
        }
        if(index == gate.GetCoarity() - 1) {
            afterIndexString =
                "${afterIndexString}x${gate.GetCoarity() - afterEndIndex}"
        }
        let input = "(${beforeIndexString}${input}, ${afterIndexString})"
        let outputBeforeString = if(index == 0) {
            ""
        } else {
            "${beforeIndexString}, "
        }
        let output = "(${outputBeforeString}${afterIndexString})"
        "${this.gate.GetName()}${input} = ${output}"
    }
}
/**
 * For a given gate and interpretation, find the inputs are annihilators
 * and identifiers, if any exist.
 *
 * Note that although there is a lot of iterating over nested loops here, this
 * is only done on initialisation of a signature, so it should be a one time
 * cost.
 *
 * @param gate
 * @param latticeStructure
 * @param gateInterpretation
 * @param annihilatiorsList list to store the annihilators in
 * @param identitiesList list to store the identities in
 */
func GetAnnihilatorAndIdentifierRules<V, G>(
    gate : G,
    latticeStructure : FiniteLattice<V>,
    gateInterpretation : (Array<Signal<V>>) -> Array<Signal<V>>,
    annihilatorsList : ArrayList<Annihilator<V, G>>,
    identitiesList : ArrayList<Identifier<V, G>>
) : Unit
     where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    // Only gates with multiple inputs can have annihilator and identity rules
    let arity = gate.GetArity()
    if(arity >= 2) {
        // Check each of the input ports in turn
        for(i in 0..gate.GetInputPorts().size){
            let port = gate.GetInputPort(i)
            // Check every possible input on this wire
            let possibleInputsOnThisWire =
                latticeStructure.EnumerateSignals(port.GetWidth())
            for(fixedInput in possibleInputsOnThisWire) {
                // Check every possible input on the other wires
                let possibleInputsOnAllWires =
                    latticeStructure.EnumerateInputs(
                        gate.GetInputPorts(),
                        fixed: HashMap([(i, HashSet([fixedInput]))])
                    )
                /**
                 * Given an array of inputs and outputs, check to see if
                 * the elements that are not element i in the inputs are
                 * also the corresponding outputs.
                 *
                 * @param inputs
                 * @param outputs
                 * @return Whether this is an identification
                 */
                func CheckIfIdentifier(
                    input : Array<Signal<V>>, output : Array<Signal<V>>
                ) {
                    foldi_left(
                        { acc, j, cur =>
                            let correspondingInput =
                                if(j < i) {
                                    input[j]
                                } else {
                                    input[j + 1]
                                }
                                acc && correspondingInput == cur
                        },
                        true,
                        output
                    )
                }
                // We will fold over all the possible inputs so we need to grab
                // the first one to use as the initial value
                let firstInput = possibleInputsOnAllWires[0]
                let firstOutput = gateInterpretation(firstInput)
                // For annihilators we just take the first output as the
                // candidate annihiliation value
                let candidateAnnihiliationResult = firstOutput
                // For identifiers we need to check if this first output is
                // an identification
                let currentIsIdentifier =
                    CheckIfIdentifier(firstInput, firstOutput)
                let (isAnnihilator, isIdentifier) = fold_left(
                    { acc, currentInput =>
                        let (oldIsAnnihilator, oldIsIdentifier) = acc
                        let currentOutput = gateInterpretation(currentInput)
                        // Check if the result matches the
                        // annihilation candidate
                        let newIsAnnihilator =
                            oldIsAnnihilator &&
                            currentOutput == candidateAnnihiliationResult
                        // Check if this is also an identification
                        let newIsIdentifier =
                            oldIsIdentifier &&
                                CheckIfIdentifier(currentInput, currentOutput)
                        (newIsAnnihilator, newIsIdentifier)
                    }, (true, true),
                    possibleInputsOnAllWires,
                    start: 1
                )
                // Add annihilators and identifications to the appropriate lists
                if(isAnnihilator) {
                    annihilatorsList.append(
                        Annihilator(
                            gate, fixedInput, i,
                            candidateAnnihiliationResult
                        )
                    )
                }
                if(isIdentifier) {
                    identitiesList.append(Identifier(gate, fixedInput, i))
                }
            }
        }
    }
}
public struct Blackbox<V, G>
    <: Hashable & Equatable<Blackbox<V, G>> & HasName & Specifiable
{
    static var nextBlackBoxId = 0
    let id : Int64
    Blackbox(
        let name : String,
        let inputs : Array<Port>,
        let outputs : Array<Port>
    ){
        this.id = nextBlackBoxId
        nextBlackBoxId++
    }
    public func hashCode() : Int64 {
        this.id
    }
    public func GetName() : String {
        this.name
    }
    public func GetInputPorts() : Array<Port> {
        this.inputs
    }
    public func GetOutputPorts() : Array<Port> {
        this.outputs
    }
    public operator func ==(rhs : Blackbox<V, G>) : Bool {
        this.name == rhs.GetName() &&
            this.inputs == rhs.GetInputPorts() &&
            this.outputs == rhs.GetOutputPorts()
    }
    public operator func !=(rhs : Blackbox<V, G>) : Bool {
        !(this == rhs)
    }
}
/**
 * A signature defines the value and gate components that can be used in a
 * circuit.
 */
public class Signature<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let uniqueId : Int64 = GetNextId()
    public let annihilators : Array<Annihilator<V, G>>
    public let identities : Array<Identifier<V, G>>
    let blackboxes : HashSet<Blackbox<V, G>> = HashSet<Blackbox<V, G>>()
    public Signature(
        let name : String,
        let latticeStructure: FiniteLattice<V>,
        let usedGates : HashSet<G>,
        let gateInterpretation: (G) -> ((Array<Signal<V>>) -> Array<Signal<V>>)
    ) {
        let annihilatorsList = ArrayList<Annihilator<V, G>>()
        let identitiesList = ArrayList<Identifier<V, G>>()
        // Verify that the specified gates and their interpretation
        // is a valid monotone gate, and then get their annihilators and
        // identifiers if they are
        for(g in usedGates) {
            AssertTableMonotone(
                this.latticeStructure, g.GetInputPorts(), gateInterpretation(g)
            )
            GetAnnihilatorAndIdentifierRules(
                g, latticeStructure, gateInterpretation(g),
                annihilatorsList, identitiesList
            )
        }
        this.annihilators = annihilatorsList.toArray()
        this.identities = identitiesList.toArray()
    }
    public func GetId() : Int64 {
        this.uniqueId
    }
    /**
     * @param gate
     * @return The interpretation of gate in this signature
     */
    public func GetGate(gate : G) : ((Array<Signal<V>>) -> Array<Signal<V>>) {
        this.gateInterpretation(gate)
    }
    /**
     * Get the join in the lattice of two elements
     *
     * @param lhs
     * @param rhs
     * @return The join of lhs and rhs
     */
    public func Join(lhs: V, rhs: V): V {
        this.latticeStructure.Join(lhs, rhs)
    }
    /**
     * Get the (pointwise) join in the lattice on powers (arrays) of elements
     *
     * @param lhs the first array
     * @param rhs the second array
     * @return The pointwise join of lhs and rhs
     */
    public func Join(lhs: Array<V>, rhs: Array<V>): Array<V> {
        this.latticeStructure.Join(lhs, rhs)
    }
    /**
     * Get the (pointwise) join in the lattice on powers (arrays) of elements
     *
     * @param lhs the first array
     * @param rhs the second array
     * @return The pointwise join of lhs and rhs
     */
    public func Join(lhs: Signal<V>, rhs: Signal<V>): Signal<V> {
        Signal(this.Join(lhs.GetValues(), rhs.GetValues()))
    }
    /**
     * Check whether an element in the lattice is less than another
     *
     * @param lhs
     * @param rhs
     * @return lhs <= rhs
     */
    public func LTE(lhs: V, rhs: V): Bool {
        this.latticeStructure.LTE(lhs, rhs)
    }
    /**
     * Check whether a power (array) of elements in the lattice is less than
     * another
     *
     * @param lhs
     * @param rhs
     * @return lhs <= rhs
     */
    public func LTE(v: Array<V>, u: Array<V>): Bool {
        this.latticeStructure.LTE(v, u)
    }
    public func GetBottom() : V {
        this.latticeStructure.bot
    }
    /**
     * Enumerate all the signals of a given width.
     *
     * @param width
     * @return An array of signals of given width
     */
    public func EnumerateSignals(width : Int64) : Array<Signal<V>> {
        this.latticeStructure.EnumerateSignals(width)
    }
    /**
     * Enumerate all the inputs that could be applied to a given array of ports.
     * Optionally some ports can be restricted to a given array of signals.
     *
     * @param width
     * @param fixed A hash map of input indices to the signal it is fixed at
     * @return An array of signals of given width
     */
    public func EnumerateInputs(
        ports : Array<Port>,
        fixed!: HashMap<Int64, HashSet<Signal<V>>> = HashMap()
    ) : Array<Array<Signal<V>>> {
        this.latticeStructure.EnumerateInputs(ports, fixed: fixed)
    }
    /**
     * @param i
     * @return Get the longest chain in the lattice for powers of length i
     */
    public func GetLongestChain(i : Int64) : Int64 {
        this.latticeStructure.GetLongestChain(i)
    }
    public func GetAnnihilators() : Array<Annihilator<V, G>> {
        this.annihilators
    }
    public func GetIdentities() : Array<Identifier<V, G>> {
        this.identities
    }
    /**
     * Add a blackbox to this signature.
     *
     * @param name
     * @param inputs
     * @param outputs
     */
    public func AddBlackbox(
        name : String, inputs : Array<Port>, outputs : Array<Port>
    ) : Blackbox<V, G> {
        let bb = Blackbox<V, G>(name, inputs, outputs)
        if(this.blackboxes.contains(bb)) {
            bb
        } else {
            this.blackboxes.put(bb)
            bb
        }
    }
}
extend Signature<V, G> <: HasName {
    public func GetName() : String {
        this.name
    }
}
extend Signature<V, G> <: ToString {
    public func toString() : String {
        this.GetName()
    }
}
