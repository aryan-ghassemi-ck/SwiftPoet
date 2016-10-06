//
//  ParameterSpec.swift
//  SwiftPoet
//
//  Created by Kyle Dorman on 11/10/15.
//
//

import Foundation
public protocol ParameterSpecProtocol {
    var type: TypeName { get }
}

open class ParameterSpec: PoetSpec, ParameterSpecProtocol {
    open let type: TypeName

    fileprivate init(builder: ParameterSpecBuilder) {
        self.type = builder.type
        super.init(name: builder.name, construct: builder.construct, modifiers: builder.modifiers,
                   description: builder.description, framework: builder.framework, imports: builder.imports)
    }

    open static func builder(for name: String, type: TypeName, construct: Construct? = nil) -> ParameterSpecBuilder {
        return ParameterSpecBuilder(name: name, type: type, construct: construct)
    }

    open override func collectImports() -> Set<String> {
        return type.collectImports().union(imports)
    }

    @discardableResult
    open override func emit(to writer: CodeWriter) -> CodeWriter {
        let cbBuilder = CodeBlock.builder()
        if (construct == .mutableParam) {
            cbBuilder.add(literal: construct)
        }
        cbBuilder.add(literal: name)
        cbBuilder.add(literal: ":")
        cbBuilder.add(literal: type)
        writer.emit(codeBlock: cbBuilder.build())
        return writer
    }
}

open class ParameterSpecBuilder: PoetSpecBuilder, Builder, ParameterSpecProtocol {
    public typealias Result = ParameterSpec
    open static let defaultConstruct: Construct = .param

    open let type: TypeName

    fileprivate init(name: String, type: TypeName, construct: Construct? = nil) {
        self.type = type
        let requiredConstruct = construct == nil || construct! != .mutableParam ? ParameterSpecBuilder.defaultConstruct : construct!
        super.init(name: name.cleaned(case: .paramName), construct: requiredConstruct)
    }

    open func build() -> Result {
        return ParameterSpec(builder: self)
    }

}

// MARK: Chaining
extension ParameterSpecBuilder {

    @discardableResult
    public func add(modifier toAdd: Modifier) -> Self {
        mutatingAdd(modifier: toAdd)
        return self
    }

    @discardableResult
    public func add(modifiers toAdd: [Modifier]) -> Self {
        mutatingAdd(modifiers: toAdd)
        return self
    }

    @discardableResult
    public func add(description toAdd: String?) -> Self {
        mutatingAdd(description: toAdd)
        return self
    }

    @discardableResult
    public func add(framework toAdd: String?) -> Self {
        mutatingAdd(framework: toAdd)
        return self
    }

    @discardableResult
    public func add(import toAdd: String) -> Self {
        mutatingAdd(import: toAdd)
        return self
    }

    @discardableResult
    public func add(imports toAdd: [String]) -> Self {
        mutatingAdd(imports: toAdd)
        return self
    }
}
