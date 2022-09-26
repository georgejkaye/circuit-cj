/**
 * syntax/assertions,cj
 *
 * Assertions for the syntax package
 *
 * @author George Kaye
 * @since 0.3
 */

package syntax

func AssertSignalsSameWidth(
    vs : Array<Signal>
) : Int64 {
    AssertArrayAllSameParameter<Signal, Int64>(
        vs,
        { v : Signal => v.GetWidth() },
        Width
    )
}