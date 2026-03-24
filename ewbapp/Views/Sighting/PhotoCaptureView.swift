import SwiftUI
import UIKit

struct PhotoCaptureView: View {
    @Binding var photoFilenames: [String]
    @State private var showCamera = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Photos (\(photoFilenames.count)/3)")
                .font(.headline)
            HStack(spacing: 12) {
                // Thumbnails
                ForEach(photoFilenames, id: \.self) { filename in
                    PhotoThumbnail(filename: filename)
                }
                // Camera button
                if photoFilenames.count < 3 {
                    Button {
                        showCamera = true
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                            Text("Add Photo")
                                .font(.caption)
                        }
                        .frame(width: 80, height: 80)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPickerView { filename in
                if let filename = filename {
                    photoFilenames.append(filename)
                }
                showCamera = false
            }
        }
    }
}

struct PhotoThumbnail: View {
    let filename: String

    var body: some View {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Photos")
            .appendingPathComponent(filename)
        if let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray4))
                .frame(width: 80, height: 80)
                .overlay(Image(systemName: "photo").foregroundColor(.secondary))
        }
    }
}

struct CameraPickerView: UIViewControllerRepresentable {
    let completion: (String?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let completion: (String?) -> Void
        init(completion: @escaping (String?) -> Void) { self.completion = completion }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            guard let image = info[.originalImage] as? UIImage else {
                completion(nil)
                return
            }
            let filename = "photo_\(UUID().uuidString).jpg"
            let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Photos")
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let url = dir.appendingPathComponent(filename)
            if let data = image.jpegData(compressionQuality: 0.8) {
                try? data.write(to: url)
            }
            completion(filename)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completion(nil)
        }
    }
}
