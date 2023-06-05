
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
let componentLength = 4
let offSignalString = "".padRight(componentLength, paddingChar: ' ')
let onSignalString = "".padRight(componentLength, paddingChar: '─')
let highToLowUpString = "┐".padRight(componentLength, paddingChar: ' ')
let highToLowDownString = "└".padRight(componentLength, paddingChar: '─')
let lowToHighUpString = "┌".padRight(componentLength, paddingChar: '─')
let lowToHighDownString = "┘".padRight(componentLength, paddingChar: ' ')
let upDownString = "|".padRight(componentLength, paddingChar: ' ')
/**
 * Attempt to get the waveform level at a given tick of the clock of a waveform
 * for a given bit of a signal
 *
 * @param ticks a list of elements that can be transformed into optional signals
 * @param bit The bit of the signal to consider
 * @param tick The tick of the clock to consider
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
 * Get the string for a waveform level for a bit where the level is stable
 * i.e. the previous level was the same as the current one, or was not drawn.
 *
 * @param drawingLevel The level being drawn
 * @param activeLevel The level is currently powered on
 * @return The string for the level
 */
func StableSignal(drawingLevel : Int64, activeLevel : Int64) : String {
    if(drawingLevel != activeLevel) {
        offSignalString
    } else {
        onSignalString
    }
}
/**
 * Get the string for a waveform level for a bit where the level is going up
 * i.e. one where the previous level was lower than the current one.
 *
 * @param drawingLevel The level being drawn
 * @param activeLevel The level is currently powered on
 * @param previousActiveLevel The level that was previously powered on
 * @return The string for the level
 */
func GoingUpSignal(
    drawingLevel : Int64, activeLevel : Int64, previousActiveLevel : Int64
) : String {
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
 * Get the string for a waveform level for a bit where the level is going down
 * i.e. one where the previous level was higher than the current one.
 *
 * @param drawingLevel The level being drawn
 * @param activeLevel The level is currently powered on
 * @param previousActiveLevel The level that was previously powered on
 * @return The string for the level
 */
func GoingDownSignal(
    drawingLevel : Int64, activeLevel : Int64, previousActiveLevel : Int64
) : String {
    // The waveform needs to go down
    if(drawingLevel == previousActiveLevel) {
        highToLowUpString
    // The waveform needs to flatten out
    } else if (drawingLevel == activeLevel) {
        highToLowDownString
    // The waveform is going down
    } else if(drawingLevel > activeLevel && drawingLevel < previousActiveLevel) {
        upDownString
    // The waveform is not present at this level
    } else {
        offSignalString
    }
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
    ticks : ArrayList<T>, currentBit : Int64, currentPhysicalDrawingLevel : Int64,
    currentLogicalDrawingLevel : Int64, fn : (T) -> Option<Signal<V>>,
    waveformName : String, maxNameLength : Int64
) : String
    where V <: ValueSymbol<V>
{
    let prefix = if(currentPhysicalDrawingLevel == 0) {
        waveformName.padRight(maxNameLength)
    } else {
        "".padRight(maxNameLength)
    }
    fold_left(
        { acc, currentTick : Int64 =>
            let currentActiveLevelOpt =
                GetLevel(ticks, currentBit, currentTick, fn)
            let currentTickString = match(currentActiveLevelOpt) {
                case None => offSignalString
                case Some(currentActiveLevel) =>
                    let previousActiveLevelOpt =
                        if(currentTick == 0) {
                            currentActiveLevelOpt
                        } else {
                            GetLevel(ticks, currentBit, currentTick - 1, fn)
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
            "${acc}${currentTickString}"
    }, prefix, end: ticks.size)
}
func DrawSignalOverview<V, T>(
    ticks : ArrayList<T>, fn : (T) -> Option<Signal<V>>, width : Int64,
    maxNameLength : Int64, signalDisplayFn : (Option<Signal<V>>) -> String
) : String where V <: ValueSymbol<V> {
    let prefix = "".padRight(maxNameLength)
    foldi_left(
        { acc, i, cur =>
            let maybeSignal = fn(cur)
            let text =
                if(i == 0 || fn(ticks[i-1]) != maybeSignal) {
                    let signalDisplay = signalDisplayFn(maybeSignal)
                    let signalLength = fold_left_while(
                        { acc, next =>
                            if(fn(next) == maybeSignal) {
                                (acc + componentLength, false)
                            } else {
                                (acc, true)
                            }
                        }, componentLength, ticks, start: i+1
                    )
                    if(signalDisplay.size >= signalLength) {
                        "|".padRight(signalLength, paddingChar: '*')
                    } else {
                        "|${signalDisplay}".padRight(signalLength)
                    }
                } else {
                    ""
                }
            "${acc}${text}"
        },
        "${prefix}",
        ticks
    )
}
func DrawWaveformHeaderForSignal<V, T>(
    ticks : ArrayList<T>, fn : (T) -> Option<Signal<V>>, width : Int64,
    signalName : String, maxNameLength : Int64,
    signalDisplayFn : (Option<Signal<V>>) -> String
) : String where V <: ValueSymbol<V> {
    let actualSignalName =
        if(signalName == "") {
            "_"
        } else {
            signalName
        }
    let waveformLength = ticks.size * componentLength
    let lineLength = maxNameLength + waveformLength
    let firstLine =
        "${actualSignalName} ".padRight(lineLength, paddingChar: '─')
    let secondLine = DrawSignalOverview(
        ticks, fn, width, maxNameLength, signalDisplayFn
    )
    let thirdLine = "".padRight(lineLength, paddingChar: '─')
    "${firstLine}\n${secondLine}\n${thirdLine}"
}
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
 * Draw the waveforms for a signal across a given list of ticks.
 *
 * @param ticks The list of elements to be interpreted as an optional signal
 * @param fn The function to interpret elements as optional signals
 * @param width The width of the signal
 * @param waveformName
 * @param maxNameLength
 * @return The string visualising the waveforms for this signal
 */
func DrawWaveformsForSignal<V, T>(
    ticks : ArrayList<T>, fn : (T) -> Option<Signal<V>>, width : Int64,
    signalName : String, maxNameLength : Int64,
    signalDisplayFn!: (Option<Signal<V>>) -> String
) : String
    where V <: ValueSymbol<V>
{
    let linesPerValue = V.GetHighestWaveformLevel() + 1
    let totalLines = linesPerValue * width
    let waveformLength = ticks.size * componentLength
    let lineLength = maxNameLength + waveformLength
    let signalHeading = DrawWaveformHeaderForSignal(
        ticks, fn, width, signalName, maxNameLength, signalDisplayFn
    )
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
                    "[${currentBit}]", maxNameLength
                )
            "${acc}\n${rowString}"
        }, "${signalHeading}", end: totalLines
    )
    "${rows}\n${"".padRight(lineLength, paddingChar: '─')}"
}
/**
 * Draw the waveforms for an array of signals.
 *
 * @param signals The array of lists of the optional signals over time
 * @param fn The function to interpret elements as optional signals
 * @param widthFn The function to get the width of each element of signals
 * @param signalDisplayFn How the print the signals in shorthand
 * @return A string visualising the waveforms
 */
public func DrawWaveformsForSignalArray<V, T>(
    signals : Array<ArrayList<T>>, fn : (T) -> Option<Signal<V>>,
    widthFn : (Int64) -> Int64, nameFn : (Int64) -> String,
    signalDisplayFn!: (Option<Signal<V>>) -> String = DefaultSignalDisplayFn()
) : String
    where V <: ValueSymbol<V>
{
    let maximumLength = max(
        signals,
        { i, t =>
            let name = nameFn(i)
            let width = "[${widthFn(i)}]"
            name.size + width.size + 4
        }
    )
    let waveforms = mapi<ArrayList<T>, String>(
        { xs, i =>
            DrawWaveformsForSignal<V, T>(
                xs, fn, widthFn(i), nameFn(i), maximumLength,
                signalDisplayFn: signalDisplayFn
            )
        },
        signals
    )
    concatStrings(waveforms, delimiter: "\n\n")
}
/**
 * Draw the waveforms for an array of signals, with labels in decimal.
 *
 * @param signals The array of lists of the optional signals over time
 * @param fn The function to interpret elements as optional signals
 * @param widthFn The function to get the width of each element of signals
 * @param signed Whether to interpret signals in decimal
 * @return A string visualising the waveforms
 */
public func DrawWaveformsForSignalArray<V, T>(
    signals : Array<ArrayList<T>>, fn : (T) -> Option<Signal<V>>,
    widthFn : (Int64) -> Int64, nameFn : (Int64) -> String, signed!: Bool
) : String
    where V <: ValueSymbol<V> & Decimal<V>
{
    let signalDisplayFn =
        { sopt : Option<Signal<V>> =>
            match(sopt) {
                case None => ""
                case Some(s) =>
                    match(V.SignalToDec(s, signed)){
                        case None => s.GetName()
                        case Some(n) => "${n}"
                    }
            }
        }
    DrawWaveformsForSignalArray(
        signals, fn, widthFn, nameFn, signalDisplayFn: signalDisplayFn
    )
}