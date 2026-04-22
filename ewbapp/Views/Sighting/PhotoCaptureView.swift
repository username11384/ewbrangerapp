import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct PhotoCaptureView: View {
    @Binding var photoFilenames: [String]
    /// Receives the area estimate from SizeEstimationOverlay (e.g. "~4.2 m²").
    /// The parent (LogSightingView) owns this binding via the view-model.
    @Binding var estimatedArea: String?

    @State private var showCamera = false
    /// The UIImage that was just captured, held until the estimation overlay is dismissed.
    @State private var pendingImage: UIImage? = nil
    @State private var showEstimation = false

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
                                .font(DSFont.caption)
                        }
                        .frame(width: 80, height: 80)
                        .background(Color.dsSurface)
                        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        // Step 1: camera / photo-library picker
        .sheet(isPresented: $showCamera) {
            CameraPickerView { filename, image in
                if let filename = filename, let image = image {
                    // Add thumbnail immediately so it appears even if user skips estimation
                    photoFilenames.append(filename)
                    pendingImage   = image
                    showEstimation = true
                }
                showCamera = false
            }
        }
        // Step 2: size estimation overlay for the just-captured photo
        .fullScreenCover(isPresented: $showEstimation) {
            if let img = pendingImage {
                SizeEstimationOverlay(image: img, estimatedArea: $estimatedArea)
            }
        }
    }
}

// MARK: - Thumbnail

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
            RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                .fill(Color.dsSurface)
                .frame(width: 80, height: 80)
                .overlay(Image(systemName: "photo").foregroundStyle(Color.dsInk3))
        }
    }
}

// MARK: - Camera picker

/// Wraps UIImagePickerController. The completion now returns both the saved
/// filename and the original UIImage so the caller can forward it to the overlay.
struct CameraPickerView: UIViewControllerRepresentable {
    let completion: (String?, UIImage?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let completion: (String?, UIImage?) -> Void
        init(completion: @escaping (String?, UIImage?) -> Void) { self.completion = completion }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            guard let image = info[.originalImage] as? UIImage else {
                completion(nil, nil)
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
            completion(filename, image)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completion(nil, nil)
        }
    }
}
