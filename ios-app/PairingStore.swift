import Foundation
import SwiftUI
import JITKit27FFI

private final class PairingCallbackBox {
    weak var store: PairingStore?
    var service: NetService?
    init(_ store: PairingStore) { self.store = store }
}

private func readyCallback(_ ctx: UnsafeMutableRawPointer?, _ serviceID: UnsafePointer<CChar>?, _ port: UInt16, _ keys: UnsafePointer<UnsafePointer<CChar>?>?, _ values: UnsafePointer<UnsafePointer<CChar>?>?, _ count: Int) {
    guard let ctx, let serviceID else { return }
    let box = Unmanaged<PairingCallbackBox>.fromOpaque(ctx).takeUnretainedValue()
    var txt: [String: Data] = [:]
    if let keys, let values {
        for i in 0..<count {
            if let k = keys[i], let v = values[i] { txt[String(cString: k)] = Data(String(cString: v).utf8) }
        }
    }
    let service = NetService(domain: "local.", type: "_remotepairing._tcp.", name: String(cString: serviceID), port: Int32(port))
    service.setTXTRecord(NetService.data(fromTXTRecord: txt))
    box.service = service
    service.publish()
    Task { @MainActor in
        box.store?.detail = "Remote Pairing host advertised. Waiting for the system pairing connection…"
    }
}

private func pinCallback(_ ctx: UnsafeMutableRawPointer?, _ pin: UnsafePointer<CChar>?) {
    guard let ctx, let pin else { return }
    let box = Unmanaged<PairingCallbackBox>.fromOpaque(ctx).takeUnretainedValue()
    let value = String(cString: pin)
    Task { @MainActor in
        box.store?.pin = value
        box.store?.detail = "Enter this PIN in the iOS/iPadOS Remote Pairing prompt."
    }
}

@MainActor
final class PairingStore: ObservableObject {
    enum Stage: String { case ready = "Ready", pairing = "Pairing", generated = "Generated", validating = "Validating", validated = "Validated", failed = "Failed" }
    @Published var stage: Stage = .ready
    @Published var detail = "No pairing record has been generated yet."
    @Published var pairingURL: URL?
    @Published var pin: String?
    @Published var pairedDevice: String?
    private var callbackBox: PairingCallbackBox?

    var isSelfPairingExpected: Bool { ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 27 }

    func beginPairing() {
        guard isSelfPairingExpected else { stage = .failed; detail = "JITKit27 requires iOS 27.0 or iPadOS 27.0 or later."; return }
        guard stage != .pairing else { return }
        stage = .pairing; pin = nil; detail = "Starting Remote Pairing host…"
        let box = PairingCallbackBox(self); callbackBox = box
        let opaque = Unmanaged.passRetained(box).toOpaque()
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        let path = support.appendingPathComponent("rp_pairing_file.plist").path
        let savedIRK = UserDefaults.standard.string(forKey: "JITKit27.hostAltIRK") ?? ""

        DispatchQueue.global(qos: .userInitiated).async {
            var result = Jk27PairResult()
            let code = path.withCString { p in savedIRK.withCString { irk in
                "0.0.0.0".withCString { bind in "JITKit27".withCString { name in "Mac17,7".withCString { model in
                    jk27_pairing_run_host(bind, 0, name, model, p, irk, readyCallback, pinCallback, opaque, &result)
                }}}
            }}
            let err = result.error.map { String(cString: $0) }
            let device = result.device_name.map { String(cString: $0) }
            let file = result.pairing_file_path.map { String(cString: $0) }
            let newIRK = result.host_alt_irk_hex.map { String(cString: $0) }
            jk27_pair_result_free(&result)
            DispatchQueue.main.async {
                let retained = Unmanaged<PairingCallbackBox>.fromOpaque(opaque).takeRetainedValue()
                retained.service?.stop()
                self.callbackBox = nil
                if code == 0, let file {
                    if let newIRK { UserDefaults.standard.set(newIRK, forKey: "JITKit27.hostAltIRK") }
                    self.pairingURL = URL(fileURLWithPath: file)
                    self.pairedDevice = device
                    self.stage = .generated
                    self.detail = "Remote Pairing completed and the pairing identity was saved."
                } else {
                    self.stage = .failed
                    self.detail = err ?? "Remote Pairing failed with code \(code)."
                }
            }
        }
    }

    func validate() {
        guard pairingURL != nil else { stage = .failed; detail = "Generate a pairing record first."; return }
        stage = .validating
        detail = "RSD validation is the next transport milestone."
    }
}
