import Foundation

class ReggieApplication {

	let fileManager = FileManager()
	let reggieFilePath = "./reggie.json"

	struct ReggieFile: Codable {
		struct Entry: Codable {
			var name: String
			var phone: String
		}
		var entries: [Entry]
	}

	let nameValidator: Pattern
	let styledPhoneValidator: Pattern
	let phoneDestyler: Pattern
	let e161PhoneValidator: Pattern

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
			guard let validName = self.processName(args[0]) else {
				print("Bad name.")
				return
			}
			guard let validPhone = self.processPhoneNumber(args[1]) else {
				print("Bad phone.")
				return
			}

			let entry = ReggieFile.Entry(name: validName, phone: validPhone)

			if !self.fileExists() {
				self.createFile()
			}

			guard var file = self.readFile() else {
				print("Could not read file.")
				return
			}
			file.entries.append(entry)
			self.writeFile(file)
			print("Saved \"\(validName)\" to database.")
		}

		// reggie DEL <name>


		// reggie DEL <phone>


		// reggie LIST

	}

	func fileExists() -> Bool {
		return fileManager.fileExists(atPath: reggieFilePath)
	}

	func createFile() {
		let contents = "[]".data(using: .utf8)
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
		
		// then, strip anything other than + and digits to get a pseudo E.161
		// -formatted number. This way, our NANP and E.161 schemes don't need
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