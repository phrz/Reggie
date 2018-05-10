import Foundation
import Reggie

class Handlers {
	static func addRoute(app: ReggieApplication, arguments args: [String]) {
		guard let validName = app.processName(args[0]) else {
			print("\nYou've provided the name:")
			print("\n    \(args[0])\n")
			print("\nI'm sorry, that does not quite look like a name.\n")
			print("    USAGE: reggie ADD <name> <phone>\n")
			return
		}
		guard let validPhone = app.processPhoneNumber(args[1]) else {
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

		if !app.fileExists() {
			app.createFile()
		}

		guard var file = app.readFile() else {
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

		if !app.writeFile(file) {
			print("Failed to write file.")
			return
		}
		print("Saved \"\(validName)\" to database.")
	}
}