// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "ImageSlideshow",
    platforms: [
        .iOS(.v12), .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "ImageSlideshow",
            targets: ["ImageSlideshow"]),
        .library(
            name: "ImageSlideshow/Kingfisher",
            targets: ["ImageSlideshowKingfisher"])
    ],
    dependencies: [
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.4.1"),
    ],
    targets: [
        .target(
            name: "ImageSlideshow",
            path: "ImageSlideshow",
            exclude: ["Classes/InputSources/AFURLSource.swift",
                      "Classes/InputSources/ParseSource.swift",
                      "Classes/InputSources/KingfisherSource.swift"],
            sources: [
                "Classes/Core"
            ],
            resources: [
                .copy("Assets/ic_cross_white@2x.png"),
                .copy("Assets/ic_cross_white@3x.png"),
            ]),
        .target(
            name: "ImageSlideshowKingfisher",
            dependencies: ["ImageSlideshow", "Kingfisher"],
            path: "ImageSlideshow/Classes/InputSources",
            exclude: ["AFURLSource.swift",
                      "ParseSource.swift"],              
            sources: ["KingfisherSource.swift"])
    ],
    swiftLanguageVersions: [.v4, .v4_2, .v5]
)
