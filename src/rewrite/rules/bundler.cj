/**
 * rewrite/rules/bundler.cj
 *
 * Functions for using the bundler rule.
 *
 * @author George Kaye
 * @since 0.3
 */
package rewrite.rules
enum SingleBit<V> where V <: ValueSymbol<V> {
    | VALUE(V)
    | PARTIAL(VariableValue<V>)
}
/**
 * Given an edge with signals or values attached to its sources, get the
 * single bits that make up these arguments and put them in a list.
 *
 * @param list
 * @param e
 * @param f
 */
func GetSingleBits<V, G>(
    list : ArrayList<SingleBit<V>>,
    e : Edge<V, G>,
    f : InterfacedHypergraph<V, G>
) : Unit where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    forEach({ v : Vertex<V, G>, i : Int64 =>
        // Precondition enforces there must be an in edge
        let valueEdge = v.GetInEdge().getOrThrow().GetEdge()
        match(valueEdge.GetLabel()) {
            case VALUE(v) =>
                list.append(VALUE(v))
            case SIGNAL(signal) =>
                forEach(
                    { v : V , _ =>
                        list.append(VALUE(v))
                    }, signal.GetValues()
                )
            case PARTIAL(pi) =>
                forEach(
                    { pv : VariableValue<V>, _ =>
                        list.append(PARTIAL(pv))
                    }, pi.GetValues()
                )
            case _ => ()
        }
        // Remove the old value edges and their vertices
        RemoveEdge(valueEdge, f)
        RemoveVertex(v, f)
    }, e.GetSources())
}
/**
 * Given an array of bits where each bit is fixed, make the label and subgraph
 * for the bundled edge.
 *
 * @param bits
 * @return The label and subgraph
 */
func MakeDefiniteLabelAndSubgraph<V, G>(
    values : Array<SingleBit<V>>
) : (Label<V, G>, Option<InterfacedHypergraph<V, G>>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    if(values.size == 1) {
        let value = values[0]
        match(value){
            case VALUE(v) => (
                Label<V,G>.VALUE(v), None<InterfacedHypergraph<V, G>>
            )
            case _ => throw Exception()
        }
    } else {
        let signalValues = map(
            { bit : SingleBit<V> => match(bit) {
                case VALUE(v) => v
                case _ => throw Exception()
            }}, values
        )
        let signal = Signal(signalValues)
        (Label<V, G>.SIGNAL(signal), Some(MakeSignal<V, G>(signal)))
    }
}
/**
 * Given an array of bits where at least one of them is variable, make the label
 * and subgraph for the bundled edge.
 *
 * @param bits
 * @return The label and subgraph
 */
func MakeVariableLabelAndSubgraph<V, G>(
    bits : Array<SingleBit<V>>
) : (Label<V, G>, Option<InterfacedHypergraph<V, G>>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    let partialValues = map(
        { bit : SingleBit<V> => match(bit) {
            case PARTIAL(p) => p
            case VALUE(v) =>
                let newVariable = Variable<V>(HashSet([Signal([v])]))
                VariableValue<V>(
                    HashSet([newVariable]), { ss => ss[0].GetBit(0) }
                )
        }}, bits
    )
    let partialSignal = VariableSignal(partialValues)
    (Label<V,G>.PARTIAL(partialSignal), None<InterfacedHypergraph<V, G>>)
}
/**
 * Given a bundler spec and an array of single bits, create the edges for the
 * bits combined appropriately into (variable) signals.
 *
 * @param bundlerOutputs
 * @param valuesArray
 * @param newElements
 * @param e
 * @param f
 */
func CreateNewBundles<V, G>(
    bundlerOutputs : Array<Int64>,
    valuesArray : Array<SingleBit<V>>,
    newElements : HashSet<TraversalElement<V, G>>,
    e : Edge<V, G>, f : InterfacedHypergraph<V, G>
) : Unit where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    forEach<Vertex<V, G>>({ v : Vertex<V, G>, i : Int64 =>
        let start = Sum(bundlerOutputs, end: i)
        let values = valuesArray.sliceArray(
            start: start, end: start + v.GetWidth()
        )
        let isAllDefinite = fold_left(
            { acc, cur => acc && match(cur) {
                case VALUE(_) => true
                case PARTIAL(_) => false
            }}, true, values
        )
        let (label, subgraph) = if(isAllDefinite) {
            MakeDefiniteLabelAndSubgraph<V, G>(values)
        } else {
            MakeVariableLabelAndSubgraph<V, G>(values)
        }
        let newEdge = Edge(
            label, Array<Vertex<V, G>>(),
            [v], subgraph, f.GetGraph()
        )
        newElements.put(EDGE(newEdge))
    }, e.GetTargets())
}
/**
 * Get a value bundle rule, where the values applied to a bundle are transformed
 * into appropriate width signals.
 *
 * @param signature
 * @return The value bundle rule
 */
public func GetValueBundleRule<V, G>(signature : Signature<V, G>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    RewriteRule<V, G>(
        "bundle",
        BUNDLE,
        { e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
            if(!ApplyPreconditions(e)){
                None
            } else {
                let (bundlerInputs, bundlerOutputs) =
                    e.GetLabel().GetBundlerSpec()
                let totalValues = Sum(bundlerInputs)
                let values = ArrayList<SingleBit<V>>(totalValues)
                // Remove the bundle edge
                RemoveEdge(e, f)
                // Get all the individual values in an array
                GetSingleBits<V, G>(values, e, f)
                let valuesArray = values.toArray()
                // Create a new signal edge for each output of the bundle
                let newElements = HashSet<TraversalElement<V, G>>()
                // Create the new bundled wires
                CreateNewBundles(bundlerOutputs, valuesArray, newElements, e, f)
                Some(newElements)
            }
        }
    )
}