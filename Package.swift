// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "OHTTPSwift",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(name: "OHTTPEncapsulation", targets: ["OHTTPEncapsulation"]),
        .library(name: "OHTTPSwift", targets: ["OHTTPSwift"]),
    ],
    dependencies: [
        .package(url: "git@github.com:flohealth/bhttp-swift.git", from: "0.1.0")
    ],
    targets: [
        .binaryTarget(
            name: "LibAppRelay",
            url: "https://github.com/cloudflare/privacy-gateway-client-library/releases/download/v0.0.4/LibAppRelay.xcframework.zip",
            checksum: "f2fe029022ee3db61f7a500f1864416aa2b21a72226220f7efb318dc8cfbe583"
        ),
        
        .target(
            name: "OHTTPEncapsulation",
            dependencies: ["AppRelayObjc"]
        ),
        
        .target(
            name: "AppRelayObjc",
            dependencies: ["LibAppRelay"],
            publicHeadersPath: "."
        ),
        
        .target(
            name: "OHTTPSwift",
            dependencies: [
                "OHTTPEncapsulation",
                .product(name: "BinaryHTTP", package: "bhttp-swift")
            ]
        ),
        
        .testTarget(
            name: "OHTTPSwiftTests",
            dependencies: ["OHTTPSwift"]
        )
    ]
)
