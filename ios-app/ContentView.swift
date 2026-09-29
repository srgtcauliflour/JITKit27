import SwiftUI

struct ContentView: View {
    @StateObject private var store = PairingStore()
    var body: some View {
        NavigationStack {
            List {
                Section("Device") {
                    LabeledContent("Platform", value: UIDevice.current.userInterfaceIdiom == .pad ? "iPadOS" : "iOS")
                    LabeledContent("Version", value: UIDevice.current.systemVersion)
                    LabeledContent("Remote Pairing", value: "iOS/iPadOS 27+")
                }
                Section("Pairing") {
                    Button(store.stage == .pairing ? "Pairing…" : "1. Generate Pairing File") { store.beginPairing() }.disabled(store.stage == .pairing)
                    if let pin = store.pin {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("PAIRING PIN").font(.caption).foregroundStyle(.secondary)
                            Text(pin).font(.system(size: 36, weight: .bold, design: .monospaced)).textSelection(.enabled)
                            Text("Enter this PIN in the Remote Pairing prompt shown by iOS/iPadOS.").font(.footnote)
                        }.padding(.vertical, 4)
                    }
                    if let device = store.pairedDevice { LabeledContent("Paired device", value: device) }
                    Button("2. Validate Pairing File") { store.validate() }.disabled(store.pairingURL == nil)
                    if let url = store.pairingURL { ShareLink(item: url) { Label("3. Export .mobiledevicepairing", systemImage: "square.and.arrow.up") } }
                }
                Section("Status") {
                    Text(store.stage.rawValue).font(.headline)
                    Text(store.detail).font(.footnote).textSelection(.enabled)
                }
                Section("v0.2") { Label("JIT engine reserved for next milestone", systemImage: "hammer") }
            }.navigationTitle("JITKit27")
        }
    }
}
