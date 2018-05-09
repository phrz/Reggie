//
//  Pattern.swift
//  Reggie
//
//  Created by Paul Herz on 2018-05-03.
//  Copyright © 2018 Paul Herz. All rights reserved.
//

import Foundation

class Pattern {
	private let noOptions: NSRegularExpression.MatchingOptions = []
	
	// we need NSRange objects for the full range of a string
	private func fullRange(of string: String) -> NSRange {
		let nsString = NSString(string: string)
		return NSRange(location: 0, length: nsString.length)
	}
	
	public enum PatternError: Error {
		case cannotRetrieveRegularExpressionRepresentation
	}
	
	private let patternExpression: NSRegularExpression
	
	public init(_ regex: RegularExpressionRepresentable) throws {
		guard let ps = regex.regularExpressionRepresentation()() else {
			throw PatternError.cannotRetrieveRegularExpressionRepresentation
		}
		patternExpression = try NSRegularExpression(pattern: ps, options: [])
	}
	
	func matches(in input: String) -> [Substring] {
		let fullRange = NSRange(location: 0, length: input.count)
		let matches = patternExpression.matches(in: input, options: noOptions, range: fullRange)
		
		return matches.map { (textCheckingResult: NSTextCheckingResult) -> Substring in
			let r = textCheckingResult.range
			let i = { x in input.index(input.startIndex, offsetBy: x) }
			return input[i(r.lowerBound)...i(r.upperBound)]
		}
	}
	
	/// determines whether the regex completely matches the input, not a subset
	/// of it.
	func fullyMatches(_ input: String) -> Bool {
		let range = NSRange(location: 0, length: input.count)
		
		let matchRange: NSRange? = patternExpression.rangeOfFirstMatch(
			in: input,
			options: [],
			range: range
		)
		
		return matchRange == range
	}
	
	func replacingMatches(in input: String, with replacementPattern: String) -> String {
		let mutableString = NSMutableString(string: input)
		
		patternExpression.replaceMatches(
			in: mutableString,
			options: noOptions,
			range: fullRange(of: input),
			withTemplate: replacementPattern
		)
		
		return String(mutableString)
	}
	
	func strippingMatches(in input: String) -> String{
		return replacingMatches(in: input, with: "")
	}
}
