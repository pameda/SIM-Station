// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SIMStation",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "SIMStation", targets: ["SIMStation"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(name: "SIMStation", dependencies: ["CModemBridge"], path: "Station",
                          swiftSettings: [.swiftLanguageMode(.v5)]),
        .testTarget(name: "StationTests", dependencies: ["SIMStation"], path: "StationTests",
                    swiftSettings: [.swiftLanguageMode(.v5)]),
        .target(
            name: "CModemBridge",
            dependencies: [],
            publicHeadersPath: "include",
            linkerSettings: [
                .linkedFramework("CoreFoundation"),
                .linkedFramework("IOKit")
            ]
        )
    ]
)
