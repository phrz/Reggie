//
//  CharacterType.swift
//  Reggie
//
//  Created by Paul Herz on 2018-04-12.
//  Copyright © 2018 Paul Herz. All rights reserved.
//

import Foundation

/*
https://www.pcre.org/current/doc/html/pcre2syntax.html#SEC4
as of 2018-04-12:

.          any character except newline; in dotall mode, any character whatsoever
\C         one code unit, even in UTF mode (best avoided)
\d         a decimal digit
\D         a character that is not a decimal digit
\h         a horizontal white space character
\H         a character that is not a horizontal white space character
\N         a character that is not a newline
\p{xx}     a character with the xx property
\P{xx}     a character without the xx property
\R         a newline sequence
\s         a white space character
\S         a character that is not a white space character
\v         a vertical white space character
\V         a character that is not a vertical white space character
\w         a "word" character
\W         a "non-word" character
\X         a Unicode extended grapheme cluster

\C is dangerous because it may leave the current matching point in the middle
of a UTF-8 or UTF-16 character. The application can lock out the use of \C by
setting the PCRE2_NEVER_BACKSLASH_C option. It is also possible to build PCRE2
with the use of \C permanently disabled.

By default, \d, \s, and \w match only ASCII characters, even in UTF-8 mode or
in the 16-bit and 32-bit libraries. However, if locale-specific matching is
happening, \s and \w may also match characters with code points in the range
128-255. If the PCRE2_UCP option is set, the behaviour of these escape
sequences is changed to use Unicode properties and they match many more
characters.
*/

public struct CharacterType {
	/// will match newline in dotall mode.
	static public let anyCharacter = pure(".")
	
	static public let decimal = pure("\\d")
	static public let notDecimal = pure("\\D")
	
	static public let horizontalWhitespace = pure("\\h")
	static public let notHorizontalWhitespace = pure("\\H")
	
	/// will never match newline, even in dotall mode.
	static public let notNewLine = pure("\\N")
	
	/// any sequence resulting in a new line.
	static public let newLine = pure("\\R")
	
	static public let whiteSpace = pure("\\s")
	static public let notWhiteSpace = pure("\\S")
	
	static public let verticalWhiteSpace = pure("\\v")
	static public let notVerticalWhiteSpace = pure("\\V")

	/// will match only ASCII alphabet characters unless in Unicode mode.
	static public let wordCharacter = pure("\\w")
	
	/// will only exclude ASCII alphabet characters unless in Unicode mode.
	static public let notWordCharacter = pure("\\W")
	
	static public let unicodeExtendedGraphemeCluster = pure("\\X")
}
