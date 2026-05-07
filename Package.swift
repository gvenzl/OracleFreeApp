// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "OracleFreeApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "OracleFreeKit",
            targets: ["OracleFreeKit"]
        ),
        .executable(
            name: "OracleFreeApp",
            targets: ["OracleFreeApp"]
        )
    ],
    targets: [
        .target(
            name: "OracleFreeKit",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "OracleFreeApp",
            dependencies: ["OracleFreeKit"]
        ),
        .testTarget(
            name: "OracleFreeKitTests",
            dependencies: ["OracleFreeKit"]
        )
    ]
)
