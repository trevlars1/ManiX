//
//  StringExtensions.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2024/12/25.
//  Copyright © 2024 Manic EMU. All rights reserved.
//
//
//  StringExtensions.swift
//  ZNear
//
//  Created by Aushuang Lee on 2021/2/22.
//

import Foundation



func hasPrefix(prefix: String) -> ((String) -> Bool) { { $0.hasPrefix(prefix) } }
func contains(string: String) -> ((String) -> Bool) { { $0.contains(string) } }

extension String {
    static func ~= (pattern: (String) -> Bool, value: String) -> Bool {
        pattern(value)
    }
}


extension String {
    var a: String { return self + "a" }
    var b: String { return self + "b" }
    var c: String { return self + "c" }
    var d: String { return self + "d" }
    var e: String { return self + "e" }
    var f: String { return self + "f" }
    var g: String { return self + "g" }
    var h: String { return self + "h" }
    var i: String { return self + "i" }
    var j: String { return self + "j" }
    var k: String { return self + "k" }
    var l: String { return self + "l" }
    var m: String { return self + "m" }
    var n: String { return self + "n" }
    var o: String { return self + "o" }
    var p: String { return self + "p" }
    var q: String { return self + "q" }
    var r: String { return self + "r" }
    var s: String { return self + "s" }
    var t: String { return self + "t" }
    var u: String { return self + "u" }
    var v: String { return self + "v" }
    var w: String { return self + "w" }
    var x: String { return self + "x" }
    var y: String { return self + "y" }
    var z: String { return self + "z" }
    
    var A: String { return self + "A" }
    var B: String { return self + "B" }
    var C: String { return self + "C" }
    var D: String { return self + "D" }
    var E: String { return self + "E" }
    var F: String { return self + "F" }
    var G: String { return self + "G" }
    var H: String { return self + "H" }
    var I: String { return self + "I" }
    var J: String { return self + "J" }
    var K: String { return self + "K" }
    var L: String { return self + "L" }
    var M: String { return self + "M" }
    var N: String { return self + "N" }
    var O: String { return self + "O" }
    var P: String { return self + "P" }
    var Q: String { return self + "Q" }
    var R: String { return self + "R" }
    var S: String { return self + "S" }
    var T: String { return self + "T" }
    var U: String { return self + "U" }
    var V: String { return self + "V" }
    var W: String { return self + "W" }
    var X: String { return self + "X" }
    var Y: String { return self + "Y" }
    var Z: String { return self + "Z" }
    
    var _1 : String { get { return self + "1" } }
    var _2 : String { get { return self + "2" } }
    var _3 : String { get { return self + "3" } }
    var _4 : String { get { return self + "4" } }
    var _5 : String { get { return self + "5" } }
    var _6 : String { get { return self + "6" } }
    var _7 : String { get { return self + "7" } }
    var _8 : String { get { return self + "8" } }
    var _9 : String { get { return self + "9" } }
    var _0 : String { get { return self + "0" } }
}

extension String {
    var validateAndExtractURLComponents: (scheme: String?, host: String, port: Int?, path: String?)? {
        let trimmedInput = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let pattern = #"^(([a-zA-Z][a-zA-Z0-9+.-]*)://)?((?:$$([0-9a-fA-F:]+)$$|([^/?#:]+)))(?::(\d+))?(?:/([^?#]*))?(?:[?#].*)?$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        
        let range = NSRange(trimmedInput.startIndex..., in: trimmedInput)
        guard let match = regex.firstMatch(in: trimmedInput, options: [], range: range) else {
            return nil
        }
        
        
        let schemeRange = Range(match.range(at: 2), in: trimmedInput)
        let scheme = schemeRange.flatMap { String(trimmedInput[$0]) }
        
        
        var host: String?
        var isIPv6 = false
        if let ipv6Range = Range(match.range(at: 4), in: trimmedInput), !ipv6Range.isEmpty {
            host = String(trimmedInput[ipv6Range]) 
            isIPv6 = true
        } else if let normalHostRange = Range(match.range(at: 5), in: trimmedInput), !normalHostRange.isEmpty {
            host = String(trimmedInput[normalHostRange]) 
        }
        
        guard let validHost = host, !validHost.isEmpty else {
            return nil
        }
        
        
        let adjustedHost = isIPv6 ? validHost : validHost
        let isDomainValid = NSPredicate(format: "SELF MATCHES %@", #"^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$"#).evaluate(with: adjustedHost)
        let isIPv4Valid = NSPredicate(format: "SELF MATCHES %@", #"^(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?)$"#).evaluate(with: adjustedHost)
        let isIPv6Valid = isIPv6 && NSPredicate(format: "SELF MATCHES %@", #"^[0-9a-fA-F:]+$"#).evaluate(with: adjustedHost)
        
        guard isIPv6Valid || isIPv4Valid || isDomainValid else {
            return nil
        }
        
        
        let portString = Range(match.range(at: 6), in: trimmedInput).flatMap { String(trimmedInput[$0]) }
        let port = portString.flatMap { Int($0) }.flatMap { (1...65535).contains($0) ? $0 : nil }
        
        
        let path = Range(match.range(at: 7), in: trimmedInput).flatMap {
            let str = String(trimmedInput[$0])
            return str.isEmpty ? nil : str
        }
        
        return (scheme, adjustedHost, port, path)
    }
    
    func calculateWidth(font: UIFont, height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: height
        )
        let boundingBox = self.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil
        )
        return ceil(boundingBox.width)
    }
    
    static func errorMessage(from errors: [Error]) -> String {
        return errors.reduce("") { partialResult, error in
            if partialResult == "" {
                return error.localizedDescription
            } else {
                return partialResult + "\n" + error.localizedDescription
            }
        }
    }
    
    static func successMessage(from names: [String]) -> String {
        return names.reduce("") { partialResult, name in
            if partialResult == "" {
                return name
            } else {
                return partialResult + "\n" + name
            }
        }
    }
}

extension String {
    
    @discardableResult
    
    
    
    
    
    func replace(pattern: String, with text: String) -> String {
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let result = regex?.stringByReplacingMatches(in: self, range: NSMakeRange(0, self.count), withTemplate: text)
        return result ?? self
    }
    
    func match(pattern: String) -> Bool {
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        guard let regex = regex else { return false }
        let resultArray = regex.matches(in: self, range: NSRange(location: 0, length: self.count))
        guard resultArray.count == 1, let result = resultArray.first else {
            return false
        }
        return self.count == result.range.length
    }
}

extension String {
    var queryDict: [String: String?]? {
        guard let urlComponents = URLComponents(string: self) else {
            return nil
        }
        var querys: [String: String] = [:]
        if let queryItems = urlComponents.queryItems {
            for (_, item) in queryItems.enumerated() {
                querys[item.name] = item.value
            }
        }
        return querys.keys.count > 0 ? querys : nil
    }
}
