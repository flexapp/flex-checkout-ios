// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FlexCheckout",
    platforms: [.iOS(.v12)],
    products: [
        .library(name: "FlexCheckout", targets: ["FlexCheckout"]),
    ],
    targets: [
        .binaryTarget(
            name: "FlexCheckout",
            path: "FlexCheckout.xcframework"
        ),
    ]
)
