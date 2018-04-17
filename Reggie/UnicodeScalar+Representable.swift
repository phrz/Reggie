//
//  UnicodeScalar+Representable.swift
//  Reggie
//
//  Created by Paul Herz on 2018-04-17.
//  Copyright © 2018 Paul Herz. All rights reserved.
//

// We delegate a lot of Regular Expression representation responsibility
// from Characters to UnicodeScalars because Characters can consist of
// multiple scalars, requiring compound representation in the ASCII-constrained
// world of Regular Expression patterns.

import Foundation

extension UnicodeScalar {
	
	/// common functionality for CharacterFieldRepresentable and
	/// RegularExpressionRepresentable: a lot of rules for escaping
	/// characters are shared between the two, mainly certain ASCII control
	/// characters, and non-ASCII range Unicode characters. The only difference
	/// is a small set of special characters requiring escaping in character
	/// fields (e.g. `[A-Za-z]`) versus those requiring escaping in the rest
	/// of Regular Expression contexts.
	///
	private func escapeForRegex(
		withSpecialCharacters specialCharacters: Set<Character>
		) -> String? {
		
		// handling Unicode, non-ASCII codepoints
		guard self.isASCII else {
			// \x{HHHH} is limited to 16 bits (four hexadecimal digits)
			// so we break the scalar up
			return self.utf16.map {
				let hexCode = String($0, radix: 16, uppercase: false)
				return "\\x{\(hexCode)}"
			}.joined(separator: "")
		}
		
		// ASCII Unicode scalar encoding.
		switch self {
		case UnicodeScalar(0x00): // NUL
			return "\\0"
		case UnicodeScalar(0x07): // BEL (alarm)
			return "\\a"
		case UnicodeScalar(0x1b): // ESC (escape)
			return "\\e"
		case UnicodeScalar(0x0c): // form feed
			return "\\f"
		case UnicodeScalar(0x0a): // line feed
			return "\\n"
		case UnicodeScalar(0x0d): // carriage return
			return "\\r"
		case UnicodeScalar(0x09): // tab
			return "\\t"
		default:
			break
		}
		
		// return the character with or without a backslash escape
		return Character(self).prependingBackslashIf {
			specialCharacters.contains($0)
		}
	}
}

// one Character may have multiple Unicode scalars
extension UnicodeScalar: CharacterFieldRepresentable {
	public func characterFieldRepresentation() -> String? {
		return escapeForRegex(withSpecialCharacters: characterFieldSpecialCharacters)
	}
}

extension UnicodeScalar: RegularExpressionRepresentable {
	public func regularExpressionRepresentation() -> () -> String? {
		return {
			self.escapeForRegex(
				withSpecialCharacters: regularExpressionSpecialCharacters
			)
		}
	}
}
