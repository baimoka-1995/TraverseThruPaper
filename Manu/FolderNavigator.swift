import SwiftUI
import Combine

// MARK: - Model

class FolderNode: ObservableObject, Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    @Published var children: [FolderNode] = []
    @Published var isExpanded: Bool = false

    var pdfFiles: [URL] {
        (try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: .skipsHiddenFiles
        ))?.filter { $0.pathExtension.lowercased() == "pdf" } ?? []
    }

    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        loadChildren()
    }

    func loadChildren() {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        ) else { return }

        children = contents.filter { item in
            (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
        }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }
        .map { FolderNode(url: $0) }
    }

    func refresh() {
        loadChildren()
        for child in children { child.refresh() }
    }
}

// MARK: - Sidebar View

struct FolderNavigatorView: View {
    @Binding var selectedFolder: URL?
    @Binding var rootURL: URL?
    @State private var rootNode: FolderNode?

    var body: some View {
        VStack(spacing: 0) {
            // Root picker
            HStack {
                Text(rootURL?.lastPathComponent ?? "Choose Root…")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Spacer()
                Button {
                    pickRoot()
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            if let node = rootNode {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        FolderRowView(node: node, selectedFolder: $selectedFolder, depth: 0)
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Spacer()
                Text("No folder selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .onChange(of: rootURL) { url in
            if let url {
                rootNode = FolderNode(url: url)
            }
        }
    }

    private func pickRoot() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select your papers root folder"
        if panel.runModal() == .OK {
            rootURL = panel.url
            if let url = panel.url {
                rootNode = FolderNode(url: url)
                UserDefaults.standard.set(url.path, forKey: "rootFolderPath")
            }
        }
    }
}

// MARK: - Folder Row

struct FolderRowView: View {
    @ObservedObject var node: FolderNode
    @Binding var selectedFolder: URL?
    let depth: Int

    private var isSelected: Bool { selectedFolder == node.url }
    private var hasChildren: Bool { !node.children.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                // indent
                Spacer().frame(width: CGFloat(depth) * 12)

                // expand toggle
                if hasChildren {
                    Image(systemName: node.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 12)
                        .onTapGesture { node.isExpanded.toggle() }
                } else {
                    Spacer().frame(width: 12)
                }

                Image(systemName: "folder.fill")
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : .accentColor)

                Text(node.name)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)

                Spacer()

                // pdf count badge
                let count = node.pdfFiles.count
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                selectedFolder = node.url
                if hasChildren { node.isExpanded.toggle() }
            }
            .padding(.horizontal, 4)

            if node.isExpanded {
                ForEach(node.children) { child in
                    FolderRowView(node: child, selectedFolder: $selectedFolder, depth: depth + 1)
                }
            }
        }
    }
}
