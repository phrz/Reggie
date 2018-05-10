import Foundation
import Reggie

class ReggieApplication {

	let fileManager = FileManager()
	let reggieFilePath = "./reggie.json"

	let nameValidator: ReggiePattern
	let styledPhoneValidator: ReggiePattern
	let phoneDestyler: ReggiePattern
	let e161PhoneValidator: ReggiePattern

	let cli: CLI

	init?() {
		guard
			let nv = makeNameValidator(),
			let spv = makeStyledPhoneValidator(),
			let pd = makePhoneDestyler(),
			let e161pv = makeStandardizedPhoneValidator()
		else { return nil }

		self.nameValidator = nv
		self.styledPhoneValidator = spv
		self.phoneDestyler = pd
		self.e161PhoneValidator = e161pv

		self.cli = CLI()
		registerRoutes()
	}

	func registerRoutes() {
		// reggie ADD <name> <phone>
		cli.register(
			routeName: "ADD",
			parameterCount: 2..<3
		) { [unowned self] args in
			Handlers.addRoute(app: self, arguments: args)
		}

		// reggie DEL <name>
		// reggie DEL <phone>
		cli.register(
			routeName: "DEL",
			parameterCount: 1..<2
		) { [unowned self] args in
			Handlers.deleteRoute(app: self, arguments: args)
		}


		// reggie LIST
		cli.register(
			routeName: "LIST",
			parameterCount: 0..<1
		) { [unowned self] args in
			Handlers.listRoute(app: self, arguments: args)
		}
	}

	func fileExists() -> Bool {
		return fileManager.fileExists(atPath: reggieFilePath)
	}

	func createFile() {
		let contents = "{\"entries\":[]}".data(using: .utf8)
		fileManager.createFile(atPath: reggieFilePath, contents: contents)
	}

	func readFile() -> ReggieFile? {
		let url = URL(fileURLWithPath: reggieFilePath)
		do {
			let data = try Data(contentsOf: url, options: .mappedIfSafe)
			let decoder = JSONDecoder()
			let file = try decoder.decode(ReggieFile.self, from: data)
			return file
		} catch let e {
			print(e.localizedDescription)
			return nil
		}
	}

	func writeFile(_ reggieFile: ReggieFile) -> Bool {
		let url = URL(fileURLWithPath: reggieFilePath)
		do {
			let encoder = JSONEncoder()
			let data = try encoder.encode(reggieFile)
			try data.write(to: url, options: .atomic)
			return true
		} catch let e {
			print(e.localizedDescription)
			return false
		}
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
		
		// then, strip anything other than + and digits to get a pseudo E.164
		// -formatted number. This way, our NANP and E.164 schemes don't need
		// to consider arbitrary delimiter styling.
		let destyled = phoneDestyler.strippingMatches(in: input)
		
		// finally, validate the stripped-down E.161-formatted number
		// to see if it complies with our delimiter-naïve version of NANP
		// (if it's a +1 number) or with a pretty solid E.161 validator.
		guard e161PhoneValidator.fullyMatches(destyled) else {
			return nil
		}
		
		return destyled
	}

	func run() {
		cli.handle(arguments: CommandLine.arguments)
	}
}