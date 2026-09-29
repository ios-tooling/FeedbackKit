import SwiftUI
import UniformTypeIdentifiers
#if os(iOS)
import PhotosUI
#else
import AppKit
#endif

struct FeedbackAttachmentsSection: View {
    @Bindable var model: FeedbackFormModel
    #if os(iOS)
    @State private var selection: [PhotosPickerItem] = []
    #else
    @State private var pickingFiles = false
    #endif

    var body: some View {
        Section {
            ForEach(model.screenshots) { screenshot in
                HStack {
                    #if os(iOS)
                    if let image = UIImage(data: screenshot.data) {
                        Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 150)
                    }
                    #else
                    if let image = NSImage(data: screenshot.data) {
                        Image(nsImage: image).resizable().scaledToFit().frame(maxHeight: 150)
                    }
                    #endif
                    Button("Remove", role: .destructive) {
                        model.screenshots.removeAll { $0.id == screenshot.id }
                    }
                }
            }
            if model.screenshots.count < FeedbackSubmission.maximumScreenshots {
                #if os(iOS)
                PhotosPicker(selection: $selection, maxSelectionCount: FeedbackSubmission.maximumScreenshots - model.screenshots.count, matching: .images) {
                    Label("Attach Screenshots", systemImage: "photo")
                }
                .disabled(model.loadingImages)
                .onChange(of: selection) { _, items in
                    guard !items.isEmpty else { return }
                    model.loadingImages = true
                    Task {
                        defer { model.loadingImages = false; selection = [] }
                        do {
                            var images: [FeedbackScreenshot] = []
                            for item in items {
                                guard let data = try await item.loadTransferable(type: Data.self) else { throw FeedbackImage.ImageError.invalid }
                                let prepared = try await Task.detached { try FeedbackImage.prepare(data) }.value
                                images.append(FeedbackScreenshot(data: prepared))
                            }
                            model.screenshots.append(contentsOf: images)
                        } catch { model.error = error.localizedDescription }
                    }
                }
                #else
                Button("Attach Screenshots", systemImage: "photo") { pickingFiles = true }
                    .fileImporter(isPresented: $pickingFiles, allowedContentTypes: [.image], allowsMultipleSelection: true) { result in
                        do {
                            let urls = try result.get()
                            guard urls.count + model.screenshots.count <= FeedbackSubmission.maximumScreenshots else {
                                model.error = "Attach up to three screenshots."
                                return
                            }
                            var images: [FeedbackScreenshot] = []
                            for url in urls {
                                let access = url.startAccessingSecurityScopedResource()
                                defer { if access { url.stopAccessingSecurityScopedResource() } }
                                let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                                guard size <= 20 * 1_024 * 1_024 else { throw FeedbackImage.ImageError.tooLarge }
                                images.append(FeedbackScreenshot(data: try FeedbackImage.prepare(Data(contentsOf: url))))
                            }
                            model.screenshots.append(contentsOf: images)
                        } catch { model.error = error.localizedDescription }
                    }
                #endif
            }
            if model.loadingImages { ProgressView("Preparing screenshots…") }
        } header: { Text("Screenshots (Optional)") }
        footer: { Text("Attach up to three images. You can review and remove them before sending.") }
    }
}
