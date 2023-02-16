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
    where V <: ValueSymbol & Equatable<V> {
    func GetEnhancedName(n: Int64, w: Int64): String
}

public class Signature<V, G> <: HasName & ToString
    where V <: ValueSymbol & Equatable<V> & LessOrEqual<V>, G <: PrimitiveSymbol<V> & Equatable<G>
{
    public let specificationImplementation : HashMap<Specification<V>, ((Array<Array<V>>) -> Array<V>)>
        = HashMap<Specification<V>, ((Array<Array<V>>) -> Array<V>)>()
    public Signature(
        public let name : String,
        public let latticeStructure: FiniteLattice<V>,
        public let gateInterpretation: (G) -> ((Array<Array<V>>) -> Array<V>),
        public let toDec: (Array<V>, Bool) -> Option<Int64>
    ) {}
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
