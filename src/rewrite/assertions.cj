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

public func AssertNoNonDelayGuardedFeedback<V, G>(f : InterfacedHypergraph<V, G>) : Unit
    where V <: ValueSymbol & Equatable<V>, G <: PrimitiveSymbol<V> & Equatable<G>
{
    AssertEmpty(f.GetSequentialData().feedbackConnections, "non-delay-guarded feedback")
}