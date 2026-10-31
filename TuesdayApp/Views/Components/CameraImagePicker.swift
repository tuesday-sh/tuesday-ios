import SwiftUI
import UIKit

public struct CameraImagePicker: UIViewControllerRepresentable {
    public let sourceType: UIImagePickerController.SourceType
    public let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    public init(
        sourceType: UIImagePickerController.SourceType,
        onImagePicked: @escaping (UIImage) -> Void
    ) {
        self.sourceType = sourceType
        self.onImagePicked = onImagePicked
    }

    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            picker.sourceType = sourceType
        } else {
            picker.sourceType = .photoLibrary
        }
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: CameraImagePicker

        init(parent: CameraImagePicker) {
            self.parent = parent
        }

        public func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }

        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
