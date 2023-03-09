package signatures.gate

import syntax.*
import utils.*

from std import math.abs

public func BufGate(
    a : BelnapWire
) : BelnapWire {
    UseUnaryGate(BUF, a)[0]
}
public func NotGate(
    a : BelnapWire
) : BelnapWire {
    UseUnaryGate(NOT, a)[0]
}
public func AndGate(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    UseBinaryGate(AND, a, b)[0]
}
public func OrGate(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    UseBinaryGate(OR, a, b)[0]
}
public func NandGate(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    UseBinaryGate(NAND, a, b)[0]
}
public func NorGate(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    UseBinaryGate(NOR, a, b)[0]
}
public func XorGate(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    UseBinaryGate(XOR, a, b)[0]
}
public func XnorGate(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    UseBinaryGate(XNOR, a, b)[0]
}
/**
* Perform an unsigned extension on a wire, i.e. add a false as its msb
* @param w The input wire
* @return The wire with an extra bit
*/
public func UnsignedExtend(
    w : BelnapWire
) : BelnapWire {
    let waveform = belnapSignature.UseConstantZero(width: 1)
    Combine([waveform, w])
}