import SwiftUI
import PDFKit

// MARK: - SwiftUI wrapper

struct PDFPreviewView: View {
    let url: URL?
    @EnvironmentObject var store: ReadingStateStore

    var body: some View {
        if let url {
            PDFKitView(url: url, store: store)
                .id(url) // force recreation when PDF changes
        } else {
            ZStack {
                Color(NSColor.controlBackgroundColor)
                VStack(spacing: 12) {
                    Image(systemName: "doc.richtext")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.3))
                    Text("Select a paper to preview")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - NSViewRepresentable

struct PDFKitView: NSViewRepresentable {
    let url: URL
    let store: ReadingStateStore

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = NSColor.controlBackgroundColor

        if let doc = PDFDocument(url: url) {
            view.document = doc
            // Restore last page
            let lastPage = store.lastPage(for: url.path)
            if lastPage > 0, let page = doc.page(at: lastPage) {
                view.go(to: page)
            }
        }

        // Observe page changes to save state
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: view
        )

        return view
    }

    func updateNSView(_ nsView: PDFView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url, store: store)
    }

    class Coordinator: NSObject {
        let url: URL
        let store: ReadingStateStore

        init(url: URL, store: ReadingStateStore) {
            self.url = url
            self.store = store
        }

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPage = pdfView.currentPage,
                  let doc = pdfView.document else { return }
            let index = doc.index(for: currentPage)
            store.setPage(index, for: url.path)
        }
    }
}
