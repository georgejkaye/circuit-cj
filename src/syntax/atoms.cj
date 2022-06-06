package syntax

from std import collection.ArrayList, collection.HashMap

import debug.*
import settings.*

public interface Identifiable {
    func GetId() : Int64
}

public class Identifier <: Identifiable & Hashable & Equatable<Identifier> & ToString {
    static var nextId : Int64 = 0
    let id : Int64
    public init() {
        this.id = nextId
        nextId++
    }
    public func hashCode() : Int64 {
        this.id
    }
    public operator func ==(right: Identifier){
        this.id == right.id
    }
    public operator func !=(right : Identifier){
        this.id != right.id
    }
    public open func toString() : String {
        this.id.toString()
    }
    public func GetId() : Int64 {
        this.id
    }
}

/**
 * An atom can be identified in two ways
 *
 * - by its unique id
 * - by some 'global id' specifying the identity of what this atom represents
 */
public class Atom <: Identifiable {
    let uniqueId : Identifier
    let globalId : Identifier

    public init(globalId : Option<Identifier>)
    {
        this.uniqueId = Identifier()
        this.globalId = globalId.getOrDefault({ => Identifier()})
    }
    public func GetId() {
        this.uniqueId.GetId()
    }
    public func GetGlobalID() {
        this.globalId.GetId()
    }
}