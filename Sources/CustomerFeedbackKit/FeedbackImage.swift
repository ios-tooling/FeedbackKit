import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Decode to a bounded bitmap and re-encode, dropping source metadata.
enum FeedbackImage {
    static func prepare(_ data: Data) throws -> Data {
        guard data.count <= 20 * 1_024 * 1_024,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 2_000,
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary) else { throw ImageError.invalid }
        let result = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(result, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw ImageError.invalid
        }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.75] as CFDictionary)
        guard CGImageDestinationFinalize(destination), result.length <= FeedbackSubmission.maximumImageBytes else {
            throw ImageError.tooLarge
        }
        return result as Data
    }

    enum ImageError: LocalizedError {
        case invalid, tooLarge
        var errorDescription: String? {
            switch self {
            case .invalid: "This image could not be attached. Choose a different image."
            case .tooLarge: "This image is too large. Choose a smaller screenshot."
            }
        }
    }
}
