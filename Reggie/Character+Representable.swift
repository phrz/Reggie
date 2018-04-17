//
//  Character+Representable.swift
//  Reggie
//
//  Created by Paul Herz on 2018-04-12.
//  Copyright © 2018 Paul Herz. All rights reserved.
//

import Foundation

extension Character {
	/// given a predicate that evaluates the character, either returns a
	/// string containing the character, or the string containing the
	/// character escaped with a prefixed backslash.
	public func prependingBackslashIf(_ predicate: (Character) -> Bool) -> String {
		return predicate(self) ? "\\\(self)" : "\(self)"
	}
}

/*
individual characters can appear alongside character ranges in character
fields. This implementation escapes such characters.

PCRE requires some special escapes for non-printable and non-ASCII character
literals [CITE] https://www.pcre.org/current/doc/html/pcre2pattern.html

	\a        alarm, that is, the BEL character (hex 07)
	\cx       "control-x", where x is any printable ASCII character
	\e        escape (hex 1B)
	\f        form feed (hex 0C)
	\n        linefeed (hex 0A)
	\r        carriage return (hex 0D)
	\t        tab (hex 09)

This is one potential way to safely escape non-ASCII characters:

	\x{hhh..} character with hex code hhh.. (default mode)

*/

extension Character: CharacterFieldRepresentable {
	public func characterFieldRepresentation() -> String? {
		var result = ""
		for scalar in self.unicodeScalars {
			if let rep = scalar.characterFieldRepresentation() {
				result.append(rep)
			} else {
				let hexCode = String(scalar.value, radix: 16, uppercase: false)
				print("Warning: could not represent Unicode Scalar \(hexCode)")
				return nil
			}
		}
		return result
	}
}

/// individual characters can appear alongside strings, groups, etc.
/// in top-level regular expression contexts. This implementation escapes
/// such characters. The characters requiring escaping in regular expression
/// contexts is *different* than those requiring escaping in character fields.
extension Character: RegularExpressionRepresentable {
	public func regularExpressionRepresentation() -> () -> String? {
		return {
			let representations = self.unicodeScalars.map {
				$0.regularExpressionRepresentation()()
			}
			
			return allOrNothing(representations).map { $0.joined(separator: "") }
		}
	}
}
