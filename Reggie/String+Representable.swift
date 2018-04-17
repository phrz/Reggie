//
//  String+Representable.swift
//  Reggie
//
//  Created by Paul Herz on 2018-04-12.
//  Copyright © 2018 Paul Herz. All rights reserved.
//

import Foundation

/// to be clear, you can't have true Strings (sequences of characters) in
/// regex character fields, which are unordered sets of characters to match to.
/// This gets around some situations where `Character`s (which do not have their
/// own literal in Swift) are not interpreted as `Character`s but as single-character
/// `String`s.
extension String: CharacterFieldRepresentable {
	public func characterFieldRepresentation() -> String? {
		guard self.count == 1, let char = self.first else {
			return nil
		}
		return char.characterFieldRepresentation()
	}
}

/// this is unlike the implementation of `CharacterFieldRepresentable` above:
/// `String` in a regex context is an ordered sequence of literal characters
/// that the regex is supposed to find/match.
//extension String: RegularExpressionRepresentable {
//	public func regularExpressionRepresentation() -> () -> String? {
//		return {
//			let maybeRepresentations = self.map { $0.regularExpressionRepresentation()() }
//			if let representations = allOrNothing(maybeRepresentations) {
//				return representations.joined(separator: "")
//			} else {
//				return nil
//			}
//		}
//	}
//}
