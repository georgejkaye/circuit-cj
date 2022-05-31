package syntax

from std import collection.ArrayList, collection.HashMap

import debug.*
import settings.*

// HACK: shouldn't be public
public open class Identifiable <: Hashable & Equatable<Identifiable> & ToString {
    static var nextId : Int64 = 0
    protected let id : Int64
    public init() {
        this.id = nextId
        nextId++
    }
    public func hashCode() : Int64 {
        this.id
    }
    public operator func ==(right: Identifiable){
        this.id == right.id
    }
    public operator func !=(right : Identifiable){
        this.id != right.id
    }
    public open func toString() : String {
        this.id.toString()
    }
}

// HACK: shouldn't be public, perhaps 'sealed' when implemented?
public open class Atom <: Identifiable {
    protected let globalId : Int64
    init(){
        this.globalId = super.id
    }
    init(globalId : Option<Int64>){
        this.globalId = globalId.getOrDefault({ => super.id})
    }
}

public open class OwnedAtom<T> <: Atom {
    var owner : Option<T> = None<T>
    protected init() {
        super()
    }
    protected init(globalId : Option<Int64>){
        super(globalId)
    }
    func SetOwner(f : T) : Unit {
        this.owner = Some(f)
    }
    func RemoveOwner(f : T) : Unit {
        this.owner = None
    }
}