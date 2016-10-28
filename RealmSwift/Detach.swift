//
//  Detach.swift
//  Realm
//
//  Created by Alexandre Esteves on 22/10/16.
//  Copyright © 2016 Realm. All rights reserved.
//
import Realm

typealias PropertyInfo = (name: String, objectClassName: String?, type: PropertyType)
typealias Copier = (UInt?) -> (Object) -> Object
typealias RLMCopier = (UInt?) -> (RLMObject) -> RLMObject

protocol ObjectLike: class {
    init()
    subscript(key: String) -> Any? { get set }
    var properties: [PropertyInfo] { get }
}


extension RLMObject: ObjectLike {
    var properties: [PropertyInfo] {
        return objectSchema.properties.map {
            ($0.name, $0.objectClassName, $0.type)
        }
    }
}
extension Object: ObjectLike {
    var properties: [PropertyInfo] {
        return objectSchema.properties.map {
            ($0.name, $0.objectClassName, $0.type)
        }
    }
}

public extension Object {
    func detach(_ depth: UInt? = nil) -> Self {
        return detachFromRealm(depth)(self)
    }
}
public extension RLMObject {
    func detach(_ depth: UInt? = nil) -> Self {
        return detachFromRealm(depth)(self)
    }
}

func detachFromRealm <O: Object> (_ maxDepth: UInt?) -> (O) -> O {
    return { old in
        copyObject(detachFromRealm, detachFromRealm, old, maxDepth)
    }
}

func detachFromRealm <O: RLMObject> (_ maxDepth: UInt?) -> (O) -> O {
    return { old in
        copyObject(detachFromRealm, detachFromRealm, old, maxDepth)
    }
}

private func copyObject <O: ObjectLike> (_ rlmCopier: @escaping RLMCopier, _ copier: @escaping Copier, _ old: O, _ maxDepth: UInt?) -> O {
    let claz = type(of: old)
    let new = claz.init()
    copyFields(rlmCopier, copier, old, new, maxDepth)
    return new
}

private func copyFields (_ rlmCopier: @escaping RLMCopier, _ copier: @escaping Copier, _ old: ObjectLike, _ new: ObjectLike, _ maxDepth: UInt?) {
    func dec (_ i: UInt?) -> UInt? {
        return i.map{$0 - 1}
    }
    func identity <T> (_ t: T) -> T {
        return t
    }

    func copyProp(_ name: String, _ className: String?, _ propertyType: PropertyType) {
        switch propertyType {
        case .any,
             .linkingObjects: break;
        case .bool,
             .data,
             .date,
             .double,
             .float,
             .int,
             .string,
             .object where maxDepth == .some(0),
             .array  where maxDepth == .some(0):
            new[name] = old[name]
        case .object:
            new[name] = (old[name] as? Object).map(copier(dec(maxDepth)))
        case .array:
            let elementCopier = maxDepth == .some(1) ? identity : rlmCopier(dec(dec(maxDepth)))
            
            let list = old[name] as! RLMListBase
            let oldArr = list._rlmArray
            let newArr = RLMArray.init(objectClassName: className!)
            
            for i in 0..<oldArr.count {
                newArr.add(elementCopier(oldArr[i]))
            }
            new[name] = RLMListBase(array: newArr)
        }
    }
    old.properties.forEach(copyProp)
}
