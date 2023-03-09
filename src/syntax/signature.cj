/**
 * syntax/signature.cj
 *
 * Definition of signatures, containing components in a circuit
 */
package syntax

from std import collection.HashSet, collection.HashMap

public interface ValueSymbol<V> <: Hashable & HasName & ToString {
    // HACK: ideally we want to have this returning an element
    // of the type the interface is being implemented on, but I don't
    // know whether this is possible
    static func GetDisconnected() : V
}

public interface PrimitiveSymbol<V>
    <: Specifiable<V> & HasName & ToString & Hashable
    where V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V> {
    func GetEnhancedName(n: Int64, w: Int64): String
}
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
func CheckTableMonotone<V>(
    lattice : FiniteLattice<V>,
    ports : Array<Port>,
    table : (Array<Array<V>>) -> (Array<Array<V>>)
) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>
{
    let inputs = lattice.EnumerateInputs(ports)
    for(input1 in inputs) {
        for(input2 in inputs) {
            if (lattice.LTE(input1, input2)) {
                let result1 = table(input1)
                let result2 = table(input2)
                if(!lattice.LTE(result1, result2)){
                    throw NonMonotoneFunctionException<V>(
                        input1, input2, table
                    )
                }
            }
        }
    }
}
public struct Annihilator<V, G> <: ToString
     where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    public Annihilator(
        public let gate : G,
        public let input : Array<V>,
        public let index : Int64,
        public let output : Array<Array<V>>
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
        for(i in this.index+1..afterEndIndex){
            string = "${string} -, "
        }
        "${string}-) = ${this.output}"
    }
}
public struct Identity<V, G> <: ToString
     where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    public Identity(
        public let gate : G,
        public let input : Array<V>,
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
            afterIndexString = "${afterIndexString}x${gate.GetCoarity() - afterEndIndex}"
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
func GetAnnihilationAndIdentityRules<V, G>(
    gate : G,
    latticeStructure : FiniteLattice<V>,
    gateInterpretation : (Array<Array<V>>) -> Array<Array<V>>,
    annihilatorsList : ArrayList<Annihilator<V, G>>,
    identitiesList : ArrayList<Identity<V, G>>
) : Unit
     where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    // Only gates with multiple inputs can have annihilator and identity rules
    let arity = gate.GetArity()
    if(arity >= 2) {
        for(i in 0..gate.GetInputPorts().size){
            let port = gate.GetInputPort(i)
            let possibleInputsOnThisWire =
                latticeStructure.EnumeratePowers(port.GetWidth())
            for(fixedInput in possibleInputsOnThisWire) {
                let possibleInputsOnAllWires =
                    latticeStructure.EnumerateInputs(
                        gate.GetInputPorts(),
                        fixed: HashMap([(i, fixedInput)])
                    )
                let firstInput = possibleInputsOnAllWires[0]
                let firstOutput = gateInterpretation(firstInput)
                let candidateAnnihiliationResult = firstOutput
                func CheckIfIdentity(
                    input : Array<Array<V>>, output : Array<Array<V>>
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
                let currentIsIdentity = CheckIfIdentity(firstInput, firstOutput)
                let (isAnnihilator, isIdentity) = fold_left(
                    { acc, currentInput =>
                        let (oldIsAnnihilator, oldIsIdentity) = acc
                        let currentOutput = gateInterpretation(currentInput)
                        let newIsAnnihilator =
                            oldIsAnnihilator &&
                            currentOutput == candidateAnnihiliationResult
                        let newIsIdentity =
                            oldIsIdentity &&
                                CheckIfIdentity(currentInput, currentOutput)
                        (newIsAnnihilator, newIsIdentity)
                    }, (true, true),
                    possibleInputsOnAllWires,
                    start: 1
                )
                if(isAnnihilator) {
                    annihilatorsList.append(
                        Annihilator(
                            gate, fixedInput, i,
                            candidateAnnihiliationResult
                        )
                    )
                }
                if(isIdentity) {
                    identitiesList.append(Identity(gate, fixedInput, i))
                }
            }
        }
    }
}
public class Signature<V, G> <: HasName & ToString & Equatable<Signature<V, G>>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let uniqueId : Int64 = GetNextId()
    public let annihilators : Array<Annihilator<V, G>>
    public let identities : Array<Identity<V, G>>
    public Signature(
        let name : String,
        let latticeStructure: FiniteLattice<V>,
        let usedGates : HashSet<G>,
        let gateInterpretation: (G) -> ((Array<Array<V>>) -> Array<Array<V>>),
        let toDec: (Array<V>, Bool) -> Option<Int64>
    ) {
        let annihilatorsList = ArrayList<Annihilator<V, G>>()
        let identitiesList= ArrayList<Identity<V, G>>()
        for(g in usedGates) {
            CheckTableMonotone(
                this.latticeStructure, g.GetInputPorts(), gateInterpretation(g)
            )
            GetAnnihilationAndIdentityRules(
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
    public operator func ==(rhs : Signature<V, G>) {
        this.GetId() == rhs.GetId()
    }
    public operator func !=(rhs : Signature<V, G>) {
        !(this == rhs)
    }
    public func GetGate(gate : G) : ((Array<Array<V>>) -> Array<Array<V>>) {
        this.gateInterpretation(gate)
    }
    public func GetLattice() : FiniteLattice<V> {
        this.latticeStructure
    }
    public func Join(v: V, u: V): V {
        this.latticeStructure.Join(v, u)
    }
    public func Join(v: Array<V>, u: Array<V>): Array<V> {
        this.latticeStructure.Join(v, u)
    }
    public func GetJoin(i : Int64) : (Array<V>, Array<V>) -> Array<V> {
        { lhs : Array<V>, rhs : Array<V> => this.latticeStructure.Join(lhs, rhs) }
    }
    public func LTE(v: V, u: V): Bool {
        this.latticeStructure.LTE(v, u)
    }
    public func LTE(v: Array<V>, u: Array<V>): Bool {
        this.latticeStructure.LTE(v, u)
    }
    public func GetBottom() : V {
        this.latticeStructure.bot
    }
    public func GetLongestChain(i : Int64) : Int64 {
        this.latticeStructure.GetLongestChain(i)
    }
    public func GetUsedGates() : HashSet<G> {
        this.usedGates
    }
    public func GetAnnihilators() : Array<Annihilator<V, G>> {
        this.annihilators
    }
    public func GetIdentities() : Array<Identity<V, G>> {
        this.identities
    }
    public func GetName() : String {
        this.name
    }
    public func toString() : String {
        this.GetName()
    }
}
