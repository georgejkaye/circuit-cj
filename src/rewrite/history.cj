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
 * Struct for relating inputs and outputs in an evaluator.
 */
public struct InputOutput<V> <: ToString where V <: ValueSymbol<V> {
    public InputOutput(
        let input : Array<Signal<V>>,
        let output : Array<Option<Signal<V>>>
    ){}
    public func toString() : String {
        "${GetArgumentString(this.input)} -> ${GetOutputString(this.output)}"
    }
    public func GetInput() : Array<Signal<V>> {
        this.input
    }
    public func GetOutput() : Array<Option<Signal<V>>> {
        this.output
    }
}
extend InputOutput<V> where V <: Decimal<V> {
    public func GetDecimalString(signed : Bool) : String {
        "${GetArgumentString(this.input, signed: signed)}" +
        " -> ${GetOutputString(this.output, signed: signed)}"
    }
}
/**
 * Struct containing data structures for tracking the input output history of an
 * evaluator.
 */
public struct InputOutputHistory<V> where V <: ValueSymbol<V> {
    public let inputHistoryPerTick : ArrayList<Array<Signal<V>>>
    public let outputHistoryPerTick : ArrayList<Array<Option<Signal<V>>>>
    public let inputOutputHistoryPerTick : ArrayList<InputOutput<V>>
    public let inputHistoryPerPort : Array<ArrayList<Signal<V>>>
    public let outputHistoryPerPort : Array<ArrayList<Option<Signal<V>>>>
    public init(inputs : Int64, outputs : Int64) {
        this.inputHistoryPerTick = ArrayList()
        this.outputHistoryPerTick = ArrayList()
        this.inputOutputHistoryPerTick = ArrayList()
        this.inputHistoryPerPort =
            Array(inputs){ i => ArrayList<Signal<V>>() }
        this.outputHistoryPerPort =
            Array(outputs){ i => ArrayList<Option<Signal<V>>>() }
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
func GetInputOutputString<V> (
    ios : Collection<InputOutput<V>>,
    inputFn : (Array<Signal<V>>) -> String,
    outputFn : (Array<Option<Signal<V>>>) -> String
) : String  where V <: ValueSymbol<V> {
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
    let headerUnderline = "".padRight(totalLength, paddingChar: '=')
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
    public func GetInputHistoryPerPort() : Array<ArrayList<Signal<V>>> {
        this.history.inputHistoryPerPort
    }
    public func GetOutputHistoryPerPort() : Array<ArrayList<Option<Signal<V>>>> {
        this.history.outputHistoryPerPort
    }
    public func GetInputOutputHistoryPerTick() : ArrayList<InputOutput<V>> {
        this.history.inputOutputHistoryPerTick
    }
    public func GetInputOutputHistoryString() : String {
        GetInputOutputString(
            this.history.inputOutputHistoryPerTick,
            { inputs => GetArgumentString(inputs) },
            { outputs => GetOutputString(outputs) }
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
            { outputs => GetOutputString(outputs, signed: signed) }
        )
    }
}