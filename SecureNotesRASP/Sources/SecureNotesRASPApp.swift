import SwiftUI

@main
struct SecureNotesRASPApp: App {
    private let securityVerdict = SecurityGate.evaluate()

    var body: some Scene {
        WindowGroup {
            if securityVerdict.isCompromised {
                BlockedView(verdict: securityVerdict)
            } else {
                ContentView()
            }
        }
    }
}
