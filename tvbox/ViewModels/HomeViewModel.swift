import Foundation
import SwiftUI

/// 首页 ViewModel
@MainActor
class HomeViewModel: ObservableObject {
    @Published var sorts: [MovieSort.SortData] = []
    @Published var selectedSort: MovieSort.SortData?
    @Published var homeVideos: [Movie.Video] = []
    @Published var categoryVideos: [Movie.Video] = []
    @Published var isLoading = false
    @Published var currentPage = 1
    @Published var hasMore = true
    @Published var errorMessage: String?
    
    private let sourceService = SourceService.shared
    
    /// 加载分类列表
    func loadSorts() async {
        guard let source = ApiConfig.shared.homeSourceBean else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await sourceService.getSort(sourceBean: source)
            
            // 添加"推荐"到首位
            var allSorts = [MovieSort.SortData.home()]
            allSorts.append(contentsOf: result.sorts)
            
            self.sorts = allSorts
            self.homeVideos = result.homeVideos
            
            if selectedSort == nil {
                selectedSort = allSorts.first
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// 选择分类
    func selectSort(_ sort: MovieSort.SortData) {
        selectedSort = sort
        errorMessage = nil
        categoryVideos = []
        currentPage = 1
        hasMore = true
        
        if sort.id == "home" {
            return
        } else {
            Task {
                await loadCategoryVideos(page: 1, sort: sort)
            }
        }
    }
    
    /// 加载分类视频列表
    private func loadCategoryVideos(page: Int, sort: MovieSort.SortData) async {
        guard sort.id != "home" else { return }
        guard let source = ApiConfig.shared.homeSourceBean else { return }
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let videos = try await sourceService.getList(sourceBean: source, sortData: sort, page: page)
            
            // 分类切换过程中，丢弃旧请求结果
            guard selectedSort?.id == sort.id else { return }
            
            if page == 1 {
                categoryVideos = videos
            } else {
                categoryVideos.append(contentsOf: videos)
            }
            currentPage = page
            hasMore = !videos.isEmpty
        } catch {
            guard selectedSort?.id == sort.id else { return }
            errorMessage = error.localizedDescription
        }
    }
    
    /// 加载下一页
    func loadMore() async {
        guard let lastItem = categoryVideos.last else { return }
        await loadMoreIfNeeded(currentItem: lastItem)
    }
    
    /// 当最后一个元素出现时触发加载下一页
    func loadMoreIfNeeded(currentItem: Movie.Video) async {
        guard selectedSort?.id != "home" else { return }
        guard hasMore, !isLoading else { return }
        guard categoryVideos.last?.id == currentItem.id else { return }
        guard let sort = selectedSort else { return }
        
        let nextPage = currentPage + 1
        await loadCategoryVideos(page: nextPage, sort: sort)
    }
    
    /// 刷新
    func refresh() async {
        currentPage = 1
        hasMore = true
        categoryVideos = []
        errorMessage = nil
        await loadSorts()
        
        guard let sort = selectedSort else { return }
        if sort.id == "home" { return }
        
        if let matchedSort = sorts.first(where: { $0.id == sort.id }) {
            selectedSort = matchedSort
            await loadCategoryVideos(page: 1, sort: matchedSort)
        } else if let firstCategory = sorts.first(where: { $0.id != "home" }) {
            selectedSort = firstCategory
            await loadCategoryVideos(page: 1, sort: firstCategory)
        }
    }
}
