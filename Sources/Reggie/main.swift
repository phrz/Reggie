//
//  main.swift
//  Reggie
//
//  Created by Paul Herz on 2018-04-12.
//  Copyright © 2018 Paul Herz. All rights reserved.
//

import Foundation

let fancyApostrophe = char("’")

// ASCII sucks!
// let alphabet = chars("A"..."Z", "a"..."z")

let unicodeLetter = UnicodeProperty.letter.matching()

let validNameComponent = sequence(
	unicodeLetter,
	char("'").strictlyNonRepeating(),
	fancyApostrophe.strictlyNonRepeating(),
	char(".").strictlyNonRepeating()
)

let validNameWord = oneOfSequence(validNameComponent).oneOrMore()
let hypenatedNameWord = sequence(char("-"), validNameWord)
let unicodeWhitespace = UnicodeProperty.separator.matching()

print(
	line(
		// first name
		validNameWord,
		hypenatedNameWord.maybe(),
		
		// if we don't recursively apply optionality like this
		// [first]([second][third?])?
		// then the second name could be interpreted under third name rules
		// (i.e. if we did it like this: [first][second?][third?])
		sequence(
			// second name
			sequence(
				char(",").maybe(),
				unicodeWhitespace,
				validNameWord,
				hypenatedNameWord.maybe()
			),
			
			// third name (entirely optional)
			sequence(
				unicodeWhitespace,
				validNameWord,
				hypenatedNameWord.maybe()
			).maybe()
		).maybe()
	)
	.regularExpressionRepresentation()()
	?? "nope"
)

//let pattern = chars("A"..."Z", "a"..."z", "0"..."9").negated().repeating(between: 5...10)
//print(pattern.regularExpressionRepresentation()() ?? "whoops")
