import Foundation
import Testing
import ImageIO
import UniformTypeIdentifiers
@testable import CustomerFeedbackKit

@Suite @MainActor struct FeedbackFormTests {
    @Test func textOnlyAndLimits() {
        let model = FeedbackFormModel()
        model.text = " \n "
        #expect(!model.submission.isValid)
        model.text = "Please add more puzzles."
        #expect(model.submission.isValid)
        #expect(model.submission.screenshots.isEmpty)
        model.text = String(repeating: "x", count: 10_001)
        #expect(!model.submission.isValid)
    }

    @Test func failedSendPreservesDraftAndRetryIdentity() async {
        let model = FeedbackFormModel()
        model.text = "Something went wrong."
        let first = model.submission.id
        await model.send { _ in throw URLError(.notConnectedToInternet) }
        #expect(model.error != nil)
        #expect(!model.sent)
        #expect(!model.sending)
        #expect(model.submission.id == first)
        await model.send { report in #expect(report.id == first) }
        #expect(model.sent)
        model.text = "Changed feedback"
        #expect(model.submission.id != first)
    }

    @Test func invalidImagesRejected() {
        #expect(throws: (any Error).self) { try FeedbackImage.prepare(Data("not an image".utf8)) }
        let tooMany = FeedbackSubmission(id: UUID(), category: .bug, text: "Bug", screenshots: Array(repeating: Data([1]), count: 4))
        #expect(!tooMany.isValid)
    }

    @Test func screenshotPreparationBoundsPixelsAndDropsMetadata() throws {
        let context = try #require(CGContext(data: nil, width: 3000, height: 1000, bitsPerComponent: 8,
                                             bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                             bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        let image = try #require(context.makeImage())
        let input = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(input, UTType.jpeg.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, [kCGImagePropertyExifDictionary: [kCGImagePropertyExifUserComment: "private source metadata"]] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        let output = try FeedbackImage.prepare(input as Data)
        #expect(output.count <= FeedbackSubmission.maximumImageBytes)
        let source = try #require(CGImageSourceCreateWithData(output as CFData, nil))
        let properties = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        #expect(properties[kCGImagePropertyPixelWidth] as? Int == 2000)
        #expect((properties[kCGImagePropertyPixelHeight] as? Int ?? 0) <= 2000)
        let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
        #expect(exif?[kCGImagePropertyExifUserComment] == nil)
    }

    @Test func doesNotSubmitWhileImagesLoad() async {
        let model = FeedbackFormModel()
        model.text = "A bug"
        model.loadingImages = true
        await model.send { _ in Issue.record("Submitted before image loading finished") }
        #expect(!model.sent)
    }
}
