// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "OpenCV",
  platforms: [.iOS(.v18)],
  products: [
    .library(name: "OpenCV", targets: ["OpenCV"])
  ],
  targets: [
    .binaryTarget(
      name: "OpenCV",
      url: "https://github.com/asusmaas/JustTheBinary/releases/download/4.12.1-slim/OpenCV.xcframework.zip",
      checksum: "32ce4ef66b4773ce794dcd23a059cbaed5f3d445dadf86fde15bb6334886e2f3")
  ]
)
