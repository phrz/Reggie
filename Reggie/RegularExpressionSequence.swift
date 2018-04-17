//
//  RegularExpressionSequence.swift
//  Reggie
//
//  Created by Paul Herz on 2018-04-17.
//  Copyright © 2018 Paul Herz. All rights reserved.
//

import Foundation

public typealias RegularExpressionSequence = Array<RegularExpressionRepresentable>

extension Array: RegularExpressionRepresentable where Array.Element == RegularExpressionRepresentable {
	public func regularExpressionRepresentation() -> () -> String? {
		return {
			let maybeRepresentations = self.map { $0.regularExpressionRepresentation()() }
			guard let representations = allOrNothing(maybeRepresentations) else {
				return nil
			}
			return representations.joined(separator: "")
		}
	}
}
