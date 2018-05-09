//
//  Group.swift
//  Reggie
//
//  Created by Paul Herz on 2018-04-17.
//  Copyright © 2018 Paul Herz. All rights reserved.
//

import Foundation

public class Group {
	public enum GroupType: String {
		case
		capturing = "",
		nonCapturing = "?:",
		negativeLookahead = "?!"
	}
	
	internal let type: GroupType
	internal let sequence: RegularExpressionSequence
	
	init(type t: GroupType = .nonCapturing, sequence s: RegularExpressionSequence) {
		self.type = t
		self.sequence = s
	}
	
	func having(type t: GroupType) -> Group {
		return Group(type: t, sequence: sequence)
	}
}

extension Group: RegularExpressionRepresentable {
	public func regularExpressionRepresentation() -> () -> String? {
		let result = self.sequence.regularExpressionRepresentation()().map {
			return "(\(self.type.rawValue)\($0))"
		}
		// we get problems with deallocated "self" if we don't predetermine
		// the result
		return { result }
	}
}
