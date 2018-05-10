// swift-tools-version:4.0
import PackageDescription

let package = Package(
	name: "Reggie",
	products: [
		Product.library(name: "Reggie", targets: ["Reggie"]),
		Product.executable(name: "ReggieApp", targets: ["ReggieApp"])
	],
	dependencies: [],
	targets: [
		.target(name: "Reggie", dependencies: []),
		.target(name: "ReggieApp", dependencies: ["Reggie"])
	]
)