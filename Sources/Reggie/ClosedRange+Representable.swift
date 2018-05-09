//
//  ClosedRange+Representable.swift
//  Reggie
//
//  Created by Paul Herz on 2018-04-12.
//  Copyright © 2018 Paul Herz. All rights reserved.
//

import Foundation

/// this extension on ClosedRange allows character ranges in character fields
/// (`[A-Z]`, for example) to be represented in Swift by "A"..."Z", for example.
/// In these contexts, unfortunately, Swift doesn't interpret the String literals
/// as Character instances, whereas it does in others, leading to our need to
/// implement CharacterFieldRepresentable for String.
extension ClosedRange: CharacterFieldRepresentable where Bound: CharacterFieldRepresentable {
	public func characterFieldRepresentation() -> String? {
		guard
			let a = lowerBound.characterFieldRepresentation(),
			let b = upperBound.characterFieldRepresentation()
		else {
			return nil
		}
		return "\(a)-\(b)"
	}
}
