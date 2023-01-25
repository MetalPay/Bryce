// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "BryceNetworking",
    platforms: [
        .iOS(.v10),
        .watchOS(.v4)
    ],
    products: [
        .library(
            name: "BryceNetworking",
            targets: ["BryceNetworking"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", .upToNextMajor(from: "4.1.0")),
        .package(url: "https://github.com/Alamofire/Alamofire.git", .exact("5.4.0")),
        .package(url: "https://github.com/konkab/AlamofireNetworkActivityLogger", .exact("3.4.0")),
        .package(url: "https://github.com/Otbivnoe/CodableAlamofire.git", .exact("1.2.1")),
    ],
    targets: [
        .target(
            name: "BryceNetworking",
            dependencies: [
                "KeychainAccess",
                "Alamofire",
                "AlamofireNetworkActivityLogger",
                "CodableAlamofire"
            ],
            path: "Bryce"),
        .testTarget(
            name: "BryceNetworkingTests",
            dependencies: ["BryceNetworking"],
            path: "Example/Tests"),
    ],
    swiftLanguageVersions: [.v5]
)
