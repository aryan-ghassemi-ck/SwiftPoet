//
//  CodeWriter.swift
//  SwiftPoet
//
//  Created by Kyle Dorman on 11/10/15.
//
//

import Foundation

public typealias Appendable = Substring

open class CodeWriter: NSObject {
    fileprivate var _out: Appendable
    open var out: String {
        return String(_out)
    }

    fileprivate var indentLevel: Int

    public init(out: Appendable = Appendable(""), indentLevel: Int = 0) {
        self._out = out
        self.indentLevel = indentLevel
    }
}

// MARK: Indentation
public extension CodeWriter
{
    @discardableResult
    func indent()
        -> CodeWriter
    {
        return indent(1)
    }

    @discardableResult
    func indent(_ levels: Int)
        -> CodeWriter
    {
        return indentLevels(levels)
    }

    @discardableResult
    func unindent()
        -> CodeWriter
    {
        return unindent(1)
    }

    @discardableResult
    func unindent(_ levels: Int)
        -> CodeWriter
    {
        return indentLevels(-levels)
    }

    @discardableResult
    fileprivate func indentLevels(_ levels: Int)
        -> CodeWriter
    {
        indentLevel = max(indentLevel + levels, 0)
        return self
    }
}

extension CodeWriter {
    //
    //  FileName.swift
    //  Framework
    //
    //  Contains:
    //  PoetSpecType PoetSpecName
    //  PoetSpecType2 PoetSpecName2
    //
    //  Created by SwiftPoet on MM/DD/YYYY
    //
    //
    public func emitFileHeader(fileName: String?, framework: String?, generatorInfo: String?, addGenerationDate: Bool = true, specs: [PoetSpecType]) {
        let specStr: [String] = specs.map { spec in
            return headerLine(withString: "\(spec.construct.stringValue) \(spec.name)")
        }

        var header: [String] = [headerLine()]
        if let fileName = fileName {
            header.append(headerLine(withString: "\(fileName).swift"))
        }
        if let framework = framework {
            header.append(headerLine(withString: framework.cleaned(.typeName)))
        }
        header.append(headerLine())

        if let generatorInfo = generatorInfo {
            header.append(headerLine(withString: generatorInfo))
            header.append(headerLine())
        }

        if !specStr.isEmpty {
            header.append(headerLine(withString: "Contains:"))
            header.append(contentsOf: specStr)
            header.append(headerLine())
        }

        let generatedByAtLine = generatedBy() + (addGenerationDate ? " " + generatedAt() : "")
        header.append(headerLine(withString: generatedByAtLine))
        header.append(headerLine())

        _out.append(contentsOf: header.joined(separator: "\n"))
        emitNewLine()
        emitNewLine()
    }

    fileprivate func headerLine(withString str: String? = nil) -> String {
        guard let str = str else {
            return "//"
        }
        return "//  \(str)"
    }

    fileprivate func createdAt() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: Date())
    }

    fileprivate func generatedAt() -> String {
        return "on \(createdAt())"
    }

    fileprivate func generatedBy() -> String {
        return "Generated by SwiftPoet"
    }

    @discardableResult
    public func emit(imports toEmit: Set<String>)
        -> CodeWriter
    {
        if (toEmit.count > 0) {
            let importString = toEmit.sorted().joined(separator: "\nimport ")
            _out.append(contentsOf: "import ")
            _out.append(contentsOf: importString)
            _out.append(contentsOf: "\n\n")
        }
        return self
    }

    @discardableResult
    public func emit(documentationFor type: TypeSpec)
        -> CodeWriter
    {
        if let docs = type.description {
            var specDoc = "" as String

            let firstline = "/**\n".byIndenting(level: indentLevel)
            let lastline = "*/\n".byIndenting(level: indentLevel)
            let indentedDocs = "\(docs)\n".byIndenting(level: indentLevel + 1)

            specDoc.append(firstline)
            specDoc.append(indentedDocs)
            specDoc.append(lastline)
            _out.append(contentsOf: specDoc)
        }
        return self
    }

    @discardableResult
    public func emit(documentationFor field: FieldSpec)
        -> CodeWriter
    {
        if let docs = field.description {
            let comment = "// \(docs)\n".byIndenting(level: indentLevel)
            _out.append(contentsOf: comment)
        }
        return self
    }

    @discardableResult
    public func emit(documentationFor method: MethodSpec)
        -> CodeWriter
    {
        guard method.description != nil || !method.parameters.isEmpty else {
            return self
        }

        var specDoc = "" as String

        let firstline = "/**\n".byIndenting(level: indentLevel)
        let lastline = "*/\n".byIndenting(level: indentLevel)
        let indentedDocs = PoetUtil.fmap(method.description) {
            "\($0)\n".byIndenting(level: self.indentLevel + 1)
        }

        specDoc.append(firstline)
        if indentedDocs != nil {
            specDoc.append(indentedDocs!)
        }
    
        if method.parameters.count > 0 {
            if method.description != nil {
                specDoc.append("\n")
            }
            specDoc.append("- Parameters:".byIndenting(level: indentLevel + 1))
        }
        
        method.parameters.forEach { p in
            specDoc.append("\n\n")

            var paramDoc = "  - \(p.name)"
            if let desc = p.description {
                paramDoc.append(": \(desc)")
            }
            specDoc.append(paramDoc.byIndenting(level: indentLevel + 1))
        }
        specDoc.append("\n")
        specDoc.append(lastline)
        _out.append(contentsOf: specDoc)
        return self
    }

    @discardableResult
    public func emit(modifiers toEmit: Set<Modifier>)
        -> CodeWriter
    {
        guard !toEmit.isEmpty else {
            _out.append(contentsOf: "".byIndenting(level: indentLevel))
            return self
        }

        let modListStr = toEmit.sortedByGuidelines().map { m in
            return m.rawString
        }.joined(separator: " ") + " "

        _out.append(contentsOf: modListStr.byIndenting(level: indentLevel))

        return self
    }

    @discardableResult
    public func emit(codeBlock toEmit: CodeBlock, withIndentation indent: Bool = false)
        -> CodeWriter
    {
        if indent {
            emitIndentation()
        }

        var first = true
        toEmit.emittableObjects.forEach { either in
            switch either {
            case .right(let codeBlock):
                self.emitNewLine()
                self.emit(codeBlock: codeBlock, withIndentation: true)

            case .left(let emitObject):
                switch emitObject.type {
                case .literal:
                    self.emit(literal: emitObject.data, trimString: first || emitObject.trimString)

                case .beginStatement:
                    self.emitBeginStatement()

                case .endStatement:
                    self.emitEndStatement()

                case .newLine:
                    self.emitNewLine()

                case .nextLine:
                    self.emitNewLine(preservingIndentation: true)

                case .increaseIndentation:
                    self.indent()

                case .decreaseIndentation:
                    self.unindent()

                case .codeLine:
                    self.emitNewLine()
                    self.emit(literal: emitObject.data as! Literal, withIndentation: true)

                case .emitter:
                    self.emit(using: emitObject.data as! Emitter, first: first)
                }
                first = false
            }
        }
        return self
    }

    @discardableResult
    public func emit(type: EmitType, data: Any? = nil) -> CodeWriter {
        let cbBuilder = CodeBlock.builder()
        cbBuilder.add(type: type, data: data)
        return self.emit(codeBlock: cbBuilder.build())
    }

    @discardableResult
    public func emit(literal value: Any?, withIndentation indent: Bool = false)
         -> CodeWriter
    {
        if indent {
            emitIndentation()
        }
        emit(literal: value, trimString: true)
        return self
    }

    fileprivate func emit(literal value: Any?, trimString: Bool = false) {
        if let _ = value as? TypeSpec {
            // Dunno
        } else if let literalType = value as? Literal {
            var lv = literalType.literalValue()
            if !trimString { lv.insert(" ", at: lv.startIndex) }
            _out.append(contentsOf: lv)
        } else if let str = value as? String {
            _out.append(contentsOf: str)
        }
    }

    fileprivate func emit(using emitter: Any?, first: Bool = true)
    {
        if let emitter = emitter as? Emitter {
            if !first { _out.append(" ") }
            emitter.emit(to: self)
        }
    }

    @discardableResult
    public func emit(superType: TypeName?, protocols: [TypeName]?)
        -> CodeWriter
    {
        var inheritanceValues: [String?] = [superType?.literalValue()]
        if let protocols = protocols {
            inheritanceValues.append(contentsOf: protocols.map{ $0.literalValue() })
        }

        let stringValues = inheritanceValues.compactMap{$0}

        if stringValues.count > 0 {
            _out.append(contentsOf: ": ")
            _out.append(contentsOf: stringValues.joined(separator: ", "))
        }

        return self
    }

    fileprivate func emitBeginStatement()
    {
        let begin = " {"
        _out.append(contentsOf: begin)
        indent()
    }

    fileprivate func emitEndStatement()
    {
        let newline = "\n"
        unindent()
        let endBracket = "}".byIndenting(level: indentLevel)
        let end = newline + endBracket
        _out.append(contentsOf: end)
    }

    @discardableResult
    public func emitNewLine(preservingIndentation: Bool = false)
        -> CodeWriter
    {
        _out.append("\n")
        if preservingIndentation {
            emitIndentation()
        }
        return self
    }

    fileprivate func emitIndentation()
    {
        _out.append(contentsOf: "".byIndenting(level: indentLevel))
    }

    @discardableResult
    public func emit(specs toEmit: [Emitter])
        -> CodeWriter
    {
        _out.append(contentsOf: (toEmit.map { spec in
            spec.toString()
        }).joined(separator: "\n\n"))
        emitNewLine()
        return self
    }
}

extension String {
    fileprivate func byIndenting(level indentationLevel: Int)
        -> String
    {
        let indentSpacing = "    "

        var indented = ""
        indentationLevel.times {
            indented += indentSpacing
        }
        return indented + self
    }
}

extension Int {
    fileprivate func times(_ fn: () -> Void) {
        for _ in 0..<self {
            fn()
        }
    }
}

