//
//  RegularExpressionRepresentable.swift
//  Reggie
//
//  Created by Paul Herz on 2018-04-12.
//  Copyright © 2018 Paul Herz. All rights reserved.
//

import Foundation

/// a set of characters which cannot be directly represented in the
/// general regex context (all sequences, aka everywhere outside of `[]` character
/// fields), but instead must be represented escaped by a backslash.
///
/// the right square bracket is not featured here because it is treated as a
/// normal character in all contexts except when inside of a character field
/// (where it is treated as the character field terminator, to match the `[`).
public let regularExpressionSpecialCharacters = Set<Character>(arrayLiteral:
	".","^","$","*","+","?","(",")","[","{","\\","|"
)

/// Any object that can be translated losslessly into a representation
/// that is valid within a Regular Expression sequence, i.e.
/// anything *not* between the square brackets (`[]`).
///
/// This includes object representations of all regex features like
/// character fields (`[A-Za-z0-9]`), groups (`(a|b|c)`), and sequence literals
/// (`banana`). At the top level, we use this protocol to translate them to
/// strings to actually generate the regular expression pattern. At lower levels,
/// these objects may either:
///
/// - naïvely use this protocol to translate their "child" elements to strings,
/// as capture group implementations may choose to do, or
/// - use special cases where the types of child elements are important to
/// apply special rules where basic string translation and concatenation would
/// result in invalid/suboptimal regular expression patterns.
public protocol RegularExpressionRepresentable {
	/// this may sometimes be `nil` in cases where there simply is no
	/// representation of the object in regex context, despite the
	/// class in general being representable, or when there is specifically
	/// no *lossless* representation.
	func regularExpressionRepresentation() -> () -> String?
}
