import SwiftUI

@main
struct SecureNotesRASPApp: App {
    private let securityVerdict = SecurityGate.evaluate()
    @State private var debugBypassed = false

    var body: some Scene {
        WindowGroup {
            if securityVerdict.isCompromised && !debugBypassed {
                BlockedView(verdict: securityVerdict, onDebugBypass: { debugBypassed = true })
            } else {
                ContentView()
            }
        }
    }
}
