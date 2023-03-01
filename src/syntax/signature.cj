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
