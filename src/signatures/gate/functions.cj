package signatures.gate

import syntax.*
import utils.*

from std import math.abs

/**
 * Unary gates
 */

public func BufGate(
    a : BelnapWire
) : BelnapWire {
    belnapSignature.UseUnaryGate(BUF, a)
}
public func NotGate(
    a : BelnapWire
) : BelnapWire {
    belnapSignature.UseUnaryGate(NOT, a)
}

/**
 * Binary gates
 */

public func AndGate(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    belnapSignature.UseBinaryGate(AND, a, b)
}
public func OrGate(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    belnapSignature.UseBinaryGate(OR, a, b)
}
public func NandGate(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    belnapSignature.UseBinaryGate(NAND, a, b)
}
public func NorGate(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    belnapSignature.UseBinaryGate(NOR, a, b)
}
public func XorGate(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    belnapSignature.UseBinaryGate(XOR, a, b)
}
public func XnorGate(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    belnapSignature.UseBinaryGate(XNOR, a, b)
}


/**
 * Perform an unsigned extension on a wire, i.e. add a false as its msb
 * @param w The input wire
 * @return The wire with an extra bit
 */
public func UnsignedExtend(
    w : BelnapWire
) : BelnapWire {
    let waveform = belnapSignature.ConstantZero()
    Combine([waveform, w])
}