import ProjectDescription

let project = Project(
    name: "SecureNotesRASP",
    targets: [
        .target(
            name: "SecureNotesRASP",
            destinations: .iOS,
            product: .app,
            bundleId: "com.kanat.securenotesrasp",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .default,
            sources: ["SecureNotesRASP/Sources/**"],
            resources: ["SecureNotesRASP/Resources/**"],
            dependencies: [
                .external(name: "GRDB")
            ]
        )
    ]
)
