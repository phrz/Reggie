//
//  Helpers.swift
//  Reggie
//
//  Created by Paul Herz on 2018-04-17.
//  Copyright © 2018 Paul Herz. All rights reserved.
//

import Foundation

// shorthand functions to quickly construct complex Reggie types.


/// a helper function for the DSL to concisely create
/// PureRegularExpressionRepresentation. Use it to directly insert Regex.
public func pure(_ literal: String?) -> PureRegularExpressionRepresentation {
	return PureRegularExpressionRepresentation(literal: literal)
}

public func never() -> PureRegularExpressionRepresentation {
	return PureRegularExpressionRepresentation(literal: nil)
}

public func char(_ character: Character) -> CharacterField {
	return CharacterField(character)
}

public func chars(_ items: CharacterFieldRepresentable...) -> CharacterField {
	return CharacterField(items)
}

public func chars(_ items: [CharacterFieldRepresentable]) -> CharacterField {
	return CharacterField(items)
}

/// a non-capturing group
public func nonCapturingGroup(_ sequence: RegularExpressionSequence) -> Group {
	return Group(type: .nonCapturing, sequence: sequence)
}

public func capturingGroup(_ sequence: RegularExpressionSequence) -> Group {
	return Group(type: .capturing, sequence: sequence)
}

/// explicit sequence to deal with type system problems, i.e. not detecting
/// array literals as RegularExpressionSequence
public func sequence(_ s: RegularExpressionSequence) -> RegularExpressionSequence {
	return s
}

/// Swift complains about heterogeneous sequences without this and disallows
/// sequences to contain subsequences.
public func sequence(_ s: RegularExpressionRepresentable...) -> RegularExpressionSequence {
	return s
}

/// generates a non-capturing choice group (?:A|B|C)
public func oneOfSequence(_ sequence: RegularExpressionSequence) -> Group {
	let reps = sequence.map {
		$0.regularExpressionRepresentation()()
	}
	// we don't check that all representations are good, that's Groups job
	
	// we map to pure() to make sure things in choice groups don't get escaped
	// when they're not meant to be! (This also required removing the implementation
	// of RegularExpressionRepresentable for String).
	let choiceSequence = intersperse(reps.map { pure($0) }, with: pure("|"))
	return Group(type: .nonCapturing, sequence: choiceSequence)
}

public func oneOf(_ s: RegularExpressionRepresentable...) -> Group {
	return oneOfSequence(s)
}

public func line(_ s: RegularExpressionRepresentable...) -> RegularExpressionSequence {
	return line(sequence(s))
}

public func line(_ s: RegularExpressionSequence) -> RegularExpressionSequence {
	return [pure("^"), s, pure("$")]
}

extension RegularExpressionRepresentable {
	/// negative lookahead shorthand
	public func notFollowedBy(_ pattern: RegularExpressionRepresentable)
	-> RegularExpressionSequence {
		return [self, Group(type: .negativeLookahead, sequence: [pattern])]
	}
	
	/// ensures with neagtive lookahead that the expression cannot repeat
	/// immediately
	public func strictlyNonRepeating() -> RegularExpressionSequence {
		return self.notFollowedBy(self)
	}
}
