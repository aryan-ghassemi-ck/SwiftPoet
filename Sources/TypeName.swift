//
//  TypeName.swift
//  SwiftPoet
//
//  Created by Kyle Dorman on 11/10/15.
//
//

import Foundation

open class TypeName: Importable {
    open let keyword: String
    open let attributes: [String]
    open let innerTypes: [TypeName]

    // for arrays and dictionaries
    open var leftInnerType: TypeName? {
        return innerTypes.first
    }

    // for dictionaries
    open var rightInnerType: TypeName? {
        guard innerTypes.count > 1 else { return nil }
        return innerTypes[1]
    }
    open let optional: Bool
    open var imports: Set<String>

    public convenience init<T: StringProtocol>(keyword: T, attributes: [String] = [], optional: Bool = false, imports: [String]? = nil)
    {
        self.init(keyword: String(keyword), attributes: attributes, optional: optional, imports: imports)
    }

    public init(keyword: String, attributes: [String] = [], optional: Bool = false, imports: [String]? = nil) {
        let trimmedKeyWord = keyword.trimmingCharacters(in: .whitespaces)
        let nonOptionalKeyword: String
        let stringOptional: Bool
        if TypeName.isOptionalClosure(keyword) {
            let chars = trimmedKeyWord
            let endIndex = chars.index(chars.endIndex, offsetBy: -2)
            let startIndex = chars.index(after: chars.startIndex)
            nonOptionalKeyword = String(trimmedKeyWord[startIndex..<endIndex])
            stringOptional = true
        } else if TypeName.isOptional(keyword) {
            let chars = trimmedKeyWord
            let endIndex = chars.index(before: chars.endIndex)
            nonOptionalKeyword = String(trimmedKeyWord[chars.startIndex..<endIndex])
            stringOptional = true
        } else {
            nonOptionalKeyword = trimmedKeyWord
            stringOptional = false
        }
        self.attributes = attributes

        if TypeName.isClosure(nonOptionalKeyword) {
            let chars = nonOptionalKeyword
            // find ->
            let returnRange = nonOptionalKeyword.range(of: "->")!
            // Find function inputs
            let endIndex = nonOptionalKeyword.index(returnRange.lowerBound, offsetBy:-2)
            let inputs = nonOptionalKeyword[chars.index(after: chars.startIndex)..<endIndex]
            // Find return type
            let returnType = nonOptionalKeyword[chars.index(after: returnRange.upperBound)..<chars.endIndex]

            let leftInnerTypes = inputs.components(separatedBy: ",").map {
                TypeName(keyword: $0)
            }

            self.innerTypes = leftInnerTypes + [TypeName(keyword: returnType)]
            self.keyword = "Closure"

        } else if TypeName.containsGenerics(nonOptionalKeyword) {
            let chars = nonOptionalKeyword
            // find first `<`
            let leftIndex = nonOptionalKeyword.range(of: "<")!.lowerBound
            // find last `>`
            let reverse = String(nonOptionalKeyword.reversed())
            let endIndex = reverse.range(of: ">")!.upperBound
            let distance = reverse.distance(from:reverse.startIndex, to:endIndex)
            let rightIndex = nonOptionalKeyword.index(nonOptionalKeyword.endIndex, offsetBy: -distance)

            // find keyword before generics
            let keywordStrRange = nonOptionalKeyword.startIndex..<leftIndex
            let keywordStr = nonOptionalKeyword[keywordStrRange]

            // find contents of generic brackets
            // Note: This implmentation won't support multiple generics with multiple generics
            // i.e. Dictionary<String,Dictionary<String,String>>
            let genericsRange = chars.index(after: leftIndex)..<rightIndex
            let generics = nonOptionalKeyword[genericsRange]

            self.innerTypes = generics.components(separatedBy: ",").map {
                TypeName(keyword: $0)
            }
            self.keyword = keywordStr.cleaned(.typeName)

        } else if TypeName.isDictionary(nonOptionalKeyword) {
            let chars = nonOptionalKeyword
            let endIndex = chars.index(before: chars.endIndex)
            let splitIndex = nonOptionalKeyword.range(of: ":")!.lowerBound

            self.innerTypes = [
                TypeName(keyword: nonOptionalKeyword[chars.index(after: chars.startIndex)..<splitIndex]),
                TypeName(keyword: nonOptionalKeyword[chars.index(after: splitIndex)..<endIndex])
            ]
            self.keyword = "Dictionary".cleaned(.typeName)
            
        } else if TypeName.isArray(nonOptionalKeyword) {
            let chars = nonOptionalKeyword
            let endIndex = chars.index(before: chars.endIndex)
            let range = chars.index(after: chars.startIndex)..<endIndex

            self.innerTypes = [TypeName(keyword: nonOptionalKeyword[range])]
            self.keyword = "Array".cleaned(.typeName)

        } else {
            self.innerTypes = []
            self.keyword = nonOptionalKeyword.cleaned(.typeName)
        }

        self.optional = optional || stringOptional
        self.imports = imports?.reduce(Set<String>()) { (dict, s) in var retVal = dict; retVal.insert(s); return retVal; } ?? Set<String>()
    }

    open func collectImports() -> Set<String> {
        var collectedImports = Set(imports)
        leftInnerType?.collectImports().forEach { collectedImports.insert($0) }
        rightInnerType?.collectImports().forEach { collectedImports.insert($0) }
        return collectedImports
    }

    internal static func containsGenerics(_ keyword: String) -> Bool {
        return test(pattern: "^.*<.+>\\??$", for: keyword)
    }

    internal static func isArray(_ keyword: String) -> Bool {
        return test(pattern: "^\\[.+\\]\\??$", for: keyword)
    }

    internal static func isDictionary(_ keyword: String) -> Bool {
        return test(pattern: "^\\[.+:.+\\]\\??$", for: keyword)
    }

    internal static func isOptional(_ keyword: String) -> Bool {
        return test(pattern: "^.+\\?$", for: keyword)
    }

    internal static func isClosure(_ keyword: String) -> Bool {
        return test(pattern: "^\\(.+\\)\\s*->\\s*.+$", for: keyword)
    }

    internal static func isOptionalClosure(_ keyword: String) -> Bool {
        return test(pattern: "^[((].+\\)\\s*->\\s*.+\\)\\?$", for: keyword)
    }

    private static func test(pattern: String, for keyword: String) -> Bool {
        var match: NSRegularExpression?
        let range = NSRange(location: 0, length: keyword.count)

        do {
            match = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        } catch {
            match = nil // this should never happen
        }

        return match?.numberOfMatches(in: keyword, options: .anchored, range: range) == 1
    }
}

extension TypeName: Equatable {}

public func ==(lhs: TypeName, rhs: TypeName) -> Bool {
    return lhs.optional == rhs.optional && lhs.keyword == rhs.keyword && lhs.attributes == rhs.attributes
}

extension TypeName: Hashable {
    public var hashValue: Int {
        return toString().hashValue
    }
}

extension TypeName: Emitter {
    public func emit(to writer: CodeWriter) -> CodeWriter {
        return writer.emit(type: .literal, data: literalValue())
    }

    public func toString() -> String {
        let cw = self.emit(to: CodeWriter())
        return cw.out
    }
}

extension TypeName: Literal {
    public func literalValue() -> String {
        var attrStr = ""
        if !attributes.isEmpty {
            attrStr = attributes.map{ "@\($0)" }.joined(separator: " ") + " "
        }

        let optionalChar = optional ? "?" : ""
        if keyword == "Closure" {
            let functionParams = innerTypes[0..<innerTypes.count - 1].map { $0.literalValue() }.joined(separator: ", ")
            let function = "(\(functionParams)) -> \(innerTypes.last?.literalValue() ?? "Void")"

            if optional {
                return "(\(function))?"
            } else {
                return function
            }
        }
        if innerTypes.isEmpty {
            return attrStr + keyword + optionalChar
        } else {
            return attrStr + keyword + "<" + innerTypes.map { $0.literalValue() }.joined(separator: ",") + ">" + optionalChar
        }
    }
}

extension TypeName {
    public static let BooleanType = TypeName(keyword: "Bool")
    public static let IntegerType = TypeName(keyword: "Int")
    public static let DoubleType = TypeName(keyword: "Double")
    public static let AnyType = TypeName(keyword: "Any")
    public static let StringType = TypeName(keyword: "String")
    public static let JSONDictionary = TypeName(keyword: "[String: Any]")

    // Optional
    public static let BooleanOptional = TypeName(keyword: "Bool", optional: true)
    public static let IntegerOptional = TypeName(keyword: "Int", optional: true)
    public static let DoubleOptional = TypeName(keyword: "Double", optional: true)
    public static let AnyTypeOptional = TypeName(keyword: "Any", optional: true)
    public static let StringOptional = TypeName(keyword: "String", optional: true)
}
