import SwiftUI

struct PaperListView: View {
    let folderURL: URL?
    @Binding var selectedPDF: URL?
    @EnvironmentObject var store: ReadingStateStore

    @State private var papers: [URL] = []
    @State private var searchText: String = ""

    private var filtered: [URL] {
        if searchText.isEmpty { return papers }
        return papers.filter {
            $0.deletingPathExtension().lastPathComponent
                .localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            if let folder = folderURL {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(folder.lastPathComponent)
                            .font(.system(size: 13, weight: .semibold))
                        Text("\(papers.count) paper\(papers.count == 1 ? "" : "s")")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        NSWorkspace.shared.open(folder)
                    } label: {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .help("Open in Finder")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    TextField("Filter…", text: $searchText)
                        .font(.system(size: 12))
                        .textFieldStyle(.plain)
                }
                .padding(6)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .padding(.horizontal, 8)
                .padding(.bottom, 6)

                Divider()

                // Paper rows
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered, id: \.path) { pdf in
                            PaperRowView(
                                url: pdf,
                                isSelected: selectedPDF == pdf,
                                lastPage: store.lastPage(for: pdf.path)
                            )
                            .onTapGesture { selectedPDF = pdf }
                            .contextMenu {
                                Button("Open in Skim") { openInSkim(pdf) }
                                Button("Open in Preview") { openInPreview(pdf) }
                                Button("Reveal in Finder") {
                                    NSWorkspace.shared.activateFileViewerSelecting([pdf])
                                }
                            }
                        }
                    }
                }
            } else {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Select a folder")
                        .foregroundColor(.secondary)
                        .font(.system(size: 13))
                }
                Spacer()
            }
        }
        .onChange(of: folderURL) { oldValue, newValue in
            loadPapers()
        }
        .onAppear { loadPapers() }
    }

    private func loadPapers() {
        guard let url = folderURL else { papers = []; return }
        let fm = FileManager.default
        papers = (try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: .skipsHiddenFiles
        ))?.filter { $0.pathExtension.lowercased() == "pdf" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent } ?? []
    }

    private func openInSkim(_ url: URL) {
        let skim = URL(fileURLWithPath: "/Applications/Skim.app")
        if FileManager.default.fileExists(atPath: skim.path) {
            NSWorkspace.shared.open([url], withApplicationAt: skim, configuration: NSWorkspace.OpenConfiguration())
        } else {
            NSWorkspace.shared.open(url)
        }
    }

    private func openInPreview(_ url: URL) {
        let preview = URL(fileURLWithPath: "/System/Applications/Preview.app")
        NSWorkspace.shared.open([url], withApplicationAt: preview, configuration: NSWorkspace.OpenConfiguration())
    }
}

struct PaperRowView: View {
    let url: URL
    let isSelected: Bool
    let lastPage: Int

    private var title: String {
        url.deletingPathExtension().lastPathComponent
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 14))
                .foregroundColor(isSelected ? .white : Color.accentColor.opacity(0.8))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(2)

                if lastPage > 0 {
                    Text("Last read: p.\(lastPage + 1)")
                        .font(.system(size: 10))
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .contentShape(Rectangle())
    }
}
