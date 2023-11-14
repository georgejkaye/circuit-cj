/**
 * rewrite/waves.cj
 *
 * Waveform visualiser, inspired by hardcaml_waveterm
 * https://github.com/janestreet/hardcaml_waveterm
 *
 * @author George Kaye
 * @since 0.3
 */
package rewrite
// Components for drawing waveforms
let defaultComponentLength = 8
let offSignalString = ("", ' ')
let onSignalString = ("", '─')
let highToLowUpString = ("┐", ' ')
let highToLowDownString = ("└", '─')
let lowToHighUpString = ("┌", '─')
let lowToHighDownString = ("┘", ' ')
let upDownString = ("|", ' ')
/**
 * Get a colour code to be interpreted by a command that can understand and
 * intepret the relevant escape sequences.
 *
 * @param value The sequence to inject into the colour escape sequence
 * @return The colour generating escape sequence
 */
func GetColourCode(value : String) : String {
    "\\033[0;${value}m"
}
let off = GetColourCode("")
let cyan = GetColourCode("36")
let green = GetColourCode("32")
let yellow = GetColourCode("33")
/**
 * The colour to use for drawing the actual waveforms, to help distinguish them
 * from the rest of the diagram
 */
let waveColour = green
/**
 * Get the new line character based on whether we want to escape it or not.
 * Escaping is necessary when writing text to be passed to something that will
 * then be printed later interpreting escape sequences, such as echo -e.
 *
 * @param escaped
 * @return The appropriate newline character
 */
func GetNewline(escaped : Bool) : String {
    if(escaped) { "\\n" } else { "\n" }
}
/**
 * Create a padded string given a tuple of a starting string and a padding
 * character.
 *
 * @param symbols The tuple (starting string, padding char)
 * @param length The length to pad to
 * @return The padded string
 */
func GetAndPadWaveSymbol(symbols : (String, Char), length : Int64) : String {
    let (firstChar, padChar) = symbols
    firstChar.padRight(length, paddingChar: padChar)
}
/**
 * Attempt to get the waveform level at a given tick of the clock of a waveform
 * for a given bit of a signal.
 *
 * @param ticks a list of elements that can be transformed into optional signals
 * @param bit The bit of the signal to consider
 * @param currentTick The tick of the clock to consider
 * @param fn The function to extract an optional signal
 * @return The level this waveform should be drawn at, or None if there is no
 *              associated level
 */
func GetLevel<V, T>(
    ticks : ArrayList<T>, bit : Int64, tick : Int64,
    fn : (T) -> Option<Signal<V>>
) : Option<Int64>
    where V <: ValueSymbol<V>
{
    let currentTick = ticks[tick]
    match(fn(currentTick)) {
        case None => None
        case Some(signal) =>
            let currentBit = signal.GetBit(bit)
            currentBit.GetWaveformLevel()
    }
}
/**
 * Get the start string and pad character for a waveform level for a bit where
 * the level is stable i.e. the previous level was the same as the current one,
 * or was not drawn.
 *
 * @param drawingLevel The level being drawn
 * @param activeLevel The level is currently powered on
 * @return The string for the level
 */
func StableSignal(drawingLevel : Int64, activeLevel : Int64) : (String, Char) {
    if(drawingLevel != activeLevel) {
        offSignalString
    } else {
        onSignalString
    }
}
/**
 * Get the start string and pad character for a waveform level for a bit where
 * the level is going up i.e. one where the previous level was lower than the
 * current one.
 *
 * @param drawingLevel The level being drawn
 * @param activeLevel The level is currently powered on
 * @param previousActiveLevel The level that was previously powered on
 * @return The string for the level
 */
func GoingUpSignal(
    drawingLevel : Int64, activeLevel : Int64, previousActiveLevel : Int64
) : (String, Char) {
    // The waveform needs to go up
    if(drawingLevel == previousActiveLevel) {
        lowToHighDownString
    // The waveform needs to flatten out
    } else if (drawingLevel == activeLevel) {
        lowToHighUpString
    // The waveform is going up
    } else if(drawingLevel < activeLevel && drawingLevel > previousActiveLevel) {
        upDownString
    // The waveform is not present at this level
    } else {
        offSignalString
    }
}
/**
 * Get the start string and pad character for a waveform level for a bit where
 * the level is going down i.e. one where the previous level was higher than the
 * current one.
 *
 * @param drawingLevel The level being drawn
 * @param activeLevel The level is currently powered on
 * @param previousActiveLevel The level that was previously powered on
 * @return The string for the level
 */
func GoingDownSignal(
    drawingLevel : Int64, activeLevel : Int64, previousActiveLevel : Int64
) : (String, Char) {
    // The waveform needs to go down
    if(drawingLevel == previousActiveLevel) {
        highToLowUpString
    // The waveform needs to flatten out
    } else if (drawingLevel == activeLevel) {
        highToLowDownString
    // The waveform is going down
    } else if(
        drawingLevel > activeLevel && drawingLevel < previousActiveLevel
    ) {
        upDownString
    // The waveform is not present at this level
    } else {
        offSignalString
    }
}
/**
 * Get the string for a given tick of a waveform level.
 *
 * @param ticks
 * @param fn Function for getting signals out of T
 * @param currentBit
 * @param currentLogicalDrawingLevel
 * @param componentLength
 * @param previousTicks
 * @param currentTick
 */
func DrawWaveformLevelTick<V, T>(
    ticks : ArrayList<T>, fn : (T) -> Option<Signal<V>>, currentBit : Int64,
    currentLogicalDrawingLevel : Int64, componentLength : Int64,
    currentTickIndex : Int64
) : String where V <: ValueSymbol<V> {
    let currentActiveLevelOpt =
        GetLevel(ticks, currentBit, currentTickIndex, fn)
    let currentTickChars = match(currentActiveLevelOpt) {
        case None => offSignalString
        case Some(currentActiveLevel) =>
            let previousActiveLevelOpt =
                if(currentTickIndex == 0) {
                    currentActiveLevelOpt
                } else {
                    GetLevel(ticks, currentBit, currentTickIndex - 1, fn)
                }
            // Check against the previous signal to see if the waveform
            // is rising or falling this tick of the
            match(previousActiveLevelOpt) {
                // If there was no previous level, just begin emitting
                // the signal (no rise or fall in edge)
                case None =>
                    StableSignal(
                        currentLogicalDrawingLevel, currentActiveLevel
                    )
                // If there was a previous level, determine the
                // direction of the waveform
                case Some(previousActiveLevel) =>
                    if(previousActiveLevel < currentActiveLevel) {
                        GoingUpSignal(
                            currentLogicalDrawingLevel,
                            currentActiveLevel,
                            previousActiveLevel
                        )
                    } else if(previousActiveLevel > currentActiveLevel) {
                        GoingDownSignal(
                            currentLogicalDrawingLevel,
                            currentActiveLevel,
                            previousActiveLevel
                        )
                    } else {
                        StableSignal(
                            currentLogicalDrawingLevel,
                            currentActiveLevel
                        )
                    }
            }
    }
    GetAndPadWaveSymbol(currentTickChars, componentLength)
}
/**
 * Draw the level of a waveform for a given tick of a given bit of a signal.
 *
 * @param ticks A list of elements that can be interpreted as optional signals
 * @param currentBit
 * @param currentPhysicalDrawingLevel
 *          The index of the level according to the page (0 is at the top)
 * @param currentLogicalDrawingLevel
 *          The index of the level according to the signal (0 is at the bottom)
 * @param waveformName
 * @param maxNameLength
 * @return The level of the waveform
 */
func DrawWaveformLevel<V, T>(
    ticks : ArrayList<T>, currentBit : Int64,
    currentPhysicalDrawingLevel : Int64,currentLogicalDrawingLevel : Int64,
    fn : (T) -> Option<Signal<V>>, waveformName : String, maxNameLength : Int64,
    componentLength : Int64, coloured!: Bool = false
) : String
    where V <: ValueSymbol<V>
{
    let colour = if(coloured) { waveColour } else { "" }
    let prefix = if(currentPhysicalDrawingLevel == 0) {
        if(waveformName.size > maxNameLength) {
            waveformName.substring(0, maxNameLength)
        } else if (waveformName.size == maxNameLength) {
            waveformName
        } else {
            waveformName.padRight(maxNameLength)
        }
    } else {
        "".padRight(maxNameLength)
    }
    let line = concatStrings(
        { currentTick : Int64 =>
            DrawWaveformLevelTick(
                ticks, fn, currentBit, currentLogicalDrawingLevel,
                componentLength, currentTick
            )
        }, initial: "${prefix}${colour}", end: ticks.size
    )
    if(coloured) { "${line}${off}" } else { line }
}
/**
 * Draw the port overview for a single tick.
 *
 * @param ticks
 * @param signalFn The function turning Ts into maybe signals
 * @param signalDisplayFn The function turning maybe signals into strings
 * @param componentLength
 * @param currentTick
 */
func DrawPortOverviewForTick<V, T>(
    ticks : ArrayList<T>,
    signalFn : (T) -> Option<Signal<V>>,
    signalDisplayFn : (Option<Signal<V>>) -> String,
    componentLength: Int64,
    currentTick : Int64
) : String where V <: ValueSymbol<V> {
    let maybeSignal = signalFn(ticks[currentTick])
    let isStartOfSignal =
        currentTick == 0 || signalFn(ticks[currentTick - 1]) != maybeSignal
    let symbols = if(isStartOfSignal) {
        let signalDisplay = signalDisplayFn(maybeSignal)
        if(signalDisplay.size >= componentLength) {
            ("|", '*')
        } else {
            ("|${signalDisplay}", ' ')
        }
    } else {
        ("", ' ')
    }
    GetAndPadWaveSymbol(symbols, componentLength)
}
/**
 * Draw the port overview: the line at the top of the waveform diagram
 * naming the signals observed at the port and denoting when they change,
 *
 * @param ticks
 * @param signalFn The function turning elements of ticks into maybe signals
 * @param maxNameLength
 * @param signalDisplayFn The function turning maybe signals into strings
 * @param componentLength
 * @return The signal overview string
 */
func DrawPortOverview<V, T>(
    ticks : ArrayList<T>, signalFn : (T) -> Option<Signal<V>>,
    maxNameLength : Int64, signalDisplayFn : (Option<Signal<V>>) -> String,
    componentLength : Int64
) : String where V <: ValueSymbol<V> {
    let prefix = "".padRight(maxNameLength)
    concatStrings(
        { i =>
            DrawPortOverviewForTick(
                ticks, signalFn, signalDisplayFn, componentLength, i
            )
        }, initial: prefix, end: ticks.size
    )
}
/**
 * Draw the header for a waveform diagram, giving the name of the port being
 * watched, and the values of the signals seen.
 *
 * @param ticks
 * @param signalFn The function from Ts to maybe signals
 * @param portName
 * @param longestPortName The length to pad the port name to
 * @param signalDisplayFn The function from maybe signals to strings
 * @param componentLength
 * @return The string for the waveform header
 */
func DrawPortHeader<V, T>(
    ticks : ArrayList<T>, signalFn : (T) -> Option<Signal<V>>,
    portName : String, longestPortName : Int64,
    signalDisplayFn : (Option<Signal<V>>) -> String,  componentLength : Int64,
    coloured!: Bool = false, drawLabels!: Bool = true
) : String where V <: ValueSymbol<V> {
    let newline = GetNewline(coloured)
    let actualSignalName =
        if(portName == "") {
            "_"
        } else {
            portName
        }
    let waveformLength = ticks.size * componentLength
    let lineLength = longestPortName + waveformLength
    let firstLine =
        "${actualSignalName} ".padRight(lineLength, paddingChar: '─')
    let labelLines = if(!drawLabels) {
        ""
    } else {
        let secondLine = DrawPortOverview(
            ticks, signalFn, longestPortName, signalDisplayFn, componentLength
        )
        let thirdLine = "".padRight(lineLength, paddingChar: '─')
        "${newline}${secondLine}${newline}${thirdLine}"
    }
    "${firstLine}${labelLines}"
}
/**
 * Draw the waveforms for a signal across a given list of ticks.
 *
 * @param ticks The list of elements to be interpreted as an optional signal
 * @param fn The function to interpret elements as optional signals
 * @param width The width of the signal
 * @param waveformName
 * @param maxNameLength
 * @return The string visualising the waveforms for this signal
 */
func DrawWaveformsForPort<V, T>(
    ticks : ArrayList<T>, fn : (T) -> Option<Signal<V>>, width : Int64,
    signalName : String, maxNameLength : Int64,
    signalDisplayFn!: (Option<Signal<V>>) -> String,
    componentLength!: Int64 = defaultComponentLength, coloured!: Bool = false,
    drawWaves!: Bool = true, drawLabels!: Bool = true
) : String
    where V <: ValueSymbol<V>
{
    let newline = GetNewline(coloured)
    let linesPerValue = V.GetWaveformHeight() + 1
    let totalLines = linesPerValue * width
    let waveformLength = ticks.size * componentLength
    let lineLength = maxNameLength + waveformLength
    let signalHeading = DrawPortHeader(
        ticks, fn, signalName, maxNameLength, signalDisplayFn, componentLength,
        coloured: coloured, drawLabels: drawLabels
    )
    if(!drawWaves) {
        signalHeading
    } else {
        let rows = fold_left(
            { acc, currentLine =>
                // We want to draw the msb at the top and work down
                let currentBit = width - (currentLine / linesPerValue) - 1
                let currentPhysicalDrawingLevel = currentLine % linesPerValue
                // The lowest level should be drawn at the bottom
                let currentLogicalDrawingLevel =
                    linesPerValue - currentPhysicalDrawingLevel - 1
                let rowString =
                    DrawWaveformLevel(
                        ticks, currentBit, currentPhysicalDrawingLevel,
                        currentLogicalDrawingLevel, fn,
                        "[${currentBit}]", maxNameLength, componentLength,
                        coloured: coloured
                    )
                "${acc}${newline}${rowString}"
            }, "${signalHeading}", end: totalLines
        )
        "${rows}${newline}${"".padRight(lineLength, paddingChar: '─')}"
    }
}
/**
 * @return
 *      The default function for displaying maybe signals: empty if there is no
 *      signal, or the name of the signal otherwise.
 */
func DefaultSignalDisplayFn<V>() : (Option<Signal<V>>) -> String
    where V <: ValueSymbol<V>
{
    { sopt : Option<Signal<V>> =>
        match(sopt) {
            case None => ""
            case Some(s) => s.GetName()
        }
    }
}
/**
 * Get the default label length for an array of arraylists of signals: a
 * function of the name, the string of the index, and some constant padding.
 *
 * @param signals
 * @param nameFn The function transforming indices into their names
 * @param widthFn The function transforming indices into their width
 * @return The label length for these signals
 */
func DefaultLabelLengthForPortArray<T>(
    signals : Array<ArrayList<T>>, nameFn: (Int64) -> String,
    widthFn : (Int64) -> Int64
) : Int64
{
    max(
        signals,
        { i, t =>
            let name = nameFn(i)
            let width = "[${widthFn(i)}]"
            name.size + width.size + 4
        }
    )
}
/**
 * Draw the waveforms for an array of ports with lists of incident signals.
 *
 * @param signals The array of lists of the optional signals over time
 * @param fn The function to interpret elements as optional signals
 * @param widthFn The function to get the width of each index of signals
 * @param signalDisplayFn How the print the signals in shorthand
 * @return A string visualising the waveforms
 */
public func DrawWaveformsForPortArray<V, T>(
    ports : Array<ArrayList<T>>, fn : (T) -> Option<Signal<V>>,
    widthFn : (Int64) -> Int64, nameFn : (Int64) -> String,
    signalDisplayFn!: (Option<Signal<V>>) -> String = DefaultSignalDisplayFn(),
    componentLength!: Int64 = defaultComponentLength,
    labelLength!: Int64 =
        DefaultLabelLengthForPortArray(ports, nameFn, widthFn),
    coloured!: Bool = false, drawWaves!: Bool = true, drawLabels!: Bool = true
) : String
    where V <: ValueSymbol<V>
{
    let waveforms = mapi<ArrayList<T>, String>(
        { xs, i =>
            DrawWaveformsForPort<V, T>(
                xs, fn, widthFn(i), nameFn(i), labelLength,
                signalDisplayFn: signalDisplayFn,
                componentLength: componentLength, coloured: coloured,
                drawWaves: drawWaves, drawLabels: drawLabels
            )
        },
        ports
    )
    concatStrings(
        waveforms, delimiter: "${GetNewline(coloured)}${GetNewline(coloured)}"
    )
}
/**
 * Let evaluators draw waveform diagrams
 */
extend Evaluator<V,G> {
    /**
     * Draw the waveform diagram for the input output history of an evaluator
     *
     * @param signalDisplayFn
     * @param componentLength
     */
    public func DrawWaveformDiagram(
        signalDisplayFn!: (Option<Signal<V>>) -> String =
            DefaultSignalDisplayFn<V>(),
            componentLength!: Int64 = defaultComponentLength,
            coloured!: Bool = false,
            drawWaves!: Bool = true,
            drawLabels!: Bool = true
    ) : String {
        let labelLength = this.longestPortName + 4
        let inputWaves = DrawWaveformsForPortArray(
            this.GetInputHistoryPerPort(),
            { t => match(t){
                case DEFINITE(s) => Some(s)
                case _ => None
            }},
            { i => this.GetInput(i).GetWidth() },
            { i => this.GetInput(i).GetNameString() },
            labelLength: labelLength,
            signalDisplayFn: signalDisplayFn,
            componentLength: componentLength,
            coloured: coloured,
            drawWaves: drawWaves,
            drawLabels: drawLabels
        )
        let getSignalFromOutput = {
            op : OutputData<V, G> =>
                match(op.term) {
                    case BASE(ci) =>
                        match(ci){
                            case DEFINITE(s) => Some(s)
                            case _ => None<Signal<V>>
                        }
                    case _ => None<Signal<V>>
                }
        }
        let outputWaves = DrawWaveformsForPortArray(
            this.GetOutputHistoryPerPort(),
            getSignalFromOutput,
            { i : Int64 => this.GetOutput(i).GetWidth() },
            { i : Int64 => this.GetOutput(i).GetNameString() },
            labelLength: labelLength,
            signalDisplayFn: signalDisplayFn,
            componentLength: componentLength,
            coloured: coloured,
            drawWaves: drawWaves,
            drawLabels: drawLabels
        )
        let newline = GetNewline(coloured)
        "${inputWaves}${newline}${newline}${outputWaves}"
    }
}
////////////////////////////////////////////////////////////////////////////////
//                          Waveforms for decimals                            //
////////////////////////////////////////////////////////////////////////////////

func OptionalDecSignalDisplayFn<V>(
    signed!: Bool
) : (Option<Signal<V>>) -> String
    where V <: ValueSymbol<V> & Decimal<V>
{
    { sopt : Option<Signal<V>> =>
        match(sopt) {
            case None => ""
            case Some(s) =>
                match(V.SignalToDec(s, signed: signed)){
                    case None => s.GetName()
                    case Some(n) => "${n}"
                }
        }
    }
}
/**
 * Draw the waveforms for an array of ports, with labels in decimal.
 *
 * @param signals The array of lists of the optional signals over time
 * @param fn The function to interpret elements as optional signals
 * @param widthFn The function to get the width of each element of signals
 * @param signed Whether to interpret signals in decimal
 * @return A string visualising the waveforms
 */
public func DrawWaveformsForPortArray<V, T>(
    signals : Array<ArrayList<T>>, fn : (T) -> Option<Signal<V>>,
    widthFn : (Int64) -> Int64, nameFn : (Int64) -> String, signed!: Bool,
    componentLength!: Int64 = defaultComponentLength,
    labelLength!: Int64 =
        max(
        signals,
            { i, t =>
                let name = nameFn(i)
                let width = "[${widthFn(i)}]"
                name.size + width.size + 4
            }
        ), coloured!: Bool = false
) : String
    where V <: ValueSymbol<V> & Decimal<V>
{
    let signalDisplayFn = OptionalDecSignalDisplayFn<V>(signed: signed)
    DrawWaveformsForPortArray(
        signals, fn, widthFn, nameFn, signalDisplayFn: signalDisplayFn,
        labelLength: labelLength, componentLength: componentLength,
        coloured: coloured
    )
}
extend Evaluator<V, G> where V <: Decimal<V> {
    public func DrawWaveformDiagram(
        signed!: Bool, componentLength!: Int64 = defaultComponentLength,
        coloured!: Bool = false
    ) : String {
        this.DrawWaveformDiagram(
            signalDisplayFn: OptionalDecSignalDisplayFn<V>(signed: signed),
            componentLength: componentLength, coloured: coloured
        )
    }
}