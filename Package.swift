// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LookUp",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "LookUpCore"),
        .executableTarget(
            name: "LookUp",
            dependencies: ["LookUpCore"]
        ),
        .testTarget(
            name: "LookUpCoreTests",
            dependencies: ["LookUpCore"]
        ),
    ]
)
