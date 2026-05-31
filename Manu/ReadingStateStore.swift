import Foundation
import Combine

class ReadingStateStore: ObservableObject {
    private let key = "readingStates"

    // path -> last page index (0-based)
    @Published var lastPages: [String: Int] = [:]

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            lastPages = decoded
        }
    }

    func setPage(_ page: Int, for path: String) {
        lastPages[path] = page
        save()
    }

    func lastPage(for path: String) -> Int {
        lastPages[path] ?? 0
    }

    private func save() {
        if let data = try? JSONEncoder().encode(lastPages) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
