import Foundation

class CLI {
	typealias RouteHandler = ([String]) -> ()
	private var parameterCounts: [String: Range<Int>] = [:]
	private var routes: [String: RouteHandler] = [:]
	private var docs: [String: String?] = [:]

	func register(
		route: String, 
		description: String? = nil, 
		parameterCount: Range<Int> = Range<Int>(0...0), 
		withHandler handler: @escaping RouteHandler
	) {
		self.routes[route] = handler
		self.parameterCounts[route] = parameterCount
		self.docs[route] = description
	}

	func handle(arguments: [String]) {
		// we need the command name itself + the route name
		guard arguments.count >= 2 else { help(); return }

		let routeName = arguments[1]
		guard let handler = self.routes[routeName] else { help(); return }

		guard argument
	}

	func help() {
		print("HELP")
	}
}