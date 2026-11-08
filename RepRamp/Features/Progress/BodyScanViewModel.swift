import SwiftUI
import PhotosUI
import UIKit

@MainActor
final class BodyScanViewModel: ObservableObject {
    @Published var photoItem: PhotosPickerItem?
    @Published var imageData: Data?
    @Published var preview: UIImage?
    @Published var result: BodyScanResult?
    @Published var isAnalyzing = false
    @Published var errorMessage: String?

    func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        errorMessage = nil
        guard let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
            errorMessage = "That photo could not be read. Try another one."
            return
        }
        preview = image
        imageData = ImageCompressor.jpeg(from: image)
        result = nil
    }

    func analyze() async {
        guard let imageData else { return }
        isAnalyzing = true
        errorMessage = nil
        do {
            result = try await AIGateway.shared.analyzeBodyScan(image: imageData)
        } catch {
            errorMessage = error.localizedDescription
        }
        isAnalyzing = false
    }

    func reset() {
        photoItem = nil
        imageData = nil
        preview = nil
        result = nil
        errorMessage = nil
    }
}
