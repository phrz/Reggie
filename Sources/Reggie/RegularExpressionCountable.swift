//
//  RegularExpressionCountable.swift
//  Reggie
//
//  Created by Paul Herz on 2018-04-17.
//  Copyright © 2018 Paul Herz. All rights reserved.
//

import Foundation

/// This protocol allows us to customize how we add Regular Expression
/// quantifiers like `?`, `*`, `+`, `{3}`, `{1,5}`.

public protocol RegularExpressionCountable: RegularExpressionRepresentable {
	/// represents the `?` quantifier.
	func maybe() -> RegularExpressionRepresentable

	/// represents the `*` quantifier.
	func zeroOrMore() -> RegularExpressionRepresentable
	
	/// represents the `+` quantifier.
	func oneOrMore() -> RegularExpressionRepresentable
	
	/// represents the `{#}` quantifier.
	func repeating(withCount count: Int) -> RegularExpressionRepresentable
	
	/// represents the `{#,#}` quantifier.
	func repeating(between range: ClosedRange<Int>) -> RegularExpressionRepresentable
}

internal struct CountableSuffixes {
	static let maybe = "?"
	static let zeroOrMore = "*"
	static let oneOrMore = "+"
	static func repeating(withCount count: Int) -> String {
		return "{\(count)}"
	}
	static func repeating(between range: ClosedRange<Int>) -> String {
		return "{\(range.lowerBound),\(range.upperBound)}"
	}
}

// default implementation that works for Groups, CharacterFields
extension RegularExpressionCountable {
	public func maybe() -> RegularExpressionRepresentable {
		return sequence([self, pure(CountableSuffixes.maybe)])
	}
	
	public func zeroOrMore() -> RegularExpressionRepresentable {
		return sequence([self, pure(CountableSuffixes.zeroOrMore)])
	}
	
	public func oneOrMore() -> RegularExpressionRepresentable {
		return sequence([self, pure(CountableSuffixes.oneOrMore)])
	}
	
	public func repeating(withCount count: Int) -> RegularExpressionRepresentable {
		return sequence([self, pure(CountableSuffixes.repeating(withCount: count))])
	}
	
	public func repeating(between range: ClosedRange<Int>) -> RegularExpressionRepresentable {
		return sequence([self, pure(CountableSuffixes.repeating(between: range))])
	}
}

extension Group: RegularExpressionCountable {}
extension CharacterField: RegularExpressionCountable {}

// allows RegularExpressionSequence to be countable
extension Array: RegularExpressionCountable where Array.Element == RegularExpressionRepresentable {
	
	public func maybe() -> RegularExpressionRepresentable {
		return sequence([nonCapturingGroup(self), pure(CountableSuffixes.maybe)])
	}
	
	public func zeroOrMore() -> RegularExpressionRepresentable {
		return sequence([nonCapturingGroup(self), pure(CountableSuffixes.zeroOrMore)])
	}
	
	public func oneOrMore() -> RegularExpressionRepresentable {
		return sequence([nonCapturingGroup(self), pure(CountableSuffixes.oneOrMore)])
	}
	
	public func repeating(withCount count: Int) -> RegularExpressionRepresentable {
		return sequence([nonCapturingGroup(self), pure(CountableSuffixes.repeating(withCount: count))])
	}
	
	public func repeating(between range: ClosedRange<Int>) -> RegularExpressionRepresentable {
		return sequence([nonCapturingGroup(self), pure(CountableSuffixes.repeating(between: range))])
	}
}
