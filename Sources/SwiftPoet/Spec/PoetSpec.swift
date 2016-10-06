//
//  PoetSpec.swift
//  SwiftPoet
//
//  Created by Kyle Dorman on 11/10/15.
//
//


import Foundation

public protocol PoetSpecType {
    var name: String { get }
    var construct: Construct { get }
    var modifiers: Set<Modifier> { get }
    var description: String? { get }
    var framework: String? { get }
    var imports: Set<String> { get }
}

open class PoetSpec: PoetSpecType, Emitter, Importable {
    open let name: String
    open let construct: Construct
    open let modifiers: Set<Modifier>
    open let description: String?
    open let framework: String?
    open let imports: Set<String>

    public init(name: String, construct: Construct, modifiers: Set<Modifier>, description: String?, framework: String?, imports: Set<String>) {
        self.name = name
        self.construct = construct
        self.modifiers = modifiers
        self.description = description
        self.framework = framework
        self.imports = imports
    }

    open func emit(to writer: CodeWriter) -> CodeWriter {
        fatalError("Override emit method in child")
    }

    open func collectImports() -> Set<String> {
        fatalError("Override collectImports method in child")
    }

    open func toFile() -> PoetFile {
        return PoetFile(spec: self, framework: framework)
    }

    open func toString() -> String {
        return emit(to: CodeWriter()).out
    }
}

extension PoetSpec: Equatable {}

public func ==(lhs: PoetSpec, rhs: PoetSpec) -> Bool {
    return type(of: lhs) == type(of: rhs) && lhs.toString() == rhs.toString()
}

extension PoetSpec: Hashable {
    public var hashValue: Int {
        return self.toString().hashValue
    }
}

open class PoetSpecBuilder: PoetSpecType {
    open let name: String
    open let construct: Construct
    open fileprivate(set) var modifiers = Set<Modifier>()
    open fileprivate(set) var description: String? = nil
    open fileprivate(set) var framework: String? = nil
    open fileprivate(set) var imports = Set<String>()

    public init(name: String, construct: Construct) {
        self.name = name // clean the string in child
        self.construct = construct
    }

    internal func mutatingAdd(modifier toAdd: Modifier) {
        modifiers.insert(toAdd)
    }

    internal func mutatingAdd(modifiers toAdd: [Modifier]) {
        toAdd.forEach { mutatingAdd(modifier: $0) }
    }

    internal func mutatingAdd(description toAdd: String?) {
        self.description = toAdd
    }

    internal func mutatingAdd(framework toAdd: String?) {
        self.framework = toAdd?.cleaned(case: .typeName)
    }

    internal func mutatingAdd(import toAdd: String) {
        self.imports.insert(toAdd)
    }

    internal func mutatingAdd(imports toAdd: [String]) {
        toAdd.forEach { mutatingAdd(import: $0) }
    }
}
