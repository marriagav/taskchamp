// swift-tools-version: 5.9
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings()

#endif

let package = Package(
    name: "taskchamp",
    dependencies: [
        // Add your own dependencies here:
        Package.Dependency.package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.3")
    ]
)
