// /**
//  * components/construction.cj
//  *
//  * Functions for constructing composite circuits that apply
//  * smaller functions to multiple bits of wires in a variety of ways.
//  *
//  * @author George Kaye
//  * @since 0.2
//  */

package components

// from std import collection.ArrayList

// import debug.*

// // public enum Direction {
// //     | TOP_TO_BOTTOM
// //     | BOTTOM_TO_TOP
// // }


// /**
//  * Exception for users to throw if something is not implemented
//  */
// public class NotImplemented <: Exception {
//     public init(msg : String) {
//         ErrorMsg("Not implemented: ${msg}")
//     }
// }
// public func Bitwise<V, G>(
//     f : (Array<Wire<V, G>>) -> Array<Wire<V, G>>,
//     ws : Array<Wire<V, G>>
// ) : Array<Wire<V, G>>
//     where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
// {
//     let width = AssertWiresSameWidth(ws)
//     let splitWires = map({ w : Wire<V, G> => Split(w) }, ws)
//     println("The split wires are ${splitWires}")
//     let orderedWires = Array<Array<Wire<V, G>>>(width){ i : Int64 =>
//         Array<Wire<V, G>>(splitWires.size){ j : Int64 => splitWires[j][i] }
//     }
//     println("The ordered wires are ${orderedWires}")
//     let outputWires = map({ ws : Array<Wire<V, G>> => f(ws) }, orderedWires)
//     println("The output wires are ${outputWires}")
//     let joinedWires = Array<Wire<V, G>>(outputWires[0].size){ i : Int64 =>
//         let indexWires = Array<Wire<V, G>>(outputWires.size){ j : Int64 => outputWires[j][i] }
//         println("Index wires are ${indexWires}")
//         Combine(indexWires)
//     }
//     joinedWires
// }
// public func Bitwise<V, G>(
//     f : InterfacedHypergraph<V, G>,
//     ws : Array<Wire<V, G>>
// ) : Array<Wire<V, G>>
//     where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
// {
//     Bitwise({ ws : Array<Wire<V, G>> => UseSubcircuit(f, ws) }, ws)
// }
// public func Bitwise<V, G>(
//     f : (Array<Wire<V, G>>) -> Wire<V, G>,
//     ws : Array<Wire<V, G>>
// ) : Wire<V, G>
//     where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
// {
//     Bitwise({ ws : Array<Wire<V, G>> => [f(ws)] }, ws)[0]
// }
// public func GeneralRipple<V, G>(
//     f : (Array<Wire<V, G>>, Array<Wire<V,G>>) -> (Array<Wire<V, G>>, Array<Wire<V, G>>),
//     initial : Array<Wire<V, G>>,
//     wss : Array<Array<Wire<V, G>>>,
//     direction!: Direction = TOP_TO_BOTTOM
// ) : (Array<Array<Wire<V, G>>>, Array<Wire<V, G>>)
//     where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
// {
//     println("${wss}")
//     let width = AssertWireArrayArraysCompatible(wss)
//     var acc = initial
//     let outputs = ArrayList<Array<Wire<V, G>>>()
//     for(i in 0..wss.size) {
//         println("Rippling ${i}")
//         let j = match(direction) {
//             case TOP_TO_BOTTOM => i
//             case BOTTOM_TO_TOP => wss.size - 1 - i
//         }
//         let cur = wss[j]
//         let (curRes, curAcc) = f(acc, cur)
//         match(direction){
//             case TOP_TO_BOTTOM => outputs.append(curRes)
//             case BOTTOM_TO_TOP => outputs.prepend(curRes)
//         }
//         acc = curAcc
//     }
//     println("the outputs are ${outputs}")
//     (outputs.toArray(), acc)
// }
// // public func Ripple<V, G>(
// //     f : (Array<Wire<V, G>>, Array<Wire<V,G>>) -> Array<Wire<V, G>>,
// //     initial : Array<Wire<V, G>>,
// //     wss : Array<Array<Wire<V, G>>>,
// //     direction!: Direction = TOP_TO_BOTTOM
// // ) : Array<Wire<V, G>>
// //     where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
// // {
// //     let (outputs, acc) = GeneralRipple(
// //         { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> => (Array<Wire<V, G>>(), f(acc, cur)) },
// //         initial,
// //         wss,
// //         direction: direction
// //     )
// //     acc
// // }
// // public func Ripple<V, G>(
// //     f : InterfacedHypergraph<V, G>,
// //     initial : Array<Wire<V, G>>,
// //     wss : Array<Array<Wire<V, G>>>,
// //     direction!: Direction = TOP_TO_BOTTOM
// // ) : Array<Wire<V, G>>
// //     where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
// // {
// //     Ripple({ acc : Array<Wire<V, G>>, cur : Array<Wire<V,G>> => UseSubcircuit(f, concat(acc, cur)) }, initial, wss, direction: direction)
// // }
// // public func Ripple<V, G>(
// //     f : (Array<Wire<V, G>>, Array<Wire<V,G>>) -> Array<Wire<V, G>>,
// //     wss : Array<Array<Wire<V, G>>>,
// //     direction!: Direction = TOP_TO_BOTTOM
// // ) : Array<Wire<V, G>>
// //     where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
// // {
// //     AssertArrayHasMinimumLength(wss, 1)
// //     let initial = wss[0]
// //     println("${initial}")
// //     let rest = Array<Array<Wire<V, G>>>(wss.size - 1){ i : Int64 => wss[i+1]}
// //     println("${rest}")
// //     println("The rest is ${rest.size}")
// //     Ripple(f, initial, rest, direction: direction)
// // }
// // public func Ripple<V, G>(
// //     f : InterfacedHypergraph<V, G>,
// //     wss : Array<Array<Wire<V, G>>>,
// //     direction!: Direction = TOP_TO_BOTTOM
// // ) : Array<Wire<V, G>>
// //     where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
// // {
// //     Ripple({ acc : Array<Wire<V, G>>, cur : Array<Wire<V,G>> => UseSubcircuit(f, concat(acc, cur)) }, wss, direction: direction)
// // }
// // public func RippleMap<V, G>(
// //     f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> (Array<Wire<V, G>>, Array<Wire<V, G>>),
// //     initial : Array<Wire<V, G>>,
// //     ws : Array<Array<Wire<V, G>>>,
// //     direction!: Direction = TOP_TO_BOTTOM
// // ) : (Array<Array<Wire<V, G>>>, Array<Wire<V, G>>)
// //     where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
// // {
// //     GeneralRipple<V, G>(f, initial, ws, direction: direction)
// // }
// // public func RippleMap_1<V, G>(
// //     f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> (Array<Wire<V, G>>, Array<Wire<V, G>>),
// //     initial : Array<Wire<V, G>>,
// //     ws : Array<Wire<V, G>>,
// //     direction!: Direction = TOP_TO_BOTTOM
// // ) : (Array<Array<Wire<V, G>>>, Array<Wire<V, G>>)
// //     where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
// // {
// //     RippleMap<V, G>(f, initial, map({w : Wire<V, G> => [w]}, ws), direction: direction)
// // }
// // public func RippleMap_1<V, G>(
// //     f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> (Wire<V, G>, Wire<V, G>),
// //     initial : Array<Wire<V, G>>,
// //     ws : Array<Wire<V, G>>,
// //     direction!: Direction = TOP_TO_BOTTOM
// // ) : (Array<Wire<V, G>>, Array<Wire<V, G>>)
// //     where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
// // {
// //     let fprime = { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
// //         let (newOutput, newAcc) = f(acc, cur)
// //         ([newOutput], [newAcc])
// //     }
// //     let (finalOutput, finalAcc) = RippleMap<V, G>(fprime, initial, map({w : Wire<V, G> => [w]}, ws), direction: direction)
// //     let actualOutputs = map({ ws : Array<Wire<V, G>> => ws[0] }, finalOutput)
// //     (actualOutputs, finalAcc)
// // }
// public func BitwiseRippleMap<V, G>(
//     f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> (Array<Wire<V, G>>, Array<Wire<V, G>>),
//     initial : Array<Wire<V, G>>,
//     ws : Array<Wire<V, G>>,
//     direction!: Direction = TOP_TO_BOTTOM
// ) : (Array<Wire<V, G>>, Array<Wire<V, G>>)
//     where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
// {
//     let width = AssertWiresSameWidth(ws)
//     let splitInputs = map({ w : Wire<V, G> => Split(w) }, ws)
//     let orderedInputs = Array<Array<Wire<V, G>>>(width){ i : Int64 =>
//         Array<Wire<V, G>>(ws.size){ j : Int64 => splitInputs[j][i] }
//     }
//     println("There are ${splitInputs.size} wires")
//     let (outputs, acc) = RippleMap(f, initial, orderedInputs, direction: direction)
//     let size = outputs[0].size
//     let joinedOutputs = Array<Wire<V, G>>(size){
//         i : Int64 => Combine(Array<Wire<V, G>>(outputs.size){
//             j : Int64 => outputs[j][i]
//         })
//     }
//     (joinedOutputs, acc)
// }
// public func BitwiseRippleMap<V, G>(
//     f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> (Wire<V, G>, Wire<V, G>),
//     initial : Array<Wire<V, G>>,
//     ws : Array<Wire<V, G>>,
//     direction!: Direction = TOP_TO_BOTTOM
// ) : (Wire<V, G>, Wire<V, G>)
//     where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
// {
//     let fprime = { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
//         let (newOutput, newAcc) = f(acc, cur)
//         ([newOutput], [newAcc])
//     }
//     let (finalOutput, finalAcc) = BitwiseRippleMap(fprime, initial, ws, direction: direction)
//     (finalOutput[0], finalAcc[0])
// }
// public func InternalRipple<V, G>(
//     f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> Array<Wire<V, G>>,
//     initial : Array<Wire<V, G>>,
//     ws : Array<Wire<V, G>>,
//     direction!: Direction = TOP_TO_BOTTOM
// ) : Array<Wire<V, G>>
//     where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
// {
//     let splitWires = map({ w : Wire<V, G> => Split(w) }, ws)
//     let size = AssertWireArrayArraysCompatible(splitWires)
//     let orderedWires = Array<Array<Wire<V, G>>>(size){ i : Int64 =>
//         Array<Wire<V, G>>(ws.size){ j : Int64 => splitWires[j][i] }
//     }
//     println("${initial}")
//     println("${orderedWires}")
//     Ripple(f, initial, orderedWires, direction: direction)
// }
// public func InternalRipple<V, G>(
//     f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> Array<Wire<V, G>>,
//     ws : Array<Wire<V, G>>,
//     direction!: Direction = TOP_TO_BOTTOM
// ) : Array<Wire<V, G>>
//     where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
// {
//     let splitWires = map({ w : Wire<V, G> => Split(w) }, ws)
//     let size = AssertWireArrayArraysCompatible(splitWires)
//     let orderedWires = Array<Array<Wire<V, G>>>(size){ i : Int64 =>
//         Array<Wire<V, G>>(ws.size){ j : Int64 => splitWires[j][i] }
//     }
//     let first = orderedWires[0]
//     let rest = Array<Array<Wire<V, G>>>(orderedWires.size - 1){
//         i : Int64 => orderedWires[i+1]
//     }
//     Ripple(f, first, rest, direction: direction)
// }

