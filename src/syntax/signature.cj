/**
 * syntax/signature.cj
 *
 * Definition of signatures, containing components in a circuit
 */
package syntax

from std import collection.HashSet, collection.HashMap

public interface ValueSymbol <: Hashable & HasName & ToString {}

public interface PrimitiveSymbol<V>
    <: Specifiable<V> & HasName & ToString & Hashable
    where V <: ValueSymbol & Equatable<V> & LessOrEqual<V> {
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
        V <: ValueSymbol & Equatable<V> & LessOrEqual<V>
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
        V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
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
        V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
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
public class Signature<V, G> <: HasName & ToString
    where
        V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    public let specificationImplementation :
        HashMap<Specification<V>, ((Array<Array<V>>) -> Array<V>)>
            = HashMap<Specification<V>, ((Array<Array<V>>) -> Array<V>)>()
    public Signature(
        let name : String,
        let latticeStructure: FiniteLattice<V>,
        let usedGates : HashSet<G>,
        let gateInterpretation: (G) -> ((Array<Array<V>>) -> Array<Array<V>>),
        let toDec: (Array<V>, Bool) -> Option<Int64>
    ) {
        for(g in usedGates) {
            CheckTableMonotone(
                this.latticeStructure, g.GetInputPorts(), gateInterpretation(g)
            )
            let combinations = GetAnnihilationAndIdentityRules(g)
        }
    }
    func GetAnnihilationAndIdentityRules(gate : G) {
        let arity = gate.GetArity()
        if(arity >= 2) {
            let function = this.gateInterpretation(gate)
            // List of annihilators: each element is a tuple
            // (annihilator, port number, result of annihilation)
            let annihilators = ArrayList<Annihilator<V, G>>()
            let identities = ArrayList<Identity<V, G>>()
            for(i in 0..gate.GetInputPorts().size){
                let port = gate.GetInputPort(i)
                let possibleInputsOnThisWire =
                    this.latticeStructure.EnumeratePowers(port.GetWidth())
                for(fixedInput in possibleInputsOnThisWire) {
                    let possibleInputsOnAllWires =
                        this.latticeStructure.EnumerateInputs(
                            gate.GetInputPorts(),
                            fixed: HashMap([(i, fixedInput)])
                        )
                    let firstInput = possibleInputsOnAllWires[0]
                    let firstOutput = function(firstInput)
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
                            let currentOutput = function(currentInput)
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
                        annihilators.append(
                            Annihilator(
                                gate, fixedInput, i,
                                candidateAnnihiliationResult
                            )
                        )
                    }
                    if(isIdentity) {
                        identities.append(Identity(gate, fixedInput, i))
                    }
                }
            }
        }
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
    public func GetName() : String {
        this.name
    }
    public func toString() : String {
        this.GetName()
    }
}
