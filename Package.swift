// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SpellCheckerBot",
    dependencies: [
		.package(url: "https://github.com/givip/Telegrammer.git", .branch("develop"))
    ],
    targets: [
        .target( name: "SpellCheckerBot", dependencies: ["Telegrammer"]),
    ]
)
