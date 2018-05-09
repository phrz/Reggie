//
//  CharacterFieldRepresentable.swift
//  Reggie
//
//  Created by Paul Herz on 2018-04-12.
//  Copyright © 2018 Paul Herz. All rights reserved.
//

import Foundation

/// a set of characters which cannot be directly represented in regex
/// character fields, but instead must be backslash-escaped.
/// the PCRE standard states that opening square braces "[" don't need to be
/// escaped in character fields, but NSRegularExpression fails to compile it
/// if you do not escape it.
public let characterFieldSpecialCharacters = Set<Character>(arrayLiteral: "^","-","]","\\","[")

/// Any object that can be translated losslessly into a representation
/// that is valid within a Regular Expression character field, i.e.
/// the stuff between the square brackets (`[]`).
///
/// This primarily includes single characters (the `Character` object)
/// or `ClosedRange<Character>` objects representing ranges of characters
/// (e.g. `"A"..."Z"` in Swift, which becomes `[A-Z]` in regex).
///
/// the implementation of this protocol on Character takes care of escaping
/// the right characters with backslashes. Importantly, the characters that
/// need to be escaped in a character field are *different* than the characters
/// that need to be escaped outside of character fields.
public protocol CharacterFieldRepresentable {
	/// this may sometimes be `nil` in cases where there simply is no
	/// representation of the object within a character field, despite the
	/// class in general being representable, or when there is specifically
	/// no *lossless* representation.
	///
	/// For example, Swift (currently) has no `Character` literal. A single
	/// character `String` literal can be cast as a `Character` when expected.
	/// but we implement this protocol on `String` to handle some edge cases
	/// where `Swift` fails to interpret a `String` literal as a `Character`.
	/// This implementation returns `nil` when the String is not a single character.
	func characterFieldRepresentation() -> String?
}
