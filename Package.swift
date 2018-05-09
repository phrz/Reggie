// swift-tools-version:4.0
import PackageDescription

let package = Package(
	name: "Reggie",
	products: [
		.executable(name: "Reggie", targets: ["Reggie"])
	],
	dependencies: [
		.package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.11.0")
	],
	targets: [
		.target(name: "Reggie", dependencies: ["SQLite"])
	]
)