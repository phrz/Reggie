struct ReggieFile: Codable {
	struct Entry: Codable {
		var name: String
		var phone: String
	}
	var entries: [Entry]
}