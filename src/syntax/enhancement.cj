/**
 * syntax/enhancement.cj
 *
 * Definition of enhancements for primitives
 *
 */

package syntax

public enum Enhancement {
    | RIPPLE(Int64)         // RIPPLE(k) applies a gate m * m -> m to (k+1) wires of width m
    | BITWISE_MAP(Int64)    // BITWISE_MAP(w) applies a gate m -> n to m wires of width w
    | BITWISE_RIPPLE(Int64) // BITWISE_RIPPLE(k) applies a gate m * m -> m to m wires of width k+1
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
        }
    }
    public operator func !=(rhs : Enhancement) {
        !(this == rhs)
    }
}

public func CheckRippleSuitability<V, G>(primitive : G) : Unit
    where V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>, G <: PrimitiveSymbol<V> & Equatable<G>
{
    let inputs = primitive.GetInputPorts()
    let outputs = primitive.GetOutputPorts()
    if(
        inputs.size != 2 ||
        outputs.size != 1 ||
        inputs[0].GetWidth() != inputs[1].GetWidth() ||
        outputs[0].GetWidth() != inputs[0].GetWidth()
    ){
        throw CannotRipplePrimitiveException(primitive)
    }
}

public func CheckBitwiseMapSuitability<V, G>(primitive : G) : Unit
    where V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>, G <: PrimitiveSymbol<V> & Equatable<G>
{
    AssertPortsSameWidth(primitive.GetInputPorts())
    AssertPortsSameWidth(primitive.GetOutputPorts())
}

public struct EnhancedPrimitive<V, G> <: HasName & Specifiable<V> & Equatable<EnhancedPrimitive<V, G>>
    where V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>, G <: PrimitiveSymbol<V> & Equatable<G>
{
    public EnhancedPrimitive(
        public let primitive : G,
        public let enhancement : Enhancement
    ){
        // Validate the enhancement
        match(this.enhancement) {
            case BITWISE_MAP(w) => CheckBitwiseMapSuitability(this.primitive)
            case RIPPLE(k) => CheckRippleSuitability(this.primitive)
            case BITWISE_RIPPLE(k) => CheckRippleSuitability(this.primitive)
        }
    }
    public func GetArity() : Int64 {
        match(this.enhancement) {
            case BITWISE_MAP(w)    => this.primitive.GetArity()
            case RIPPLE(k)         => k+1
            case BITWISE_RIPPLE(k) => this.primitive.GetInputPort(0).GetWidth()
        }
    }
    public func GetCoarity() : Int64 {
        match(this.enhancement) {
            case BITWISE_MAP(w)    => this.primitive.GetCoarity()
            case RIPPLE(k)         => 1
            case BITWISE_RIPPLE(k) => 1
        }
    }
    public func GetName() : String {
        let primitiveString = this.primitive.GetName()
        let enhancementString = match(this.enhancement) {
            case BITWISE_MAP(w)    => "${primitive.GetArity()}_${w}"
            case RIPPLE(k)         => "${k+1}_${primitive.GetInputPort(0).GetWidth()}"
            case BITWISE_RIPPLE(k) => "${1}_${k+1}"
        }
        "${primitiveString}${enhancementString}"
    }
    public func GetInputPorts() : Array<Port> {
        let arity = this.GetArity()
        Array<Port>(arity, {
            i : Int64 =>
                let portWidth = match(this.enhancement) {
                    case BITWISE_MAP(w)    => w
                    case RIPPLE(k)         => this.primitive.GetInputPort(0).GetWidth()
                    case BITWISE_RIPPLE(k) => k+1
                }
                Port(portWidth, "")
        })
    }
    public func GetOutputPorts() : Array<Port> {
        let coarity = this.GetCoarity()
        Array<Port>(coarity, {
            i : Int64 =>
                let portWidth = match(this.enhancement) {
                    case BITWISE_MAP(w)    => w
                    case RIPPLE(k)         => this.primitive.GetInputPort(0).GetWidth()
                    case BITWISE_RIPPLE(k) => this.primitive.GetInputPort(0).GetWidth()
                }
                Port(portWidth, "")
        })
    }
    public operator func ==(rhs : EnhancedPrimitive<V, G>) : Bool {
        this.primitive == rhs.primitive && this.enhancement == rhs.enhancement
    }
    public operator func !=(rhs : EnhancedPrimitive<V, G>) : Bool {
        !(this == rhs)
    }
}