/**
 * syntax/enhancement.cj
 *
 * Definition of enhancements for primitives
 *
 * @author George Kaye
 * @since 0.3
 */
package syntax
/**
 * An enhancement is a primitive adapted for higher width wires or more inputs
 */
public enum Enhancement {
    // RIPPLE(k) applies a gate m * m -> m to (k+1) wires of width m
    | RIPPLE(Int64)
    // BITWISE_MAP(w) applies a gate m -> n to m wires of width w
    | BITWISE_MAP(Int64)
    // BITWISE_RIPPLE(k) applies a gate m * m -> m to m wires of width k+1
    | BITWISE_RIPPLE(Int64)
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
/**
 * Assert that a primitive can be rippled, i.e. it has two inputs, one output,
 * and these ports are all the same width. Throws exception if can't ripple.
 *
 * @param primitive
 */
public func AssertSuitableToRipple<V, G>(primitive : G) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
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
/**
 * Exception for when AssertSuitableToRipple fails
 */
class CannotRipplePrimitiveException<V, G> <: Exception
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    public init(primitive : G) {
        ErrorMsg(
            "Cannot ripple over primitive ${primitive} as its type is" +
            "${primitive.GetInputPorts()} -> ${primitive.GetOutputPorts()}" +
            "wheras rippling requires type [m, m] -> [m]"
        )
    }
}
/**
 * Assert that a primitive can be bitwise mapped, i.e. all of its inputs are the
 * same width and all of its outputs are the same width. Throws exception if
 * can't bitwise map.
 *
 * @param primitive
 */
public func AssertSuitableToBitwiseMap<V, G>(primitive : G) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertAllHaveSameWidth(primitive.GetInputPorts())
    AssertAllHaveSameWidth(primitive.GetOutputPorts())
}
/**
 * Exception for when AssertSuitableToBitwiseMap fails
 */
class CannotBitwiseMapPrimitiveException<V, G> <: Exception
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    public init(primitive : G) {
        ErrorMsg(
            "Cannot bitwise map over primitive ${primitive} as its type is" +
            "${primitive.GetInputPorts()} -> ${primitive.GetOutputPorts()}" +
            "wheras rippling requires type [m, ..., m] -> [n, ..., n]"
        )
    }
}
/**
 * Struct for a primitive and an enhancement
 */
public struct EnhancedPrimitive<V, G>
    <: HasName & Specifiable & Equatable<EnhancedPrimitive<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    public EnhancedPrimitive(
        public let primitive : G,
        public let enhancement : Enhancement
    ){
        // Validate the enhancement
        match(this.enhancement) {
            case BITWISE_MAP(w) => AssertSuitableToBitwiseMap(this.primitive)
            case RIPPLE(k) => AssertSuitableToRipple(this.primitive)
            case BITWISE_RIPPLE(k) => AssertSuitableToRipple(this.primitive)
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
            case BITWISE_MAP(w)    =>
                "${primitive.GetArity()}_${w}"
            case RIPPLE(k)         =>
                "${k+1}_${primitive.GetInputPort(0).GetWidth()}"
            case BITWISE_RIPPLE(k) =>
                "${1}_${k+1}"
        }
        "${primitiveString}${enhancementString}"
    }
    public func GetInputPorts() : Array<Port> {
        let arity = this.GetArity()
        Array<Port>(arity, {
            i : Int64 =>
                let portWidth = match(this.enhancement) {
                    case BITWISE_MAP(w)    => w
                    case RIPPLE(k)         =>
                        this.primitive.GetInputPort(0).GetWidth()
                    case BITWISE_RIPPLE(k) => k+1
                }
                Port(portWidth)
        })
    }
    public func GetOutputPorts() : Array<Port> {
        let coarity = this.GetCoarity()
        Array<Port>(coarity, {
            i : Int64 =>
                let portWidth = match(this.enhancement) {
                    case BITWISE_MAP(w)    => w
                    case RIPPLE(k)         =>
                        this.primitive.GetInputPort(0).GetWidth()
                    case BITWISE_RIPPLE(k) =>
                        this.primitive.GetInputPort(0).GetWidth()
                }
                Port(portWidth)
        })
    }
    public operator func ==(rhs : EnhancedPrimitive<V, G>) : Bool {
        this.primitive == rhs.primitive && this.enhancement == rhs.enhancement
    }
    public operator func !=(rhs : EnhancedPrimitive<V, G>) : Bool {
        !(this == rhs)
    }
}