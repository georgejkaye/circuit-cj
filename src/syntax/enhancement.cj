/**
 * syntax/enhancement.cj
 *
 * Definition of enhancements for primitives
 *
 */

package syntax

public enum Enhancement {
    | BITWISE_MAP(Int64)                    // Apply a gate to each bit of multiple wires independently
    | RIPPLE(Int64)                         // Apply a gate to each input in turn
    | BITWISE_RIPPLE(Int64)                 // Apply a gate to each bit of an input wire in turn
    | RIPPLE_BITWISE_MAP(Int64, Int64)      // Ripple a bitwise map gate over an arbitrary number of wires
    | BITWISE_MAP_RIPPLE(Int64, Int64)      // Apply a ripple gate to each bit of a wire independently
}
extend Enhancement <: Equatable<Enhancement> {
    public operator func ==(rhs : Enhancement) {
        match(this) {
            case BITWISE_MAP(w1) => match(rhs) {
                case BITWISE_MAP(w2) => w1 == w2
                case _ => false
            }
            case RIPPLE(m1) => match(rhs) {
                case RIPPLE(m2) => m1 == m2
                case _ => false
            }
            case BITWISE_RIPPLE(w1) => match(rhs) {
                case BITWISE_RIPPLE(w2) => w1 == w2
                case _ => false
            }
            case RIPPLE_BITWISE_MAP(m1, w1) => match(rhs) {
                case RIPPLE_BITWISE_MAP(m2, w2) => m1 == m2 && w1 == w2
                case _ => false
            }
            case BITWISE_MAP_RIPPLE(w1, m1) => match(rhs) {
                case BITWISE_MAP_RIPPLE(w2, m2) => w1 == w2 && m1 == m2
                case _ => false
            }
        }
    }
    public operator func !=(rhs : Enhancement) {
        !(this == rhs)
    }
}

public struct EnhancedPrimitive<V, G> <: HasName & Specifiable<V> & Equatable<EnhancedPrimitive<V, G>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    public EnhancedPrimitive(
        public let primitive : G,
        public let enhancement : Enhancement
    ){}
    public func GetInputWiresAndWidth() : (Int64, Int64) {
        match(this.enhancement) {
            case BITWISE_MAP(w)           => (this.primitive.GetArity(), w)
            case RIPPLE(n)                => (n, this.primitive.GetInputPorts()[0].GetWidth())
            case BITWISE_RIPPLE(w)        => (1, w)
            case RIPPLE_BITWISE_MAP(m, w) => (m, w)
            case BITWISE_MAP_RIPPLE(w, m) => (m, w)
        }
    }
    public func GetName() : String {
        let primitiveName = this.primitive.GetName()
        let (wires, width) = this.GetInputWiresAndWidth()
        "${primitiveName}_${wires}_${width}"
    }
    public func GetInputPorts() : Array<Port<V>> {
        let (wires, width) = GetInputWiresAndWidth()
        Array<Port<V>>(wires, {
            i : Int64 => Port(width, "${primitive.GetInputPorts()[0].name}i")
        })
    }
    public func GetOutputPorts() : Array<Port<V>> {
        let (wires, width) =
            match(this.enhancement) {
                case BITWISE_MAP(w)           => (this.primitive.GetCoarity(), w)
                case RIPPLE(n)                => (n, this.primitive.GetOutputPorts()[0].GetWidth())
                case BITWISE_RIPPLE(w)        => (1, this.primitive.GetOutputPorts()[0].GetWidth())
                case RIPPLE_BITWISE_MAP(m, w) => (1, w)
                case BITWISE_MAP_RIPPLE(w, m) => (1, w)
            }
        Array<Port<V>>(wires){
            i : Int64 => Port(width, "${primitive.GetInputPorts()[0].name}i")
        }
    }
    public operator func ==(rhs : EnhancedPrimitive<V, G>) : Bool {
        this.primitive == rhs.primitive && this.enhancement == rhs.enhancement
    }
    public operator func !=(rhs : EnhancedPrimitive<V, G>) : Bool {
        !(this == rhs)
    }
}