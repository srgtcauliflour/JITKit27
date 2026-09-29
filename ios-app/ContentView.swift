import SwiftUI

struct ContentView: View {
    @StateObject private var store = PairingStore()
    var body: some View {
        NavigationStack {
            List {
                Section("Device") {
                    LabeledContent("Platform", value: UIDevice.current.userInterfaceIdiom == .pad ? "iPadOS" : "iOS")
                    LabeledContent("Version", value: UIDevice.current.systemVersion)
                    LabeledContent("Self-pairing", value: store.isSelfPairingExpected ? "Supported target" : "Experimental")
                }
                Section("Pairing") {
                    Button("1. Generate Pairing File") { store.beginPairing() }
                    Button("2. Validate Pairing File") { store.validate() }.disabled(store.pairingURL == nil)
                    if let url = store.pairingURL { ShareLink(item: url) { Label("3. Export .mobiledevicepairing", systemImage: "square.and.arrow.up") } }
                }
                Section("Status") { Text(store.stage.rawValue).font(.headline); Text(store.detail).font(.footnote).textSelection(.enabled) }
                Section("v0.2") { Label("JIT engine reserved for next milestone", systemImage: "hammer") }
            }.navigationTitle("JITKit27")
        }
    }
}
