import SwiftUI

struct BlockedView: View {
    let verdict: SecurityGate.Verdict

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            Text("Access Blocked")
                .font(.title2.bold())
            Text("This environment failed a runtime security check. The encrypted note store will not be opened.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 4) {
                reasonRow("Jailbroken", verdict.isJailbroken)
                reasonRow("Debugger attached", verdict.isDebugged)
                reasonRow("Reverse-engineering tooling detected", verdict.isReverseEngineered)
            }
            .padding(.top, 8)
        }
        .padding()
    }

    private func reasonRow(_ label: String, _ flagged: Bool) -> some View {
        HStack {
            Image(systemName: flagged ? "xmark.circle.fill" : "checkmark.circle.fill")
                .foregroundStyle(flagged ? .red : .green)
            Text(label)
        }
        .font(.footnote)
    }
}
