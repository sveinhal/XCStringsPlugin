// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "XCStringsPlugin",
    products: [
        .plugin(
            name: "GenerateSymbols",
            targets: ["GenerateSymbols"]
        ),
    ],
    targets: [
        .plugin(
            name: "GenerateSymbols",
            capability: .buildTool(),
            path: ".",
        ),
    ]
)
