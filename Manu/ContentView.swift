import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ReadingStateStore

    @State private var rootURL: URL? = {
        if let path = UserDefaults.standard.string(forKey: "rootFolderPath") {
            return URL(fileURLWithPath: path)
        }
        return nil
    }()

    @State private var selectedFolder: URL?
    @State private var selectedPDF: URL?

    var body: some View {
        NavigationSplitView {
            // Column 1: Folder tree
            FolderNavigatorView(selectedFolder: $selectedFolder, rootURL: $rootURL)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
        } content: {
            // Column 2: Paper list for selected folder
            PaperListView(folderURL: selectedFolder, selectedPDF: $selectedPDF)
                .navigationSplitViewColumnWidth(min: 200, ideal: 260, max: 360)
        } detail: {
            // Column 3: PDF preview
            VStack(spacing: 0) {
                if let pdf = selectedPDF {
                    // Toolbar above PDF
                    HStack {
                        Text(pdf.deletingPathExtension().lastPathComponent)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button {
                            openInSkim(pdf)
                        } label: {
                            Label("Open in Skim", systemImage: "arrow.up.right.square")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help("Open in Skim for annotation")

                        Button {
                            NSWorkspace.shared.activateFileViewerSelecting([pdf])
                        } label: {
                            Image(systemName: "folder")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help("Reveal in Finder")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.windowBackgroundColor))

                    Divider()
                }

                PDFPreviewView(url: selectedPDF)
            }
        }
        .navigationTitle("PaperNav")
    }

    private func openInSkim(_ url: URL) {
        let skimPath = "/Applications/Skim.app"
        if FileManager.default.fileExists(atPath: skimPath) {
            NSWorkspace.shared.open(
                [url],
                withApplicationAt: URL(fileURLWithPath: skimPath),
                configuration: NSWorkspace.OpenConfiguration()
            )
        } else {
            NSWorkspace.shared.open(url)
        }
    }
}
