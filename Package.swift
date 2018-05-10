// swift-tools-version:4.0
import PackageDescription

let package = Package(
	name: "Reggie",
	products: [
		.executable(name: "Reggie", targets: ["Reggie"])
	],
	dependencies: [],
	targets: [
		.target(name: "Reggie", dependencies: [])
	]
)