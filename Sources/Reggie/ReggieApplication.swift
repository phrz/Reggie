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
				print("\nYou've provided the name:")
				print("\n    \(args[0])\n")
				print("\nI'm sorry, that does not quite look like a name.\n")
				print("    USAGE: reggie ADD <name> <phone>\n")
				return
			}
			guard let validPhone = self.processPhoneNumber(args[1]) else {
				print("\nYou've provided the phone number:")
				print("\n    \(args[1])\n")
				print("I'm sorry, that does not quite look like a valid phone number.")
				print("This is what we're used to seeing, and we don't normally care")
				print("how you space it or where you put dashes or dots. If you have")
				print("a (+1) number from North America, it's OK to leave the +1 in")
				print("or take it out, but it has to be 10 numbers. We make sure")
				print("it's a real North American number based on some rules for how")
				print("the numbers are given out. If you have a number that isn't (+1),")
				print("you'll have to provide your country code no matter what.\n")
				print("    North American numbers:  +1 ### ### ####")
				print("                                ### ### ####")
				print("    International (E.164):   +# ##############")
				print("                            +## #############")
				print("                           +### ############\n")
				print("    USAGE: reggie ADD <name> <phone>\n")
				
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

			// linear search for duplicates
			for e in file.entries {
				if e.name == validName {
					print("An entry already exists with that name.")
					return
				}
				if e.phone == validPhone {
					print("An entry already exists with that phone number.")
					return
				}
			}

			// save the new entry if there are no duplicates.
			file.entries.append(entry)

			if !self.writeFile(file) {
				print("Failed to write file.")
				return
			}
			print("Saved \"\(validName)\" to database.")
		}

		// reggie DEL <name>
		// reggie DEL <phone>
		cli.register(
			routeName: "DEL",
			parameterCount: 1..<2
		) { [unowned self] args in
			// the name or telephone of the entry to delete
			let deleteParameter = args[0]

			if !self.fileExists() {
				self.createFile()
			}
			guard var file = self.readFile() else {
				print("Could not read file.")
				return
			}

			let oldSize = file.entries.count
			file.entries = file.entries.filter { 
				$0.name != deleteParameter && $0.phone != deleteParameter
			}
			let newSize = file.entries.count

			if newSize == oldSize {
				print("No matches found.")
				return
			}

			if !self.writeFile(file) {
				print("Failed to write file.")
				return
			}
			print("Removed \"\(deleteParameter)\" from database.")
		}


		// reggie LIST
		cli.register(
			routeName: "LIST",
			parameterCount: 0..<1
		) { [unowned self] args in
			if !self.fileExists() {
				self.createFile()
			}
			guard let file = self.readFile() else {
				print("Could not read file.")
				return
			}

			print("\nName: Telephone")
			for entry in file.entries {
				print("\(entry.name):\n    \(entry.phone)")
			}
			print()
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