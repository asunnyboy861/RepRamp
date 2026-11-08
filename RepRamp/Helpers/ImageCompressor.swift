import UIKit

enum ImageCompressor {
    static func jpeg(from image: UIImage, maxDimension: CGFloat = 1024) -> Data? {
        let ratio = min(1.0, maxDimension / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: size)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: 0.7)
    }
}
