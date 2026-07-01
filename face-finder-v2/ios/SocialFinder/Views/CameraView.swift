import SwiftUI
import AVFoundation

struct CameraView: View {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CameraPicker(image: $image, onDismiss: { dismiss() })
            .ignoresSafeArea()
            .onAppear {
                guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
                    AVCaptureDevice.requestAccess(for: .video) { _ in }
                    return
                }
            }
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        picker.modalPresentationStyle = .fullScreen
        return picker
    }

    func updateUIViewController(_: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ p: CameraPicker) { parent = p }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { parent.image = img }
            parent.onDismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onDismiss()
        }
    }
}
