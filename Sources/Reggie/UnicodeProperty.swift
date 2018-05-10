//
//  UnicodeProperty.swift
//  Reggie
//
//  Created by Paul Herz on 2018-04-17.
//  Copyright © 2018 Paul Herz. All rights reserved.
//

import Foundation

/// based on http://www.regular-expressions.info/unicode.html#prop :
/// Unicode codepoint properties usable with the \p{} or \P{} tags.
public enum UnicodeProperty: String {
	/// any kind of letter from any language.
	case letter = "L"
	
	/// a lowercase letter that has an uppercase variant.
	case lowercaseLetter = "Ll"
	
	/// an uppercase letter that has a lowercase variant.
	case uppercaseLetter = "Lu"
	
	/// a letter that appears at the start of a word when only
	/// the first letter of the word is capitalized.
	case titlecaseLetter = "Lt"
	
	/// a letter that exists in lowercase and uppercase variants
	/// (a union of uppercase, lowercase, and titlecase letter conditions).
	case casedLetter = "L&"
	
	/// a special character that is used like a letter.
	case modifierLetter = "Lm"
	
	/// a letter or ideograph that does not have lowercase and uppercase variants.
	case otherLetter = "Lo"
	
	/// a character intended to be combined with another character
	/// (e.g. accents, umlauts, enclosing boxes, etc.).
	case mark = "M"
	
	/// a character intended to be combined with another character without
	/// taking up extra space (e.g. accents, umlauts, etc.).
	case nonSpacingMark = "Mn"
	
	/// a character intended to be combined with another character
	/// that takes up extra space (vowel signs in many Eastern languages).
	case spacingMark = "Mc"
	
	/// a character that encloses the character is is combined with
	/// (circle, square, keycap, etc.).
	case enclosingMark = "Me"
	
	/// any kind of whitespace or invisible separator.
	case separator = "Z"
	
	public func matching() -> RegularExpressionRepresentable {
		// \p{xx} - a character with the xx property
		return PureRegularExpressionRepresentation(literal: "\\p{\(self.rawValue)}")
	}
	
	public func notMatching() -> RegularExpressionRepresentable {
		// \P{xx} - a character without the xx property
		return PureRegularExpressionRepresentation(literal: "\\P{\(self.rawValue)}")
	}
}
