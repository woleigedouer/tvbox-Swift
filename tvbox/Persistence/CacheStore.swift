import Foundation
import SwiftData

/// SwiftData 持久化模型 - 对应 Android 版 Room 数据库

/// 单部剧的续播状态
struct VodPlaybackState: Codable {
    var flag: String
    var episodeIndex: Int
    var progressSeconds: Double
}

/// 视频收藏
@Model
final class VodCollect {
    var vodId: String = ""
    var vodName: String = ""
    var vodPic: String = ""
    var sourceKey: String = ""
    var updateTime: Date = Date()
    
    init(vodId: String, vodName: String, vodPic: String, sourceKey: String) {
        self.vodId = vodId
        self.vodName = vodName
        self.vodPic = vodPic
        self.sourceKey = sourceKey
        self.updateTime = Date()
    }
}

/// 播放历史记录
@Model
final class VodRecord {
    var vodId: String = ""
    var vodName: String = ""
    var vodPic: String = ""
    var sourceKey: String = ""
    var playNote: String = ""      // 如 "第5集 03:45"
    var dataJson: String = ""      // 续播状态 JSON（VodPlaybackState）
    var updateTime: Date = Date()
    
    init(vodId: String, vodName: String, vodPic: String, sourceKey: String, playNote: String = "") {
        self.vodId = vodId
        self.vodName = vodName
        self.vodPic = vodPic
        self.sourceKey = sourceKey
        self.playNote = playNote
        self.updateTime = Date()
    }
}

/// 通用缓存
@Model
final class CacheItem {
    @Attribute(.unique) var key: String = ""
    var value: String = ""
    var updateTime: Date = Date()
    
    init(key: String, value: String) {
        self.key = key
        self.value = value
        self.updateTime = Date()
    }
}

/// 缓存管理器
actor CacheStore {
    static let shared = CacheStore()
    
    private init() {}
    
    @MainActor
    func addCollect(_ video: Movie.Video, context: ModelContext) {
        // 先检查是否已存在
        let vodId = video.id
        let sourceKey = video.sourceKey
        let predicate = #Predicate<VodCollect> { item in
            item.vodId == vodId && item.sourceKey == sourceKey
        }
        let descriptor = FetchDescriptor<VodCollect>(predicate: predicate)
        
        if let existing = try? context.fetch(descriptor), !existing.isEmpty {
            return // 已收藏
        }
        
        let collect = VodCollect(
            vodId: video.id,
            vodName: video.name,
            vodPic: video.pic,
            sourceKey: video.sourceKey
        )
        context.insert(collect)
        try? context.save()
    }
    
    @MainActor
    func removeCollect(vodId: String, sourceKey: String, context: ModelContext) {
        let predicate = #Predicate<VodCollect> { item in
            item.vodId == vodId && item.sourceKey == sourceKey
        }
        let descriptor = FetchDescriptor<VodCollect>(predicate: predicate)
        if let items = try? context.fetch(descriptor) {
            for item in items {
                context.delete(item)
            }
            try? context.save()
        }
    }
    
    @MainActor
    func isCollected(vodId: String, sourceKey: String, context: ModelContext) -> Bool {
        let predicate = #Predicate<VodCollect> { item in
            item.vodId == vodId && item.sourceKey == sourceKey
        }
        let descriptor = FetchDescriptor<VodCollect>(predicate: predicate)
        return (try? context.fetchCount(descriptor)) ?? 0 > 0
    }
    
    @MainActor
    func addRecord(
        _ video: Movie.Video,
        playNote: String,
        playbackState: VodPlaybackState? = nil,
        context: ModelContext
    ) {
        let vodId = video.id
        let sourceKey = video.sourceKey
        let record = fetchRecord(vodId: vodId, sourceKey: sourceKey, context: context)
        let encodedState = Self.encodePlaybackState(playbackState)
        
        // 更新或插入
        if let record {
            record.playNote = playNote
            if let encodedState {
                record.dataJson = encodedState
            }
            record.updateTime = Date()
        } else {
            let record = VodRecord(
                vodId: video.id,
                vodName: video.name,
                vodPic: video.pic,
                sourceKey: video.sourceKey,
                playNote: playNote
            )
            if let encodedState {
                record.dataJson = encodedState
            }
            context.insert(record)
        }
        try? context.save()
    }
    
    @MainActor
    func getPlaybackState(vodId: String, sourceKey: String, context: ModelContext) -> VodPlaybackState? {
        guard let record = fetchRecord(vodId: vodId, sourceKey: sourceKey, context: context) else {
            return nil
        }
        return Self.decodePlaybackState(record.dataJson)
    }
    
    @MainActor
    func clearHistory(context: ModelContext) {
        do {
            try context.delete(model: VodRecord.self)
            try context.save()
        } catch {
            print("清空历史记录失败: \(error)")
        }
    }
    
    @MainActor
    private func fetchRecord(vodId: String, sourceKey: String, context: ModelContext) -> VodRecord? {
        let predicate = #Predicate<VodRecord> { item in
            item.vodId == vodId && item.sourceKey == sourceKey
        }
        let descriptor = FetchDescriptor<VodRecord>(predicate: predicate)
        guard let records = try? context.fetch(descriptor) else { return nil }
        return records.first
    }
    
    private nonisolated static func encodePlaybackState(_ state: VodPlaybackState?) -> String? {
        guard let state else { return nil }
        guard let data = try? JSONEncoder().encode(state) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private nonisolated static func decodePlaybackState(_ json: String) -> VodPlaybackState? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(VodPlaybackState.self, from: data)
    }
}
