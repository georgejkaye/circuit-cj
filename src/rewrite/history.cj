/**
 * rewrite/history.cj
 *
 * Structs for dealing with input-output history when rewriting
 *
 * @author George Kaye
 * @since 0.3
 */
package rewrite
/**
 * Given an array of signals, get a string representing them as arguments to a
 * circuit, i.e. a string of the form (s1, s2, s3, ...)
 *
 * @param vs The array
 * @return The signa
 */
public func GetArgumentString<V>(
    vs : Array<CycleInput<V>>,
    printFn!: (CycleInput<V>) -> String = { ci => ci.GetName() }
) : String
    where V <: ValueSymbol<V>
{
    arrayToString(
        vs, { s, _ => printFn(s) }, openingBracket: "(", closingBracket: ")",
        delimiter: ", "
    )
}
public func GetOutputString<V>(
    vs : Array<Option<CycleInput<V>>>,
    printFn!: (CycleInput<V>) -> String = { ci => ci.GetName() }
) : String
    where V <: ValueSymbol<V>
{
    arrayToString(
        vs, { opt, _ =>
            match(opt){
                case None => "?"
                case Some(s) => printFn(s)
            }
        }, openingBracket: "(", closingBracket: ")", delimiter: ","
    )
}
/**
 * Get a comma separated string of arguments represented in decimal
 *
 * @param args
 * @param signed
 * @return The argument string in decimal
 */
public func GetArgumentString<V>(
    args : Array<CycleInput<V>>, signed!: Bool
) : String
    where V <: ValueSymbol<V> & Decimal<V>
{
    GetArgumentString(
        args, printFn: {
            ci : CycleInput<V> => GetDecimalNameFromCycleInput(ci, signed)
        }
    )
}
public func GetOutputString<V>(
    vs : Array<Option<CycleInput<V>>>, signed!: Bool
) : String
    where V <: ValueSymbol<V> & Decimal<V>
{
    GetOutputString<V>(
        vs, printFn: {
            ci : CycleInput<V> => GetDecimalNameFromCycleInput(ci, signed)
        }
    )
}
/**
 * Enum of function-like things that can be in the output after partial
 * evaluation
 */
public enum Function<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    | PRIMITIVE(G)
    | ENHANCED_PRIMITIVE(EnhancedPrimitive<V, G>)
    | BLACKBOX(Blackbox<V, G>)
    | COMPOSITE(Specification)
}
extend Function<V, G> <: ToString {
    public func toString() : String {
        match(this) {
            case PRIMITIVE(g) => g.GetName()
            case ENHANCED_PRIMITIVE(ep) => ep.GetName()
            case BLACKBOX(bb) => bb.GetName()
            case COMPOSITE(spec) => spec.GetName()
        }
    }
}
extend Function<V, G> <: Specifiable {
    public func GetInputPorts() : Array<Port> {
        match(this) {
            case PRIMITIVE(g) => g.GetInputPorts()
            case ENHANCED_PRIMITIVE(ep) => ep.GetInputPorts()
            case BLACKBOX(bb) => bb.GetInputPorts()
            case COMPOSITE(spec) => spec.GetInputPorts()
        }
    }
    public func GetOutputPorts() : Array<Port> {
        match(this) {
            case PRIMITIVE(g) => g.GetOutputPorts()
            case ENHANCED_PRIMITIVE(ep) => ep.GetOutputPorts()
            case BLACKBOX(bb) => bb.GetOutputPorts()
            case COMPOSITE(spec) => spec.GetOutputPorts()
        }
    }
}
/**
 * Enum of things that can be in the output after partial evaluation.
 */
public enum OutputTerm<V, G> where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    | BASE(CycleInput<V>)
    | JOIN(OutputTerm<V, G>, OutputTerm<V, G>)
    | FUNCTION(Function<V, G>, Array<OutputTerm<V, G>>, Int64)
    | BUNDLE(Array<OutputTerm<V, G>>, Array<Int64>, Int64)
}
extend OutputTerm<V, G> <: ToString {
    func GetString(signalFn : (CycleInput<V>) -> String) : String {
        func GetMultiInputString(
            op : String, inputs : Array<OutputTerm<V, G>>,
            coarity : Int64, i : Int64
        ) : String {
            let inputStrings = map({ op : OutputTerm<V, G> => "${op}" }, inputs)
            let indexScript = if(coarity > 1) {
                "[${i}]"
            } else {
                ""
            }
            let inputString = concatStrings(inputStrings, delimiter: ", ")
            "${op}(${inputString})${indexScript}"
        }
        match(this) {
            case BASE(s) => signalFn(s)
            case JOIN(left, right) => "\u{2294}(${left}, ${right})"
            case FUNCTION(fn, inputs, i) =>
                GetMultiInputString("${fn}", inputs, fn.GetCoarity(), i)
            case BUNDLE(inputs, bundle, i) =>
                GetMultiInputString(
                    "\u{25C7}{${bundle}}", inputs, bundle.size, i
                )
        }
    }
    public func GetString() : String {
        GetString({ s => s.GetName() })
    }
    public func toString() : String {
        GetString()
    }
}
func GetDecimalNameFromCycleInput<V>(
    ci : CycleInput<V>, signed : Bool
) : String where V <: ValueSymbol<V> & Decimal<V> {
    match(ci){
        case DEFINITE(s) => s.GetDecimalName(signed: signed)
        case PARTIAL(p) => p.GetDecimalName(signed: signed)
    }
}
func GetDecimalNameFromSignal<V>(
    s : Signal<V>, signed : Bool
) : String where V <: ValueSymbol<V> & Decimal<V> {
    let num = V.SignalToDec(s, signed: signed)
    match(num) {
        case None => s.GetName()
        case Some(n) => "${n}"
    }
}
extend OutputTerm<V, G> where V <: Decimal<V> {
    public func GetString(signed!: Bool) : String {
        let fn = { ci : CycleInput<V> =>
            GetDecimalNameFromCycleInput(ci, signed)
        }
        GetString(fn)
    }
}
/**
 * Get the output term for a join edge
 *
 * @param ec
 * @param computed The map of previously computed vertices and their terms
 * @return The output from the join
 */
func MakeJoinOutput<V, G>(
    ec : EdgeConnection<V, G>, computed : HashMap<Vertex<V, G>, OutputTerm<V, G>>
) : OutputTerm<V, G> where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    let leftOutput = GetOutputTerm(ec.GetEdge().GetSource(0), computed)
    let rightOutput = GetOutputTerm(ec.GetEdge().GetSource(1), computed)
    JOIN(leftOutput, rightOutput)
}
/**
 * Get the output term for a function edge
 *
 * @param ec
 * @param computed The map of previously computed vertices and their terms
 * @return The output from the function
 */
func MakeFunctionOutput<V, G>(
    ec : EdgeConnection<V, G>, function : Function<V, G>,
    computed : HashMap<Vertex<V, G>, OutputTerm<V, G>>
) : OutputTerm<V, G> where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    let sources = ec.GetEdge().GetSources()
    let outputs = map(
        { v : Vertex<V, G> => GetOutputTerm(v, computed) }, sources
    )
    FUNCTION(function, outputs, ec.GetIndex())
}
/**
 * Get the output term for a bundler edge
 *
 * @param ec
 * @param computed The map of previously computed vertices and their terms
 * @return The output from the bundler
 */
func MakeBundlerOutput<V, G>(
    ec : EdgeConnection<V, G>, ns: Array<Int64>,
    computed : HashMap<Vertex<V, G>, OutputTerm<V, G>>
) : OutputTerm<V, G> where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    let sources = ec.GetEdge().GetSources()
    let outputs = map(
        { v : Vertex<V, G> => GetOutputTerm(v, computed) }, sources
    )
    BUNDLE(outputs, ns, ec.GetIndex())
}
/**
 * Given a root vertex, compute the output term that leads to it.
 *
 * @param rootVertex
 * @param computed The map of previously computed vertices and their terms
 * @return The output from the vertex
 */
func GetOutputTerm<V, G>(
    rootVertex : Vertex<V, G>, computed : HashMap<Vertex<V, G>, OutputTerm<V, G>>
) : OutputTerm<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    match(computed.get(rootVertex)) {
        case Some(output) => output
        case None =>
            let ec = rootVertex.GetInEdge().getOrThrow()
            let edge = ec.GetEdge()
            let output = match(edge.GetLabel()) {
                case VALUE(v) =>
                    BASE<V, G>(DEFINITE(Signal([v])))
                case SIGNAL(s) =>
                    BASE<V, G>(DEFINITE(s))
                case PARTIAL(pi) =>
                    BASE<V, G>(PARTIAL(pi))
                case BUNDLER(ms, ns) =>
                    MakeBundlerOutput(ec, ns, computed)
                case JOIN(w) =>
                    MakeJoinOutput(ec, computed)
                case PRIMITIVE(p) =>
                    MakeFunctionOutput(ec, PRIMITIVE(p), computed,)
                case ENHANCED_PRIMITIVE(ep) =>
                    MakeFunctionOutput(ec, ENHANCED_PRIMITIVE(ep), computed)
                case COMPOSITE(spec) =>
                    MakeFunctionOutput(ec, COMPOSITE(spec), computed)
                case BLACKBOX(bb) =>
                    MakeFunctionOutput(ec, BLACKBOX(bb), computed)
                case _ =>
                    throw IncompatibleVariantException(
                        edge.GetLabel(), "Combinational"
                    )
            }
            computed.put(rootVertex, output)
            output
    }
}
/**
 * Given a root vertex, compute the output term that leads to it.
 *
 * @param rootVertex
 * @return The output from the vertex
 */
func GetOutputTerm<V, G>(
    rootVertex : Vertex<V, G>
) : OutputTerm<V, G> where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    GetOutputTerm(rootVertex, HashMap<Vertex<V, G>, OutputTerm<V, G>>())
}
/**
 * Given an array of output terms, print their string as a comma-separated tuple
 *
 * @param outputs
 * @return The output string
 */
func GetOutputTermString<V, G>(
    outputs : Array<OutputData<V, G>>
) : String where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    collectionToString(
        outputs, { op : OutputData<V, G>, _ => op.term.GetString() },
        openingBracket: "(", closingBracket: ")", delimiter: ", "
    )
}
/**
 * Given an array of output terms, print their string as a comma-separated tuple
 * interpreting signals as decimal where appropriate
 *
 * @param outputs
 * @param signed
 * @return The output string
 */
func GetOutputTermString<V, G>(
    outputs : Array<OutputData<V, G>>, signed!: Bool
) : String where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G> {
    collectionToString(
        outputs,
        { op : OutputData<V, G>, _ => op.term.GetString(signed: signed) },
        openingBracket: "(", closingBracket: ")", delimiter: ", "
    )
}
public struct OutputData<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    public OutputData(
        public let term : OutputTerm<V, G>,
        public let graph : InterfacedHypergraph<V, G>
    ){}
}
/**
 * Struct for relating inputs and outputs in an evaluator.
 */
public struct InputOutput<V, G> <: ToString
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    public InputOutput(
        public let input : Array<CycleInput<V>>,
        public let output : Array<OutputData<V, G>>
    ){}
    public func toString() : String {
        "${GetArgumentString(this.input)} -> " +
            "${GetOutputTermString<V, G>(this.output)}"
    }
    public func GetInput() : Array<CycleInput<V>> {
        this.input
    }
    public func GetOutput() : Array<OutputData<V, G>> {
        this.output
    }
}
extend InputOutput<V, G> where V <: Decimal<V> {
    public func GetDecimalString(signed : Bool) : String {
        let outputString = collectionToString(
            this.output,
            { op : OutputData<V, G>, _ => op.term.GetString(signed: signed) },
            openingBracket: "(", closingBracket: ")", delimiter: ", "
        )
        "${GetArgumentString(this.input, signed: signed)}" +
        " -> ${GetOutputTermString(this.output, signed: signed)}"
    }
}
/**
 * Struct containing data structures for tracking the input output history of an
 * evaluator.
 */
public struct InputOutputHistory<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    public let inputHistoryPerTick : ArrayList<Array<CycleInput<V>>>
    public let outputHistoryPerTick : ArrayList<Array<OutputData<V, G>>>
    public let inputOutputHistoryPerTick : ArrayList<InputOutput<V, G>>
    public let inputHistoryPerPort : Array<ArrayList<CycleInput<V>>>
    public let outputHistoryPerPort : Array<ArrayList<OutputData<V, G>>>
    public init(inputs : Int64, outputs : Int64) {
        this.inputHistoryPerTick = ArrayList()
        this.outputHistoryPerTick = ArrayList()
        this.inputOutputHistoryPerTick = ArrayList()
        this.inputHistoryPerPort =
            Array(inputs){ i => ArrayList<CycleInput<V>>() }
        this.outputHistoryPerPort =
            Array(outputs){ i => ArrayList<OutputData<V, G>>() }
    }
    public func GetCurrentTick() : Int64 {
        return inputOutputHistoryPerTick.size
    }
}
/**
 * Get a string for a table displaying inputs and outputs over time
 *
 * @param ios The inputoutputs
 * @param inputFn function for displaying the input
 * @param outputFn function for displaying the output
 * @return String for an input output table
 */
func GetInputOutputString<V, G> (
    ios : Collection<InputOutput<V, G>>,
    inputFn : (Array<CycleInput<V>>) -> String,
    outputFn : (Array<OutputData<V, G>>) -> String
) : String  where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    let lines = ArrayList<String>()
    // Compute column widths
    let (longestInput, longestOutput) = fold_left(
        { acc, cur =>
            let inputLength = inputFn(cur.GetInput()).size
            let outputLength = outputFn(cur.GetOutput()).size
            let (input, output) = acc
            (max(inputLength, input), max(outputLength, output))
        },
        (0, 0),
        ios
    )
    let tickColumnWidth = max("${ios.size}".size, 4) + 2
    let inputColumnWidth = longestInput + 4
    let outputColumnWidth = longestOutput + 4
    let totalLength = tickColumnWidth + inputColumnWidth + outputColumnWidth
    // Write the header line
    let tickHeader = "Tick".padRight(tickColumnWidth)
    let inputHeader = "Input".padRight(inputColumnWidth)
    let outputHeader = "Output".padRight(outputColumnWidth)
    let headerLine = "${tickHeader} ${inputHeader} ${outputHeader}"
    lines.append(headerLine)
    // Write a dividing line between header and content
    let underlineLength = max(headerLine.size, totalLength)
    let headerUnderline = "".padRight(underlineLength, paddingChar: '=')
    lines.append(headerUnderline)
    // Write the input output for each element in the collection
    let iter = ios.iterator()
    for(i in 0..ios.size) {
        let io = iter.next().getOrThrow()
        let tickField = "${i}".padRight(tickColumnWidth)
        let inputField =
            "${inputFn(io.GetInput())}".padRight(inputColumnWidth)
        let outputField =
            "${outputFn(io.GetOutput())}".padRight(outputColumnWidth)
        let row = "${tickField} ${inputField} ${outputField}"
        lines.append(row)
    }
    // Put all the lines together
    concatStrings(lines, delimiter: "\n")
}
/**
 * Allow evaluator to expose its history and get the pretty string
 */
extend Evaluator<V, G> {
    public func GetInputHistoryPerPort() : Array<ArrayList<CycleInput<V>>> {
        this.history.inputHistoryPerPort
    }
    public func GetOutputHistoryPerPort() : Array<ArrayList<OutputData<V, G>>> {
        this.history.outputHistoryPerPort
    }
    public func GetInputOutputHistoryPerTick() : ArrayList<InputOutput<V, G>> {
        this.history.inputOutputHistoryPerTick
    }
    public func GetInputOutputHistoryString() : String {
        GetInputOutputString(
            this.history.inputOutputHistoryPerTick,
            { inputs => GetArgumentString(inputs) },
            { outputs => GetOutputTermString(outputs) }
        )
    }
}
/**
 * Allow evaluation using decimal values
 */
extend Evaluator<V, G> where V <: Decimal<V> {
    public func GetInputOutputHistoryString(signed!: Bool) : String {
        GetInputOutputString(
            this.history.inputOutputHistoryPerTick,
            { inputs => GetArgumentString(inputs, signed: signed) },
            { outputs => GetOutputTermString(outputs, signed: signed) }
        )
    }
}