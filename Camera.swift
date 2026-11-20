import AVFoundation
import CoreImage
import UIKit
import Swifter

final class Camera: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var running = false
    @Published var message = "Pronta per la stampa"
    @Published var busy = false
    let session = AVCaptureSession()
    let key = UUID().uuidString
    private let queue = DispatchQueue(label: "PrintCam.camera")
    private let context = CIContext()
    private let server = HttpServer()
    private var device: AVCaptureDevice?
    private var frame: Data?
    private var last = Date.distantPast
    private var active = false

    func start() {
        guard !busy && !running else { return }
        busy = true
        AVCaptureDevice.requestAccess(for: .video) { allowed in
            self.queue.async {
                do {
                    guard allowed else { throw Issue.permission }
                    guard !self.active else { return }
                    if self.device == nil { try self.configure() }
                    self.session.startRunning()
                    try self.listen()
                    self.active = true
                    self.status(true, "Telecamera attiva")
                } catch {
                    self.stopCapture()
                    self.status(false, error.localizedDescription)
                }
            }
        }
    }
    private func configure() throws {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { throw Issue.hardware }
        let input = try AVCaptureDeviceInput(device: camera)
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: queue)
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .vga640x480
        guard session.canAddInput(input) else { throw Issue.hardware }
        session.addInput(input)
        guard session.canAddOutput(output) else { session.removeInput(input); throw Issue.hardware }
        session.addOutput(output)
        output.connection(with: .video)?.videoOrientation = .portrait
        device = camera
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard active, Date().timeIntervalSince(last) >= 0.15, let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        frame = context.jpegRepresentation(of: CIImage(cvPixelBuffer: buffer), colorSpace: CGColorSpaceCreateDeviceRGB(), options: [:])
        last = Date()
    }
    private func listen() throws {
        let page = try String(contentsOf: Bundle.main.url(forResource: "viewer", withExtension: "html")!, encoding: .utf8)
        server.GET["/"] = { _ in .ok(.html(page)) }
        server.GET["/frame"] = { [weak self] req in
            guard let self = self, self.authorized(req) else { return .raw(401,"Unauthorized",nil,nil) }
            return self.queue.sync {
                guard self.active, Date().timeIntervalSince(self.last) < 2, let data = self.frame else { return .raw(503,"In attesa",nil,nil) }
                return .raw(200,"OK",["Content-Type":"image/jpeg","Cache-Control":"no-store"]) { writer in try writer.write(data) }
            }
        }
        server.GET["/light"] = { [weak self] req in
            guard let self = self, self.authorized(req) else { return .raw(401,"Unauthorized",nil,nil) }
            return self.queue.sync { self.lightState() }
        }
        server.POST["/light"] = { [weak self] req in
            guard let self = self, self.authorized(req) else { return .raw(401,"Unauthorized",nil,nil) }
            guard let value = Int(String(decoding:req.body, as: UTF8.self)), (0...100).contains(value) else { return .raw(400,"Bad Request",nil,nil) }
            return self.queue.sync {
                guard self.active, let device = self.device, device.isTorchAvailable else { return .raw(503,"Torcia indisponibile",nil,nil) }
                do {
                    try device.lockForConfiguration()
                    defer { device.unlockForConfiguration() }
                    if value == 0 { device.torchMode = .off }
                    else { try device.setTorchModeOn(level: Float(value)/100) }
                    return self.lightState()
                } catch { return .raw(503,"Torcia indisponibile",nil,nil) }
            }
        }
        try server.start(8787, forceIPv4: true)
    }
    private func lightState() -> HttpResponse {
        .ok(.json(["available":device?.isTorchAvailable ?? false,"level":Int((device?.torchLevel ?? 0)*100)] as [String:Any]))
    }
    private func authorized(_ req: HttpRequest) -> Bool { req.headers["authorization"] == "Bearer " + key }
    func stop() {
        queue.async {
            self.stopCapture()
            self.status(false, "Telecamera ferma")
        }
    }
    private func stopCapture() {
        active = false
        server.stop()
        if let device = device, device.isTorchActive, (try? device.lockForConfiguration()) != nil {
            device.torchMode = .off
            device.unlockForConfiguration()
        }
        session.stopRunning()
        frame = nil
    }
    private func status(_ on: Bool, _ text: String) {
        DispatchQueue.main.async {
            self.running = on
            self.busy = false
            self.message = text
            UIApplication.shared.isIdleTimerDisabled = on
            if on && UIApplication.shared.applicationState == .background { self.stop() }
        }
    }
    enum Issue: LocalizedError {
        case permission, hardware
        var errorDescription: String? {
            self == .permission ? "Consenti la fotocamera nelle Impostazioni di iOS." : "Fotocamera posteriore indisponibile."
        }
    }
}
