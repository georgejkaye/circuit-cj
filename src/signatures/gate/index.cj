/**
 * signature/gate/signature.cj
 *
 * The 'belnap signature' for gate level circuits
 *
 * @author George Kaye
 * @since 0.3
 */
package signatures.gate
from std import math.{floor, log, ceil, abs, log2}
from std import collection.HashSet
import utils.{
    AssertStrictlyPositive, AssertPowerOf, AssertNonNegative,
    AssertGreaterThanOrEqualTo, concat, pow
}
import syntax.*
import graphs.{Hypergraph, InterfacedHypergraph}
import components.*
import components.constructions.*
/**
 * package type aliases
 */
public type BelnapWire = Wire<GateLevelValue, GateLevelPrimitive>
public type BelnapInterfaceWire =
    InterfaceWire<GateLevelValue, GateLevelPrimitive>
public type BelnapCircuit = Hypergraph<GateLevelValue, GateLevelPrimitive>
public type BelnapInterfacedCircuit =
    InterfacedHypergraph<GateLevelValue, GateLevelPrimitive>
/**
 * Signature for Belnap circuits
 */
public let belnapSignature = Signature<GateLevelValue, GateLevelPrimitive>(
    "Belnap",
    gateLevelLatticeStructure,
    HashSet([BUF, NOT, AND, OR, NAND, NOR, XOR, XNOR]),
    gateLevelInterpretation
)