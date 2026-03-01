import Foundation
import SwiftUI

/// 搜索 ViewModel
@MainActor
class SearchViewModel: ObservableObject {
    @Published var keyword: String = ""
    @Published var results: [Movie.Video] = []
    @Published var isSearching = false
    @Published var searchHistory: [String] = []
    @Published var errorMessage: String?
    
    private let sourceService = SourceService.shared
    
    init() {
        loadSearchHistory()
    }
    
    /// 执行搜索
    func search() async {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        results = []
        
        // 保存搜索历史
        addToHistory(trimmed)
        
        let videos = await sourceService.searchAll(keyword: trimmed)
        self.results = videos
        
        if videos.isEmpty {
            errorMessage = "未找到相关内容"
        }
        
        isSearching = false
    }
    
    /// 在指定源搜索
    func searchInSource(_ source: SourceBean) async {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        isSearching = true
        
        do {
            let videos = try await sourceService.search(sourceBean: source, keyword: trimmed)
            self.results = videos
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSearching = false
    }
    
    // MARK: - 搜索历史
    
    private func loadSearchHistory() {
        searchHistory = UserDefaults.standard.stringArray(forKey: HawkConfig.SEARCH_HISTORY) ?? []
    }
    
    private func addToHistory(_ keyword: String) {
        searchHistory.removeAll { $0 == keyword }
        searchHistory.insert(keyword, at: 0)
        if searchHistory.count > 20 {
            searchHistory = Array(searchHistory.prefix(20))
        }
        UserDefaults.standard.set(searchHistory, forKey: HawkConfig.SEARCH_HISTORY)
    }
    
    func clearHistory() {
        searchHistory = []
        UserDefaults.standard.removeObject(forKey: HawkConfig.SEARCH_HISTORY)
    }
    
    func removeFromHistory(_ keyword: String) {
        searchHistory.removeAll { $0 == keyword }
        UserDefaults.standard.set(searchHistory, forKey: HawkConfig.SEARCH_HISTORY)
    }
}
