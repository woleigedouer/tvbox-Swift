import Foundation
import SwiftUI

struct PlaybackQualityOption: Identifiable, Hashable {
    static let autoIdentifier = "auto"
    let id: String
    let name: String
    let url: String
    
    var isAuto: Bool {
        id == Self.autoIdentifier
    }
    
    static func auto(url: String) -> PlaybackQualityOption {
        PlaybackQualityOption(id: autoIdentifier, name: "自动", url: url)
    }
}

/// 详情页 ViewModel
@MainActor
class DetailViewModel: ObservableObject {
    @Published var vodInfo: VodInfo?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFlag: String = ""
    @Published var selectedEpisodeIndex: Int = 0
    @Published var isPlaying = false
    @Published var playUrl: String?
    @Published var resumeSeconds: Double = 0
    @Published var qualityOptions: [PlaybackQualityOption] = []
    @Published var selectedQualityId: String = PlaybackQualityOption.autoIdentifier
    private var realtimeProgressSeconds: Double = 0
    
    private let sourceService = SourceService.shared
    private let network = NetworkManager.shared
    private var qualityBaseEpisodeURL: String = ""
    private var qualityOptionCache: [String: [PlaybackQualityOption]] = [:]
    private var qualityResolveTask: Task<Void, Never>?
    private var qualityResolveToken = UUID()
    
    /// 加载视频详情
    func loadDetail(video: Movie.Video) async {
        guard let source = ApiConfig.shared.getSource(key: video.sourceKey)
                ?? ApiConfig.shared.homeSourceBean else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            if let info = try await sourceService.getDetail(sourceBean: source, vodId: video.id) {
                self.vodInfo = info
                self.selectedFlag = info.playFlag
                self.selectedEpisodeIndex = info.playIndex
                self.resumeSeconds = 0
                self.realtimeProgressSeconds = 0
                if let episode = info.currentEpisode {
                    updateQualityOptions(for: episode.url, resetSelection: true)
                } else {
                    resetQualityState()
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// 选择线路
    func selectFlag(_ flag: String) {
        guard selectedFlag != flag else { return }
        let currentIndex = selectedEpisodeIndex
        
        selectedFlag = flag
        vodInfo?.playFlag = flag
        resumeSeconds = 0
        realtimeProgressSeconds = 0
        
        let episodes = vodInfo?.playUrlMap[flag] ?? []
        guard !episodes.isEmpty else {
            selectedEpisodeIndex = 0
            vodInfo?.playIndex = 0
            resetQualityState()
            return
        }
        
        let targetIndex = min(max(currentIndex, 0), episodes.count - 1)
        selectedEpisodeIndex = targetIndex
        vodInfo?.playIndex = targetIndex
        let episodeURL = episodes[targetIndex].url
        updateQualityOptions(for: episodeURL, resetSelection: true)
        
        // 播放中切线路时，立即切换到新线路对应剧集
        if isPlaying {
            playUrl = selectedPlayableURL(fallback: episodeURL)
        }
    }
    
    /// 选择剧集并播放
    func selectEpisode(index: Int) {
        guard selectedEpisodeIndex != index || !isPlaying else { return }
        selectedEpisodeIndex = index
        vodInfo?.playIndex = index
        resumeSeconds = 0
        realtimeProgressSeconds = 0
        
        if let episode = vodInfo?.currentEpisode {
            let shouldResetQuality = qualityBaseEpisodeURL != episode.url
            updateQualityOptions(for: episode.url, resetSelection: shouldResetQuality)
            playUrl = selectedPlayableURL(fallback: episode.url)
            isPlaying = true
        }
    }
    
    /// 应用历史续播状态并自动继续播放
    func applyPlaybackState(_ state: VodPlaybackState) {
        guard let info = vodInfo, !info.playFlags.isEmpty else { return }
        
        let fallbackFlag = info.playFlag.isEmpty ? info.playFlags[0] : info.playFlag
        let targetFlag = info.playFlags.contains(state.flag) ? state.flag : fallbackFlag
        
        selectedFlag = targetFlag
        vodInfo?.playFlag = targetFlag
        
        let episodes = vodInfo?.playUrlMap[targetFlag] ?? []
        guard !episodes.isEmpty else { return }
        
        let targetIndex = min(max(state.episodeIndex, 0), episodes.count - 1)
        selectedEpisodeIndex = targetIndex
        vodInfo?.playIndex = targetIndex
        
        let progress = max(0, state.progressSeconds)
        resumeSeconds = progress
        realtimeProgressSeconds = progress
        let episodeURL = episodes[targetIndex].url
        updateQualityOptions(for: episodeURL, resetSelection: true)
        playUrl = selectedPlayableURL(fallback: episodeURL)
        isPlaying = true
    }
    
    /// 选择清晰度
    func selectQuality(_ option: PlaybackQualityOption) {
        guard qualityOptions.contains(option) else { return }
        selectedQualityId = option.id
        guard isPlaying else { return }
        
        let targetURL = option.url.isEmpty ? qualityBaseEpisodeURL : option.url
        guard !targetURL.isEmpty, playUrl != targetURL else { return }
        
        let progress = max(currentPlaybackSeconds(), 0)
        resumeSeconds = progress
        realtimeProgressSeconds = progress
        playUrl = targetURL
    }
    
    /// 播放器时间回调
    func updatePlaybackProgress(seconds: Double) {
        guard seconds.isFinite else { return }
        realtimeProgressSeconds = max(seconds, 0)
    }
    
    /// 当前实时进度（不触发 UI 高频刷新）
    func currentPlaybackSeconds() -> Double {
        max(realtimeProgressSeconds, resumeSeconds)
    }
    
    /// 仅在必要时同步快照到可观察状态
    func commitPlaybackProgressSnapshot() {
        let snapshot = max(realtimeProgressSeconds, 0)
        if abs(snapshot - resumeSeconds) >= 1 {
            resumeSeconds = snapshot
        }
    }
    
    /// 播放下一集
    func playNext() -> Bool {
        guard let info = vodInfo else { return false }
        let episodes = info.currentEpisodes
        if selectedEpisodeIndex + 1 < episodes.count {
            selectEpisode(index: selectedEpisodeIndex + 1)
            return true
        }
        return false
    }
    
    /// 播放上一集
    func playPrevious() -> Bool {
        if selectedEpisodeIndex > 0 {
            selectEpisode(index: selectedEpisodeIndex - 1)
            return true
        }
        return false
    }
    
    /// 当前剧集列表
    var currentEpisodes: [VodInfo.Episode] {
        vodInfo?.playUrlMap[selectedFlag] ?? []
    }
    
    /// 可选线路列表
    var flags: [String] {
        vodInfo?.playFlags ?? []
    }
    
    /// 是否存在可选清晰度
    var hasQualityChoices: Bool {
        qualityOptions.count > 1
    }
    
    private func selectedPlayableURL(fallback: String) -> String {
        let selected = qualityOptions.first(where: { $0.id == selectedQualityId })?.url
        if let selected, !selected.isEmpty {
            return selected
        }
        return fallback
    }
    
    private func resetQualityState() {
        qualityResolveTask?.cancel()
        qualityResolveTask = nil
        qualityBaseEpisodeURL = ""
        qualityOptions = []
        selectedQualityId = PlaybackQualityOption.autoIdentifier
        qualityResolveToken = UUID()
    }
    
    private func updateQualityOptions(for episodeURL: String, resetSelection: Bool) {
        let trimmedEpisodeURL = episodeURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEpisodeURL.isEmpty else {
            resetQualityState()
            return
        }
        
        qualityResolveTask?.cancel()
        qualityResolveTask = nil
        
        let autoOption = PlaybackQualityOption.auto(url: trimmedEpisodeURL)
        let previousSelected = selectedQualityId
        
        qualityBaseEpisodeURL = trimmedEpisodeURL
        if resetSelection {
            selectedQualityId = PlaybackQualityOption.autoIdentifier
        }
        
        qualityOptions = [autoOption]
        
        if let cached = qualityOptionCache[trimmedEpisodeURL] {
            qualityOptions = cached
            if resetSelection || !cached.contains(where: { $0.id == selectedQualityId }) {
                selectedQualityId = PlaybackQualityOption.autoIdentifier
            } else if previousSelected != selectedQualityId && cached.contains(where: { $0.id == previousSelected }) {
                selectedQualityId = previousSelected
            }
            return
        }
        
        let token = UUID()
        qualityResolveToken = token
        qualityResolveTask = Task { [trimmedEpisodeURL, resetSelection, previousSelected] in
            let resolved = await resolveQualityOptions(for: trimmedEpisodeURL)
            guard !Task.isCancelled else { return }
            guard qualityResolveToken == token, qualityBaseEpisodeURL == trimmedEpisodeURL else { return }
            guard !resolved.isEmpty else { return }
            
            qualityOptionCache[trimmedEpisodeURL] = resolved
            qualityOptions = resolved
            
            if resetSelection {
                selectedQualityId = PlaybackQualityOption.autoIdentifier
            } else if resolved.contains(where: { $0.id == selectedQualityId }) {
                // 当前选择仍有效，保持不变
            } else if resolved.contains(where: { $0.id == previousSelected }) {
                selectedQualityId = previousSelected
            } else {
                selectedQualityId = PlaybackQualityOption.autoIdentifier
            }
        }
    }
    
    private func resolveQualityOptions(for episodeURL: String) async -> [PlaybackQualityOption] {
        guard let url = URL(string: episodeURL), Self.looksLikeHLSURL(url) else { return [] }
        guard let playlist = try? await network.getString(from: episodeURL) else { return [] }
        return Self.parseMasterPlaylist(playlist, masterURL: url)
    }
    
    private struct HLSVariant {
        let url: String
        let name: String?
        let height: Int?
        let bandwidth: Int?
    }
    
    private static func looksLikeHLSURL(_ url: URL) -> Bool {
        let lowercased = url.absoluteString.lowercased()
        if lowercased.contains(".m3u8") { return true }
        let ext = url.pathExtension.lowercased()
        return ext == "m3u8" || ext == "m3u"
    }
    
    private static func parseMasterPlaylist(_ content: String, masterURL: URL) -> [PlaybackQualityOption] {
        guard content.localizedCaseInsensitiveContains("#EXT-X-STREAM-INF") else { return [] }
        
        let lines = content.components(separatedBy: .newlines)
        var variants: [HLSVariant] = []
        var index = 0
        
        while index < lines.count {
            let line = lines[index].trimmingCharacters(in: .whitespacesAndNewlines)
            guard line.hasPrefix("#EXT-X-STREAM-INF:") else {
                index += 1
                continue
            }
            
            let attributeString = String(line.dropFirst("#EXT-X-STREAM-INF:".count))
            let attributes = parseAttributeMap(attributeString)
            
            var uri: String?
            var nextIndex = index + 1
            while nextIndex < lines.count {
                let candidate = lines[nextIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                if candidate.isEmpty {
                    nextIndex += 1
                    continue
                }
                if candidate.hasPrefix("#") {
                    nextIndex += 1
                    continue
                }
                uri = candidate
                break
            }
            
            if let uri, !uri.isEmpty {
                let resolvedURL = URL(string: uri, relativeTo: masterURL)?.absoluteURL.absoluteString ?? uri
                let name = attributes["NAME"]?.trimmingCharacters(in: .whitespacesAndNewlines)
                let bandwidth = attributes["BANDWIDTH"].flatMap(Int.init)
                let height: Int?
                if let resolution = attributes["RESOLUTION"] {
                    let parts = resolution.split(separator: "x")
                    if parts.count == 2 {
                        height = Int(parts[1])
                    } else {
                        height = nil
                    }
                } else {
                    height = nil
                }
                
                variants.append(HLSVariant(
                    url: resolvedURL,
                    name: name?.isEmpty == true ? nil : name,
                    height: height,
                    bandwidth: bandwidth
                ))
            }
            
            index = nextIndex + 1
        }
        
        guard !variants.isEmpty else { return [] }
        
        var seenURLs = Set<String>()
        let deduped = variants.filter { variant in
            let inserted = seenURLs.insert(variant.url).inserted
            return inserted
        }
        
        let sorted = deduped.sorted { lhs, rhs in
            let lhsHeight = lhs.height ?? -1
            let rhsHeight = rhs.height ?? -1
            if lhsHeight != rhsHeight {
                return lhsHeight > rhsHeight
            }
            let lhsBandwidth = lhs.bandwidth ?? -1
            let rhsBandwidth = rhs.bandwidth ?? -1
            if lhsBandwidth != rhsBandwidth {
                return lhsBandwidth > rhsBandwidth
            }
            return lhs.url < rhs.url
        }
        
        let masterURLString = masterURL.absoluteString
        var displayNameCount: [String: Int] = [:]
        let options = sorted.enumerated().map { offset, variant -> PlaybackQualityOption in
            let baseName: String
            if let name = variant.name, !name.isEmpty {
                baseName = name
            } else if let height = variant.height {
                baseName = "\(height)p"
            } else if let bandwidth = variant.bandwidth, bandwidth > 0 {
                baseName = "\(bandwidth / 1000)K"
            } else {
                baseName = "清晰度\(offset + 1)"
            }
            
            let newCount = (displayNameCount[baseName] ?? 0) + 1
            displayNameCount[baseName] = newCount
            let finalName = newCount > 1 ? "\(baseName) \(newCount)" : baseName
            
            return PlaybackQualityOption(id: variant.url, name: finalName, url: variant.url)
        }.filter { !$0.url.isEmpty && $0.url != masterURLString }
        
        guard options.count >= 2 else { return [] }
        
        var merged = [PlaybackQualityOption.auto(url: masterURLString)]
        merged.append(contentsOf: options)
        return merged
    }
    
    private static func parseAttributeMap(_ raw: String) -> [String: String] {
        var result: [String: String] = [:]
        let pairs = splitAttributes(raw)
        for pair in pairs {
            let components = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard components.count == 2 else { continue }
            let key = String(components[0]).trimmingCharacters(in: .whitespacesAndNewlines)
            var value = String(components[1]).trimmingCharacters(in: .whitespacesAndNewlines)
            if value.hasPrefix("\""), value.hasSuffix("\""), value.count >= 2 {
                value.removeFirst()
                value.removeLast()
            }
            if !key.isEmpty {
                result[key] = value
            }
        }
        return result
    }
    
    private static func splitAttributes(_ raw: String) -> [String] {
        var parts: [String] = []
        var buffer = ""
        var inQuotes = false
        
        for char in raw {
            if char == "\"" {
                inQuotes.toggle()
                buffer.append(char)
                continue
            }
            
            if char == "," && !inQuotes {
                let item = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
                if !item.isEmpty {
                    parts.append(item)
                }
                buffer.removeAll(keepingCapacity: true)
                continue
            }
            
            buffer.append(char)
        }
        
        let tail = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tail.isEmpty {
            parts.append(tail)
        }
        return parts
    }
}
