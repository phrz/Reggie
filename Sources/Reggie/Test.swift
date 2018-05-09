//
//  Test.swift
//  Reggie
//
//  Created by Paul Herz on 2018-05-08.
//  Copyright © 2018 Paul Herz. All rights reserved.
//
/*
import Foundation

guard
	let nameValidator = makeNameValidator(),
	let styledPhoneValidator = makeStyledPhoneValidator(),
	let phoneDestyler = makePhoneDestyler(),
	let standardPhoneValidator = makeStandardizedPhoneValidator()
	else {
		print("Could not compile validators.")
		exit(1)
}

let names = [
	// good
	"Bruce Schneier",
	"Schneier, Bruce",
	"Schneier, Bruce Wayne",
	"O’Malley, John F.",
	"John O’Malley-Smith",
	"Cher",
	"Nguyễn Phước",
	// bad
	"Ron O’’Henry",
	"Ron O’Henry-Smith-Barnes",
	"L33t Hacker",
	"<script>alert(\"XSS\")</script>",
	"Brad Everett Samuel Smith",
	"select * from users;"
]

let phones = [
	// good
	"12345",
	"(703)111-2121",
	"123-1234",
	"+1(703)111-2121",
	"+32 (21) 212-2324",
	"1(703)123-1234",
	"011 701 111 1234",
	"12345.12345",
	"011 1 703 111 1234",
	// bad
	"123",
	"1/703/123/1234",
	"Nr 102-123-1234",
	"<script>alert(“XSS”)</script>",
	"7031111234",
	"+1234 (201) 123-1234",
	"(001) 123-1234",
	"+01 (703) 123-1234",
	"(703) 123-1234 ext 204",
	"+1 214 745 4567",
	"+1 (214) 745-4567",
	"+1 214-745-4567",
	"+1 9 03 91 83912",
	"+212 123456789012",
	"+21 1234567890123",
	"+7 12345678901234",
	"+212 1234567890123",
	"+21 12345678901234",
	"+7 123456789012345"
]

//for name in names {
//	print("\(nameValidator.fullyMatches(name) ? "✅" : "🛑") \(name)")
//}

for phone in phones {
	//	print("\(phoneValidator.fullyMatches(phone) ? "✅" : "🛑") \(phone)")
	print("ORIGINAL: \(phone)")
	
	// first, determine if the number is in an acceptable format given
	// stylization. We are very liberal here, only preventing alphabetic
	// characters and other irrelevant content.
	let isStyledValid = styledPhoneValidator.fullyMatches(phone)
	print("STYLE CHECK:", isStyledValid ? "✅" : "🛑")
	
	let destyled = phoneDestyler.strippingMatches(in: phone)
	print("DESTYLED: \(destyled)")
	
	let isValid = standardPhoneValidator.fullyMatches(destyled)
	print("VALID:", isValid ? "✅" : "🛑")
	
	print("\n\n")
}
*/