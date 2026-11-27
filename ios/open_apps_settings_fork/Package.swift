// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "open_apps_settings_fork",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "open-apps-settings-fork", targets: ["open_apps_settings_fork"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "open_apps_settings_fork",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
