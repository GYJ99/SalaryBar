// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SalaryBar",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "SalaryBar",
            targets: ["SalaryBar"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "SalaryBar"
        ),
        .testTarget(
            name: "SalaryBarTests",
            dependencies: ["SalaryBar"]
        ),
    ]
)
