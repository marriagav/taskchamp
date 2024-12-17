import ProjectDescription

let project = Project(
    name: "taskchamp",
    targets: [
        .target(
            name: "taskchamp",
            destinations: .iOS,
            product: .app,
            bundleId: "com.mav.taskchamp",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleName": "Taskchamp",
                    "UILaunchScreen": [
                        "UIColorName": "LaunchBackground"
                    ],
                    "NSAccentColorName": "AccentColor",
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
                    "com.apple.developer.ubiquity-container-identifiers": ["iCloud.com.mav.taskchamp"],
                    "com.apple.developer.usernotifications.time-sensitive": true
                ]
            ),
            scripts: [
                .pre(script: "./scripts/pre_build_script.sh", name: "Prebuild", basedOnDependencyAnalysis: false)
            ],
            dependencies: [
                .target(name: "taskchampShared"),
                .target(name: "taskchampWidget")
            ]
        ),
        .target(
            name: "taskchampTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.tuist.taskchampTests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["taskchamp/Tests/**"],
            resources: [],
            dependencies: [.target(name: "taskchamp")]
        ),
        .target(
            name: "taskchampWidget",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "com.mav.taskchamp.taskchampWidget",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "$(PRODUCT_NAME)",
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.widgetkit-extension"
                ],
                "NSUbiquitousContainers": [
                    "iCloud.com.mav.taskchamp":
                        [
                            "NSUbiquitousContainerIsDocumentScopePublic": true,
                            "NSUbiquitousContainerName": "taskchamp",
                            "NSUbiquitousContainerSupportedFolderLevels": "Any"
                        ]
                ]
            ]),
            sources: "taskchampWidget/Sources/**",
            entitlements: .dictionary(
                [
                    "com.apple.developer.icloud-container-identifiers": ["iCloud.com.mav.taskchamp"],
                    "com.apple.developer.icloud-services": ["CloudDocuments"],
                    "com.apple.developer.ubiquity-container-identifiers": ["iCloud.com.mav.taskchamp"]
                ]
            ),
            dependencies: [
                .target(name: "taskchampShared")
            ]
        ),
        .target(
            name: "taskchampShared",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.mav.taskchamp.taskchampShared",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            sources: "taskchampShared/Sources/**",
            dependencies: [
                .external(name: "SQLite"),
                .external(name: "SoulverCore")
            ]
        )
    ]
)
