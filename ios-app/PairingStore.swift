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
        guard isSelfPairingExpected else {
            stage = .failed
            detail = "JITKit27 requires iOS 27.0 or iPadOS 27.0 or later."
            return
        }
        stage = .pairing
        detail = "Preparing Remote Pairing host…"
    }

    func validate() {
        guard pairingURL != nil else { stage = .failed; detail = "Generate a pairing record first."; return }
        stage = .validating
        detail = "Preparing RSD validation…"
    }
}
