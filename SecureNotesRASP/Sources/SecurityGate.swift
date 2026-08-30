import IOSSecuritySuite

enum SecurityGate {
    struct Verdict {
        let isJailbroken: Bool
        let isDebugged: Bool
        let isReverseEngineered: Bool

        var isCompromised: Bool { isJailbroken || isDebugged || isReverseEngineered }
    }

    /// Runs once, at composition root, before the encrypted store is ever
    /// touched. A compromised environment never gets a DatabaseQueue.
    static func evaluate() -> Verdict {
        Verdict(
            isJailbroken: IOSSecuritySuite.amIJailbroken(),
            isDebugged: IOSSecuritySuite.amIDebugged(),
            isReverseEngineered: IOSSecuritySuite.amIReverseEngineered()
        )
    }
}
