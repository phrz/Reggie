//
//  CharacterField.swift
//  Reggie
//
//  Created by Paul Herz on 2018-04-17.
//  Copyright © 2018 Paul Herz. All rights reserved.
//

import Foundation

public struct CharacterField {
	
	private let isNegated: Bool
	private var items: [CharacterFieldRepresentable]
	
	init(_ i: CharacterFieldRepresentable..., isNegated n: Bool = false) {
		self.items = i
		self.isNegated = n
	}
	
	init(_ i: [CharacterFieldRepresentable], isNegated n: Bool = false) {
		self.items = i
		self.isNegated = n
	}
	
	/// returns a new character field which matches all characters *except*
	/// those in the character group. Only works once to negate. Trying to
	/// negate a negative character field (e.g. `[^A-Z]`) will do nothing.
	func negated() -> CharacterField {
		return CharacterField(items, isNegated: true)
	}
}

extension CharacterField: RegularExpressionRepresentable {
	public func regularExpressionRepresentation() -> () -> String? {
		return {
			let maybeRepresentations = self.items.map {
				$0.characterFieldRepresentation()
			}
			guard let representations = allOrNothing(maybeRepresentations) else {
				return nil
			}
			
			let chainedRepresentations = representations.joined(separator: "")
			let negation = self.isNegated ? "^" : ""
			
			return "[\(negation)\(chainedRepresentations)]"
		}
	}
}
