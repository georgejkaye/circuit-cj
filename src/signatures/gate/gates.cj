/**
 * signatures/gate/gates
 *
 * Primitives and composites for the belnap signature
 *
 * @author George Kaye
 * @since 0.3
 */
package signatures.gate
/**
 * Bitwise buf
 *
 * @param a
 * @param delay
 * @return Output of bitwise buf
 */
public func UseBuf(
    a : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseMapPrimitive(BUF, [a], delay: [delay])[0]
}
/**
 * Bitwise not
 *
 * @param a
 * @param delay
 * @return Output of bitwise not
 */
public func UseNot(
    a : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseMapPrimitive(NOT, [a], delay: [delay])[0]
}
/**
 * Bitwise and
 *
 * @param a
 * @param b
 * @param delay
 * @return Output of bitwise and
 */
public func UseAnd(
    a : BelnapWire, b : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseMapPrimitive(AND, [a, b], delay: [delay])[0]
}
/**
 * Bitwise or
 *
 * @param a
 * @param b
 * @param delay
 * @return Output of bitwise or
 */
public func UseOr(
    a : BelnapWire, b : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseMapPrimitive(OR, [a, b], delay: [delay])[0]
}
/**
 * Bitwise nand
 *
 * @param a
 * @param b
 * @param delay
 * @return Output of bitwise nand
 */
public func UseNand(
    a : BelnapWire, b : BelnapWire, delay!: Int64
) : BelnapWire {
    UseBitwiseMapPrimitive(NAND, [a, b], delay: [delay])[0]
}
/**
 * Bitwise nor
 *
 * @param a
 * @param b
 * @param delay
 * @return Output of bitwise nor
 */
public func UseNor(
    a : BelnapWire, b : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseMapPrimitive(NOR, [a, b], delay: [delay])[0]
}
/**
 * Bitwise xor
 *
 * @param a
 * @param b
 * @param delay
 * @return Output of bitwise xor
 */
public func UseXor(
    a : BelnapWire, b : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseMapPrimitive(XOR, [a, b], delay: [delay])[0]
}
/**
 * Bitwise xnor
 *
 * @param a
 * @param b
 * @param delay
 * @return Output of bitwise xnor
 */
public func UseXnor(
    a : BelnapWire, b : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseMapPrimitive(XNOR, [a, b], delay: [delay])[0]
}
/**
 * Ripple and
 *
 * @param ws
 * @param delay
 * @return Output of bitwise and
 */
public func UseAnd(
    ws : Array<BelnapWire>, delay!: Int64 = 0
) : BelnapWire {
    UseRippleBinaryPrimitive(AND, ws, delay: [delay])[0]
}
/**
 * Ripple or
 *
 * @param ws
 * @param delay
 * @return Output of bitwise or
 */
public func UseOr(
    ws : Array<BelnapWire>, delay!: Int64 = 0
) : BelnapWire {
    UseRippleBinaryPrimitive(OR, ws, delay: [delay])[0]
}
/**
 * Ripple nand
 *
 * @param ws
 * @param delay
 * @return Output of bitwise nand
 */
public func UseNand(
    ws : Array<BelnapWire>, delay!: Int64 = 0
) : BelnapWire {
    UseRippleBinaryPrimitive(NAND, ws, delay: [delay])[0]
}
/**
 * Ripple nor
 *
 * @param ws
 * @param delay
 * @return Output of bitwise and
 */
public func UseNor(
    ws : Array<BelnapWire>, delay!: Int64 = 0
) : BelnapWire {
    UseRippleBinaryPrimitive(NOR, ws, delay: [delay])[0]
}
/**
 * Ripple xor
 *
 * @param ws
 * @param delay
 * @return Output of bitwise xor
 */
public func UseXor(
    ws : Array<BelnapWire>, delay!: Int64 = 0
) : BelnapWire {
    UseRippleBinaryPrimitive(XOR, ws, delay: [delay])[0]
}
/**
 * Ripple xnor
 *
 * @param ws
 * @param delay
 * @return Output of bitwise xnor
 */
public func UseXnor(
    ws : Array<BelnapWire>, delay!: Int64 = 0
) : BelnapWire {
    UseRippleBinaryPrimitive(XNOR, ws, delay: [delay])[0]
}
/**
 * Bitwise ripple and
 *
 * @param w
 * @param delay
 * @return Output of bitwise ripple and
 */
public func UseAnd(
    w : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseRippleBinaryPrimitive(AND, [w], delay: [delay])
}
/**
 * Bitwise ripple or
 *
 * @param w
 * @param delay
 * @return Output of bitwise ripple or
 */
public func UseOr(
    w : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseRippleBinaryPrimitive(OR, [w], delay: [delay])
}
/**
 * Bitwise ripple nand
 *
 * @param w
 * @param delay
 * @return Output of bitwise ripple nand
 */
public func UseNand(
    w : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseRippleBinaryPrimitive(NAND, [w], delay: [delay])
}
/**
 * Bitwise ripple nor
 *
 * @param w
 * @param delay
 * @return Output of bitwise ripple nor
 */
public func UseNor(
    w : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseRippleBinaryPrimitive(NOR, [w], delay: [delay])
}
/**
 * Bitwise ripple xor
 *
 * @param w
 * @param delay
 * @return Output of bitwise ripple xor
 */
public func UseXor(
    w : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseRippleBinaryPrimitive(XOR, [w], delay: [delay])
}
/**
 * Bitwise ripple xnor
 *
 * @param w
 * @param delay
 * @return Output of bitwise ripple xnor
 */
public func UseXnor(
    w : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseRippleBinaryPrimitive(XNOR, [w], delay: [delay])
}