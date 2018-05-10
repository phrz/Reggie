import Foundation

class CLI {
	struct Route {
		let parameterCount: Range<Int>
		let handler: RouteHandler
	}

	typealias RouteHandler = ([String]) -> ()
	private var routes: [String: Route] = [:]

	func register(
		routeName: String, 
		parameterCount: Range<Int> = Range(0...0),
		withHandler handler: @escaping RouteHandler
	) {
		guard self.routes[routeName] == nil else {
			print("Logic Error: Cannot register another route with a duplicate name '\(routeName)'!")
			exit(1)
		}
		self.routes[routeName] = Route(
			parameterCount: parameterCount,
			handler: handler
		)
	}

	func handle(arguments: [String]) {
		// we need the executable name itself + the route name
		// at a minimum (2 args)
		guard arguments.count >= 2 else {
			help()
			return
		}

		// the args after the executable and the route name
		let givenRouteArgs = arguments.count - 2
		let givenRouteName = arguments[1]

		guard let route = self.routes[givenRouteName] else { 
			help()
			return 
		}
		
		guard route.parameterCount.contains(givenRouteArgs) else {
			help()
			return
		}

		// the arguments the route expects are the arguments excluding
		// the executable name and the route name
		route.handler(Array(arguments.suffix(from: 2)))
	}

	func help() {
		print(
			"""

			USAGE: 
			reggie ADD "<name>" "<telephone>"
				adds a person's name and telephone number to the database.
			reggie DEL "<name>"
			reggie DEL "<telephone>"
				delete an entry by matching the name or telephone number
			reggie LIST
				list the contents of the database
				
			"""
		)
	}
}