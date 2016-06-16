//
//  PoetUtil.swift
//  SwiftPoet
//
//  Created by Kyle Dorman on 11/12/15.
//
//

import Foundation

public struct PoetUtil {
    private static let template = "^^^^"
    private static let regexPattern = "\\s|_|\\.|-|\\[|\\]"
    
    private static var spaceAndPunctuationRegex: RegularExpression? {
        do {
            return try RegularExpression(pattern: PoetUtil.regexPattern, options: .anchorsMatchLines)
        } catch {
            return nil
        }
    }

    internal static func addUnique<T: Equatable>(data: T, toList list: inout [T]) {
        if !list.contains(data) {
            list.append(data)
        }
    }

    internal static func stripSpaceAndPunctuation(name: String) -> [String] {
        guard let regex = spaceAndPunctuationRegex else {
            return [name]
        }

        return regex.stringByReplacingMatches(
            in: name, options: [],
            range: NSMakeRange(0, name.characters.count), withTemplate: template)
                .components(separatedBy: template)
                .map { capitalizeFirstChar(str: $0) }
    }

    // capitalize first letter without removing cammel case on other characters
    internal static func capitalizeFirstChar(str: String) -> String {
        return caseFirstChar(str: str) {
            return $0.uppercased().characters
        }
    }

    // lowercase first letter without removing cammel case on other characters
    internal static func lowercaseFirstChar(str: String) -> String {
        return caseFirstChar(str: str) {
            return $0.lowercased().characters
        }
    }

    private static func caseFirstChar(str: String, caseFn: (str: String) -> String.CharacterView) -> String {
        guard str.characters.count > 0 else {
            return str // This does happen!
        }

        var chars = str.characters
        let first = str.substring(to: chars.index(after: chars.startIndex))
        let range = chars.startIndex..<chars.index(after: chars.startIndex)
        chars.replaceSubrange(range, with: caseFn(str: first))
        return String(chars)
    }

    public static func fmap<A, B>(data: A?, function: (A) -> B?) -> B? {
        switch data {
        case .some(let x): return function(x)
        case .none: return .none
        }
    }

    public static func fmap<A, B>(data: A?, function: (A) -> B) -> B? {
        switch data {
        case .some(let x): return function(x)
        case .none: return .none
        }
    }
}