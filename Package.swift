import PackageDescription

let package = Package(
    name: "SwiftPoet",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v10),
        .tvOS(.v10),
        .watchOS(.v3)
    ],
    products: [.library(name: "SwiftPoet", targets: ["SwiftPoet"])],
    targets: [.target(name: "SwiftPoet", path: "Sources")], swiftLanguageVersions: [.v5])
