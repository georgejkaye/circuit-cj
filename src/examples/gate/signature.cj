/**
 * examples/gate/signature
 *
 * Contains type aliases for the gate signature/
 *
 * @author George Kaye
 * @since 0.3
 */
package examples.gate
import components.*
import signatures.gate.*
import utils.*
import syntax.*
import graphs.*
// Signature elements
public type Value = GateLevelValue
public type Gate = GateLevelPrimitive
// Circuit construction objects
public type Wire_ = Wire<Value, Gate>
public type Circuit_ = InterfacedHypergraph<Value, Gate>
public type InterfaceWire_ = InterfaceWire<Value, Gate>
// Signature
let sig = belnapSignature