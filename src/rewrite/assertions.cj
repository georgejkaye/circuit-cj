/**
 * rewrite/assertions.cj
 *
 * Assertions for rewriting circuits
 *
 * @author George Kaye
 * @since 0.3
 */

package rewrite

import assertions.*
import graphs.*

public func AssertNoNonDelayGuardedFeedback(f : InterfacedHypergraph) : Unit {
    AssertEmpty(f.GetSequentialData().feedbackConnections, "non-delay-guarded feedback")
}