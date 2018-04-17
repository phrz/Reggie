//
//  PureRegularExpressionRepresentation.swift
//  Reggie
//
//  Created by Paul Herz on 2018-04-12.
//  Copyright © 2018 Paul Herz. All rights reserved.
//

import Foundation

/// something that always has a hard-coded Regular Expression representation,
/// such as [PCRE Character Type specifiers](https://www.pcre.org/current/doc/html/pcre2syntax.html#SEC4)
///
public class PureRegularExpressionRepresentation: RegularExpressionRepresentable {
	private let literal: String?
	
	public init(literal l: String?) {
		self.literal = l
	}
	
	public func regularExpressionRepresentation() -> () -> String? {
		return { [unowned self] in self.literal }
	}
}
