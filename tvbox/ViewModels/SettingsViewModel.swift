import Foundation
import SwiftUI

/// 设置 ViewModel
@MainActor
class SettingsViewModel: ObservableObject {
    @Published var apiUrl: String = ""
    @Published var isLoadingConfig = false
    @Published var configError: String?
    @Published var configSuccess = false
    @Published var apiHistory: [String] = []
    @Published var playerEngine: PlayerEngine = .system
    @Published var decodeMode: VideoDecodeMode = .auto
    @Published var vlcBufferMode: VLCBufferMode = .defaultMode
    @Published var playTimeStep: Int = 10
    @Published var cacheSizeString: String = "0 KB"
    
    let playTimeStepOptions: [Int] = [5, 10, 15, 30, 60]
    let playerEngineOptions: [PlayerEngine] = PlayerEngine.availableEngines
    let decodeModeOptions: [VideoDecodeMode] = VideoDecodeMode.allCases
    let vlcBufferModeOptions: [VLCBufferMode] = VLCBufferMode.allCases
    
    init() {
        apiUrl = UserDefaults.standard.string(forKey: HawkConfig.API_URL) ?? ""
        loadApiHistory()
        playerEngine = PlayerEngine.fromStoredValue(
            UserDefaults.standard.integer(forKey: HawkConfig.PLAY_TYPE)
        )
        decodeMode = VideoDecodeMode.fromStoredValue(
            UserDefaults.standard.integer(forKey: HawkConfig.PLAY_DECODE_MODE)
        )
        vlcBufferMode = VLCBufferMode.fromStoredValue(
            UserDefaults.standard.integer(forKey: HawkConfig.PLAY_VLC_BUFFER_MODE)
        )
        
        let savedStep = UserDefaults.standard.integer(forKey: HawkConfig.PLAY_TIME_STEP)
        playTimeStep = savedStep > 0 ? savedStep : 10
        refreshCacheSize()
    }
    
    /// 加载配置
    func loadConfig() async {
        let trimmed = apiUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            configError = "请输入配置地址"
            return
        }
        
        isLoadingConfig = true
        configError = nil
        configSuccess = false
        
        do {
            try await ApiConfig.shared.loadConfig(from: trimmed)
            UserDefaults.standard.set(trimmed, forKey: HawkConfig.API_URL)
            addToApiHistory(trimmed)
            configSuccess = true
        } catch {
            configError = error.localizedDescription
        }
        
        isLoadingConfig = false
    }
    
    // MARK: - API 历史
    
    private func loadApiHistory() {
        apiHistory = UserDefaults.standard.stringArray(forKey: "api_history") ?? []
    }
    
    private func addToApiHistory(_ url: String) {
        apiHistory.removeAll { $0 == url }
        apiHistory.insert(url, at: 0)
        if apiHistory.count > 10 {
            apiHistory = Array(apiHistory.prefix(10))
        }
        UserDefaults.standard.set(apiHistory, forKey: "api_history")
    }
    
    func removeApiHistory(_ url: String) {
        apiHistory.removeAll { $0 == url }
        UserDefaults.standard.set(apiHistory, forKey: "api_history")
    }
    
    /// 清除所有缓存
    func clearCache() {
        URLCache.shared.removeAllCachedResponses()
        ImageLoader.shared.clearCache()
        ImageCache.shared.clear()
        refreshCacheSize()
    }
    
    /// 设置快进步长
    func setPlayTimeStep(_ step: Int) {
        guard step > 0 else { return }
        playTimeStep = step
        UserDefaults.standard.set(step, forKey: HawkConfig.PLAY_TIME_STEP)
    }
    
    /// 设置播放器内核
    func setPlayerEngine(_ engine: PlayerEngine) {
        guard playerEngineOptions.contains(engine) else { return }
        playerEngine = engine
        UserDefaults.standard.set(engine.rawValue, forKey: HawkConfig.PLAY_TYPE)
    }
    
    /// 设置视频解码模式
    func setDecodeMode(_ mode: VideoDecodeMode) {
        guard decodeModeOptions.contains(mode) else { return }
        decodeMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: HawkConfig.PLAY_DECODE_MODE)
    }

    /// 设置 VLC 缓冲策略
    func setVLCBufferMode(_ mode: VLCBufferMode) {
        guard vlcBufferModeOptions.contains(mode) else { return }
        vlcBufferMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: HawkConfig.PLAY_VLC_BUFFER_MODE)
    }
    
    private func refreshCacheSize() {
        let sharedDisk = URLCache.shared.currentDiskUsage
        let imageDisk = ImageLoader.shared.cacheUsage.disk
        cacheSizeString = Self.formatSize(bytes: sharedDisk + imageDisk)
    }
    
    private static func formatSize(bytes: Int) -> String {
        let size = max(0, bytes)
        if size < 1024 * 1024 {
            return String(format: "%.1f KB", Double(size) / 1024.0)
        }
        return String(format: "%.1f MB", Double(size) / 1024.0 / 1024.0)
    }
}
