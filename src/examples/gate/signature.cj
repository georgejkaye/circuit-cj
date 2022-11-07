package examples.gate

public type Value = GateLevelValue
public type Gate = GateLevelPrimitive

public type Wire_ = Wire<Value, Gate>
public type Circuit_ = InterfacedHypergraph<Value, Gate>
public type Port_ = Port<Value>
public type InterfaceWire_ = InterfaceWire<Value, Gate>

let sig = belnapSignature