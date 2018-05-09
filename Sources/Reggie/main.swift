//
//  main.swift
//  Reggie
//
//  Created by Paul Herz on 2018-04-12.
//  Copyright © 2018 Paul Herz. All rights reserved.
//

import Foundation

let addDescription = """
reggie ADD "Johnny Appleseed" "555 555 5555" — adds a person with a name and a telephone number to the database.
"""

guard
	let nameValidator = makeNameValidator(),
	let styledPhoneValidator = makeStyledPhoneValidator(),
	let phoneDestyler = makePhoneDestyler(),
	let standardPhoneValidator = makeStandardizedPhoneValidator()
else {
		print("Could not compile validators.")
		exit(1)
}

func processName(_ input: String) -> String? {
	guard nameValidator.fullyMatches(input) else { return nil }
	return input
}

func processPhoneNumber(_ input: String) -> String? {
	// first, determine if the number is in an acceptable format given
	// stylization. We are very liberal here, only preventing alphabetic
	// characters and other irrelevant content.
	guard styledPhoneValidator.fullyMatches(input) else { return nil }
	
	// then, strip anything other than + and digits to get a pseudo E.161
	// -formatted number. This way, our NANP and E.161 schemes don't need
	// to consider arbitrary delimiter styling.
	let destyled = phoneDestyler.strippingMatches(in: input)
	
	// finally, validate the stripped-down E.161-formatted number
	// to see if it complies with our delimiter-naïve version of NANP
	// (if it's a +1 number) or with a pretty solid E.161 validator.
	guard standardPhoneValidator.fullyMatches(destyled) else {
		return nil
	}
	
	return destyled
}

let cli = CLI()
cli.register(route: "ADD", description: addDescription, parameterCount: 2...2) {
	print($0)
}

while(true) {
	cli.handle(arguments: CommandLine.arguments)
}