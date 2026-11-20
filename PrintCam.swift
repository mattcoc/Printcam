import SwiftUI
import AVFoundation

@main struct PrintCamApp: App {
    var body: some Scene { WindowGroup { Station() } }
}
private let lime = Color(red:0.79,green:0.95,blue:0.36)
struct Preview: UIViewRepresentable {
    let session: AVCaptureSession
    final class Surface: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    }
    func makeUIView(context: Context) -> Surface {
        let view = Surface()
        let layer = view.layer as! AVCaptureVideoPreviewLayer
        layer.session = session
        layer.videoGravity = .resizeAspectFill
        return view
    }
    func updateUIView(_ view: Surface, context: Context) {}
}
struct Station: View {
    @StateObject private var camera = Camera()
    @AppStorage("host") private var host = ""
    @State private var dim = false
    @Environment(\.scenePhase) private var phase
    private var link: URL? {
        let parts = host.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ".")
        let octets = parts.compactMap { UInt8($0) }
        guard parts.count == 4, octets.count == 4, octets[0] == 100, (64...127).contains(octets[1]) else { return nil }
        return URL(string:"http://" + octets.map { String($0) }.joined(separator:".") + ":8787/#" + camera.key)
    }
    var body: some View {
        ZStack {
            Color(white:0.055).ignoresSafeArea()
            ScrollView {
                VStack(alignment:.leading,spacing:18) {
                    Text("RUBBS3D   /   PRINTCAM").font(.caption.monospaced().bold()).foregroundStyle(lime)
                    Text("Postazione").font(.system(size:43,weight:.bold))
                    ZStack {
                        RoundedRectangle(cornerRadius:20).fill(Color(white:0.12))
                        if camera.running { Preview(session: camera.session) }
                        else { Image(systemName:"camera.aperture").font(.system(size:65,weight:.light)).foregroundStyle(lime) }
                    }.frame(height:245).clipShape(RoundedRectangle(cornerRadius:20))
                    Text(camera.message).font(.headline)
                    Button { camera.running ? camera.stop() : camera.start() } label: {
                        Label(camera.running ? "Ferma telecamera" : "Avvia telecamera", systemImage:camera.running ? "stop.fill" : "video.fill").frame(maxWidth:.infinity).padding(10)
                    }.buttonStyle(.borderedProminent).tint(lime).foregroundStyle(.black).disabled(camera.busy)
                    Text("Collega il secondo iPhone").font(.title3.bold())
                    Text("Inserisci l’IPv4 di questo iPhone indicato in Tailscale.").foregroundStyle(.secondary)
                    TextField("100.x.y.z",text:$host).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                    if camera.running, let link = link {
                        ShareLink(item:link) { Label("Condividi link privato",systemImage:"square.and.arrow.up") }
                        Button("Oscura interfaccia") { dim = true }
                    }
                }.padding(22)
            }
            if dim {
                Color.black.ignoresSafeArea()
                Button("Tocca per tornare") { dim = false }.foregroundStyle(.gray)
            }
        }.preferredColorScheme(.dark).tint(lime)
        .onChange(of:phase) { if $0 == .background { dim = false; camera.stop() } }
    }
}
