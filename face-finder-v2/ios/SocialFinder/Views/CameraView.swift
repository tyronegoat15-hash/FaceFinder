import SwiftUI
import AVFoundation

struct CameraView: View {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = CameraModel()

    var body: some View {
        ZStack {
            CameraPreview(model: model)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.title3.weight(.bold))
                            .foregroundColor(.white).padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Spacer()
                }
                .padding(.top, 56).padding(.leading, 20)

                Spacer()

                Button {
                    model.capture { img in
                        image = img
                        dismiss()
                    }
                } label: {
                    Circle().strokeBorder(.white, lineWidth: 4).frame(width: 72, height: 72)
                        .overlay(Circle().fill(.white).frame(width: 60, height: 60))
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }
}

class CameraModel: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var handler: ((UIImage?) -> Void)?

    func start() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        session.beginConfiguration()
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()
        DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
    }

    func stop() { session.stopRunning() }

    func capture(_ completion: @escaping (UIImage?) -> Void) {
        handler = completion
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let img = UIImage(data: data) else { handler?(nil); return }
        handler?(img)
    }
}

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var model: CameraModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let layer = AVCaptureVideoPreviewLayer(session: model.session)
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        (uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer)?.frame = uiView.bounds
    }
}
