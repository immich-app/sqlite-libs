// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "sqlite3_flutter_libs",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "sqlite3-flutter-libs", type: .static, targets: ["sqlite3_flutter_libs"])
    ],
    dependencies: [
        // Reference the parent sqlite-libs package
        .package(path: "../../.."),
    ],
    targets: [
        .target(
            name: "sqlite3_flutter_libs",
            dependencies: [
                .product(name: "SQLiteExtensions", package: "sqlite-libs"),
            ]
        )
    ]
)
