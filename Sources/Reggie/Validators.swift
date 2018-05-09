//
//  Validators.swift
//  Reggie
//
//  Created by Paul Herz on 2018-05-08.
//  Copyright © 2018 Paul Herz. All rights reserved.
//

import Foundation

// +1 is EXCLUDED to be matched separately in NANP
let oneDigitCountryCodes = ["7"]

let twoDigitCountryCodes = [
	"82","41","20","33","31","48","64","45","60","54","63","57","98","47","90",
	"92","89","56","53","43","40","86","30","95","51","52","39","81","44","55",
	"83","32","91","36","61","65","27","93","34","62","28","46","66","84","49",
	"94","58"
]

let threeDigitCountryCodes = [
	"212","216","507","227","850","965","997","800","377","999","693","594","696",
	"685","809","964","976","378","857","678","963","887","245","254","504","876",
	"243","210","223","239","230","855","871","222","292","968","996","389","371",
	"253","692","680","684","978","875","990","224","244","255","350","352","219",
	"358","426","688","801","879","966","961","266","291","299","881","859","804",
	"886","217","236","261","806","993","422","599","355","880","889","807","351",
	"508","679","265","686","215","268","697","388","967","974","598","687","269",
	"503","851","670","234","420","681","248","505","597","506","691","296","596",
	"695","264","858","251","852","425","873","971","698","221","998","381","674",
	"970","423","856","242","238","878","220","500","237","379","374","675","259",
	"376","241","372","298","424","429","356","595","383","385","884","218","509",
	"808","683","252","803","969","689","295","235","382","225","962","359","240",
	"877","232","690","994","995","250","233","231","802","853","427","249","428",
	"592","267","256","421","991","972","211","263","502","979","213","671","888",
	"226","290","870","883","373","257","885","591","258","992","677","501","214",
	"676","375","872","882","380","854","293","294","260","247","672","357","590",
	"297","229","977","354","387","673","699","386","874","682","694","960","370",
	"973","246","262","384","805","593","228","975","353"
]

let hyphen = Character("-")
let enDash = Character("–")
let emDash = Character("—")
let unicodeWhitespace = UnicodeProperty.separator.matching()

func makeNameValidator() -> Pattern? {
	// I initally tried a very ambitious whitelist approach by matching Unicode Categories
	// with the \p{} flag (Unicode property matching). Instead, I've found a blacklist
	// approach to be much more sensible.
	let expression = line(
		chars("!@#$%^&*()+=[]{}<>\\|/?:;\r\n\t\\x00").negated().oneOrMore()
	)
	
	do {
		return try Pattern(expression)
	} catch let e {
		print(e.localizedDescription)
		return nil
	}
}

/// validates the format of a styled, delimited phone number. Is very liberal,
/// just generally avoids alphabet characters.
func makeStyledPhoneValidator() -> Pattern? {
	return try? Pattern(
		oneOf(
			chars("+","0"..."9",hyphen,enDash,emDash,".","(",")"), unicodeWhitespace
		).oneOrMore()
	)
}

/// strips formatting from a phone number, just leaving + and numbers.
func makePhoneDestyler() -> Pattern? {
	return try? Pattern(
		chars("0"..."9","+").negated().oneOrMore()
	)
}

func makePrefixes(codes: [String]) -> RegularExpressionRepresentable {
	return sequence(char("+"), oneOfSequence(sequence(codes.map { str($0) })))
}

func makeStandardizedPhoneValidator() -> Pattern? {
	
	let digit = chars("0"..."9")
	let notZeroOrOne = chars("2"..."9")
	let notOne = chars("0","2"..."9")
	let one = char("1")
	let notNine = chars("0"..."8")
	
	// NANP: North American Numbering Plan -
	// The standard for +1 country code numbers in North America and the
	// Carribean.
	//
	// (+1)?NPANXXxxxx
	//
	// NANP is not assigning area codes with nine as the second digit.
	// NPA -> [2-9][0-8][0-9]
	//
	// exchange codes may not have the digit one in both the second and third position,
	// and the first digit of both the area code and the exchange must be 2-9.
	// NXX -> [2-9](1[02-9]|[02-9]1|[02-9][02-9])
	// xxxx -> [0-9]{4}
	let nanpCountryCode = sequence(str("+1"))
	let areaCode = sequence(notZeroOrOne, notNine, digit)
	let exchange = sequence(
		notZeroOrOne,
		// the second two digits of the exchange code may contain zero or one
		// instances of the digit one.
		oneOf(
			sequence(one,notOne),sequence(notOne,one),sequence(notOne,notOne)
		)
	)
	let subscriber = digit.repeating(withCount: 4)
	
	let nanp = sequence(
		nanpCountryCode.maybe(), areaCode, exchange, subscriber
	)
	
	// E.164: ITU-T Recommendation -
	// The international public telecommunication numbering plan
	
	let oneDigitPrefix   = makePrefixes(codes: oneDigitCountryCodes)
	let twoDigitPrefix   = makePrefixes(codes: twoDigitCountryCodes)
	let threeDigitPrefix = makePrefixes(codes: threeDigitCountryCodes)
	
	// 15 >= len(country code, rest of number)
	//
	// Saint Helena has the shortest phone number possible: 4 digits.
	// E.164 permits up to 15 digits including the country code.
	// We assume 4 to be the shortest possible local number.
	
	let e164 = oneOf(
		// one digit code variant: 1 + 14 = 15 max
		sequence(oneDigitPrefix, digit.repeating(between: 4...14)),
		// two digit variant: 2 + 13 = 15 max
		sequence(twoDigitPrefix, digit.repeating(between: 4...13)),
		// three digit variant: 3 + 12 = 15 max
		sequence(threeDigitPrefix, digit.repeating(between: 4...12))
	)
	
	// try the NANP and E.164 standards separately
	let expression = oneOf(nanp, e164)
	print(expression.regularExpressionRepresentation()() ?? "poo")
	do {
		return try Pattern(expression)
	} catch let e {
		print(e.localizedDescription)
		return nil
	}
}
