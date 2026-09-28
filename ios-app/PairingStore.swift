import Foundation
import SwiftUI

@MainActor
final class PairingStore: ObservableObject {
    enum Stage: String { case ready = "Ready", pairing = "Pairing", generated = "Generated", validating = "Validating", validated = "Validated", failed = "Failed" }
    @Published var stage: Stage = .ready
    @Published var detail = "No pairing record has been generated yet."
    @Published var pairingURL: URL?

    var isSelfPairingExpected: Bool {
        ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 27
    }

    func beginPairing() {
        stage = .pairing
        detail = isSelfPairingExpected ? "Preparing Remote Pairing host…" : "Experimental OS target: probing Remote Pairing capability."
    }

    func validate() {
        guard pairingURL != nil else { stage = .failed; detail = "Generate a pairing record first."; return }
        stage = .validating
        detail = "Preparing RSD validation…"
    }
}
