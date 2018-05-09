//
//  ArrayUtilities.swift
//  Reggie
//
//  Created by Paul Herz on 2018-04-17.
//  Copyright © 2018 Paul Herz. All rights reserved.
//

import Foundation

/// (Not sure how to implement this as a method on Array or Sequence
/// due to the limitations of extensions+generics combined.)
/// Returns either a completely unwrapped Array, or nil if the Array contained
/// nil values.
func allOrNothing<T>(_ array: [T?]) -> [T]? {
	var result = [T]()
	for element in array {
		if let value = element {
			result.append(value)
		} else {
			return nil
		}
	}
	return result
}

func intersperse<T>(_ array: [T], with separator: T) -> [T] {
	var new = [T]()
	for element in array {
		new.append(element)
		new.append(separator)
	}
	// remove the last delimiter, it's dangling
	if !new.isEmpty {
		new.removeLast()
	}
	return new
}
