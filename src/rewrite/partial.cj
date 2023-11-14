/**
 * rewrite/partial.cj
 *
 * Partially evaluate circuits
 *
 * @author George Kaye
 * @since 0.3
 */
package rewrite
import graphs.InterfacedHypergraph

public func GetFixed<V>(signal : Signal<V>) : CycleInput<V>
    where V <: ValueSymbol<V>
{
    DEFINITE(signal)
}
public func GetVariable<V>(signals : HashSet<Signal<V>>) : CycleInput<V>
    where V <: ValueSymbol<V>
{
    if(signals.size == 0) {
        let signal = signals.iterator().next().getOrThrow()
        GetFixed(signal)
    } else {
        let width = AssertAllHaveSameWidth(signals)
        let pvv = Variable(signals)
        let values = Array<VariableValue<V>>(width){ i : Int64 =>
            VariableValue(pvv, i)
        }
        PARTIAL(VariableSignal(values))
    }
}

func ConvertPotentialSignalsToCycleInput<V>(
    signals : HashSet<Signal<V>>
) : CycleInput<V> where V <: ValueSymbol<V> {
    GetVariable(signals)
}

public func GetPotentialOutputs<V, G>(
    signature : Signature<V, G>,
    partialInputs : Array<CycleInput<V>>,
    primitive : G
) : Array<HashSet<Signal<V>>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertHasLength<CycleInput<V>>(partialInputs, primitive.GetArity())
    // Establish the ranges of the inputs
    let restrictedInputs = HashMap<Int64, HashSet<Signal<V>>>()
    forEach<CycleInput<V>>({
        ci : CycleInput<V>, i : Int64 =>
            let restrictedAtThisIndex = HashSet<Signal<V>>()
            match(ci) {
                case DEFINITE(s) =>
                    restrictedAtThisIndex.put(s)
                case PARTIAL(p) =>
                    restrictedAtThisIndex.putAll(p.GetPotentialSignals())
            }
            restrictedInputs.put(i, restrictedAtThisIndex)
    }, partialInputs)
    // Get all the arrays of inputs
    let potentialInputs =
        signature.EnumerateInputs(
            primitive.GetInputPorts(), fixed: restrictedInputs
        )
    // Initialise the array of outputs: the ith element of this array is the
    // hash set of outputs that may arise on the ith output wire.
    let outputsPerPort = Array<HashSet<Signal<V>>>(primitive.GetCoarity(), {
        i : Int64 => HashSet<Signal<V>>(potentialInputs.size)
    })
    // For each input, compute the outputs and put the result of each port
    // onto the appropriate hash set
    forEach({
        inputs : Array<Signal<V>>, _ : Int64 =>
            let outputs = signature.GetGate(primitive)(inputs)
            forEach<Signal<V>>({
                output : Signal<V>, i : Int64 =>
                    outputsPerPort[i].put(output)
            }, outputs)
    }, potentialInputs)
    outputsPerPort
}
func GetPartialApplyRule<V, G>(
    signature : Signature<V, G>
) : RewriteRule<V, G> where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    RewriteRule<V, G>(
        "papply",
        PRIMITIVE,
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                let primitive = e.GetLabel().GetPrimitive()
                let (argumentEdges, argumentSignals) = GetArgs(e)
                try {
                    let inputEdges = Array<Option<Edge<V, G>>>(
                        e.GetArity(), { i => None<Edge<V, G>>}
                    )
                    let partialInputs = map(
                        { oe : Option<Edge<V, G>> =>
                            let e = oe.getOrThrow()
                            match(e.GetLabel()) {
                                case VALUE(v) =>
                                    DEFINITE(Signal([v]))
                                case SIGNAL(s) =>
                                    DEFINITE(s)
                                case PARTIAL(pi) =>
                                    PARTIAL(pi)
                                // This shouldn't happen
                                case _ => throw Exception()
                            }
                        }, argumentEdges
                    )
                    let potentialOutputs = GetPotentialOutputs(
                        signature, partialInputs, primitive
                    )
                    let cycleInputs = map(
                        ConvertPotentialSignalsToCycleInput<V>, potentialOutputs
                    )
                    let nextEdges = ReplaceGateWithOutputs(
                        signature, f, e, argumentEdges, cycleInputs
                    )
                    None<HashSet<TraversalElement<V, G>>>
                } catch (e : NoneValueException) {
                    None
                }
        }
    )
}
// /**
//  * Partially evaluate a circuit. Clones the circuit so the original is not
//  * affected
//  *
//  * @param f
//  * @param partialInputs
//  */
// public func PartialEvaluate<V, G>(
//     sig : Signature<V, G>, f: InterfacedHypergraph<V, G>,
//     cycleInputs : Array<Option<CycleInput<V>>>
// ) : Unit where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
//     AssertHasLength(cycleInputs, f.GetArity())
//     let completeCycleInputs = map2({
//         pit : CycleInputM<V, iv : InterfaceVertex<V, G> =>
//             let actualInputType = match(oci) {
//                 case Some(ci) => ci
//                 case None =>
//                     let signals = EnumerateSignals()
//             }
//             PartialInput(actualInputType, iv.GetWidth())
//     }, cycleInputs, f.GetInputs())
//     let newGraph = Apply(f, cycleInputs)
//     newGraph.WriteDotToFile("dot/partial", depth: 1)
// }