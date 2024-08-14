import ProjectDescription

let project = Project(
    name: "taskchamp",
    targets: [
        .target(
            name: "taskchamp",
            destinations: .iOS,
            product: .app,
            bundleId: "com.mav.taskchamp",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "LaunchBackground"
                    ],
                    "ITSAppUsesNonExemptEncryption": false,
                    "NSUbiquitousContainers": [
                        "iCloud.com.mav.taskchamp":
                            [
                                "NSUbiquitousContainerIsDocumentScopePublic": true,
                                "NSUbiquitousContainerName": "taskchamp",
                                "NSUbiquitousContainerSupportedFolderLevels": "Any"
                            ]
                    ]
                ]
            ),
            sources: ["taskchamp/Sources/**"],
            resources: ["taskchamp/Resources/**"],
            entitlements: .dictionary(
                [
                    "com.apple.developer.icloud-container-identifiers": ["iCloud.com.mav.taskchamp"],
                    "com.apple.developer.icloud-services": ["CloudDocuments"],
                    "com.apple.developer.ubiquity-container-identifiers": ["iCloud.com.mav.taskchamp"]
                ]
            ),
            scripts: [
                .pre(script: "./scripts/pre_build_script.sh", name: "Prebuild", basedOnDependencyAnalysis: false)
            ],
            dependencies: [
                .external(name: "SQLite")
            ]
        ),
        .target(
            name: "taskchampTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.tuist.taskchampTests",
            infoPlist: .default,
            sources: ["taskchamp/Tests/**"],
            resources: [],
            dependencies: [.target(name: "taskchamp")]
        )
    ]
)
