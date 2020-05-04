//
//  Mappable.swift
//  CheckScan
//
//  Created by Indir Amerkhanov on 19.12.2019.
//  Copyright © 2019 Warefly. All rights reserved.
//

import CoreData

public struct ManagedObjectContainer: Codable, Equatable {
    let objectID: NSManagedObjectID?
    
    public var urlId: URL? {
        objectID?.uriRepresentation()
    }
    
    enum CodingKeys: String, CodingKey {
        case objectID
    }
    
    public init(from decoder: Decoder) throws {
        self.objectID = nil
    }
    
    public func encode(to encoder: Encoder) throws { }
    
    public init(objectID: NSManagedObjectID?) {
        self.objectID = objectID
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.objectID?.uriRepresentation() == rhs.objectID?.uriRepresentation()
    }
}

public typealias Mappable = MappableType & AnyMappable

public protocol MappableType {
    associatedtype Persistance: NSManagedObject
    
    var objectContainer: ManagedObjectContainer? { get }
    
    func mapManagedObject(target: Persistance)
    static func mapFrom(_ managedObject: Persistance) throws -> Self
    
    static var primaryKey: String? { get }
    
    func withOtherObject(_ object: Self) -> Self
}

public protocol AnyMappable {
    func mapManagedObject(target: Any)
    static func mapFrom(_ managedObject: Any) throws -> Self
}

public extension AnyMappable where Self: MappableType {
    func mapManagedObject(target: Any) {
        guard let persistance = target as? Persistance else {
            return
        }
        
        mapManagedObject(target: persistance)
    }
    
    static func mapFrom(_ managedObject: Any) throws -> Self {
        guard let persistance = managedObject as? Persistance else {
            throw AnyMappableError.unknownError
        }
        
        return try mapFrom(persistance)
    }
    
    static var primaryKey: String? { nil }
}

enum AnyMappableError: Error {
    case unknownError
}

extension MappableType {
    func getIntValue(for primaryKey: String) -> Int? {
        let mirror = Mirror(reflecting: self)
        
        return mirror.children.first(where: { $0.label == primaryKey })?.value as? Int
    }
    
    func getStringValue(for primaryKey: String) -> String? {
        let mirror = Mirror(reflecting: self)
        
        return mirror.children.first(where: { $0.label == primaryKey })?.value as? String
    }
}
