import Foundation

/// 视频详情模型 - 对应 Android 版 VodInfo.java
struct VodInfo: Codable, Identifiable {
    var id: String
    var name: String = ""
    var pic: String = ""
    var note: String = ""
    var year: String = ""
    var area: String = ""
    var typeName: String = ""
    var director: String = ""
    var actor: String = ""
    var des: String = ""
    var sourceKey: String = ""
    
    /// 播放来源（线路）列表
    var playFlags: [String] = []
    /// key: flag名称, value: 剧集列表
    var playUrlMap: [String: [Episode]] = [:]
    
    var playFlag: String = ""   // 当前选中线路
    var playIndex: Int = 0      // 当前播放剧集索引
    
    /// 单集信息
    struct Episode: Codable, Identifiable, Hashable {
        var id: String { name }
        let name: String
        let url: String
        
        init(name: String, url: String) {
            self.name = name
            self.url = url
        }
    }
    
    /// 从 Movie.Video 和详情数据构建
    static func from(video: Movie.Video, playFrom: String, playUrl: String) -> VodInfo {
        var info = VodInfo(id: video.id)
        info.name = video.name
        info.pic = video.pic
        info.note = video.note
        info.year = video.year
        info.area = video.area
        info.typeName = video.type
        info.director = video.director
        info.actor = video.actor
        info.des = video.des.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        info.sourceKey = video.sourceKey
        
        // 解析播放列表
        // playFrom 格式: "线路1$$$线路2$$$线路3"
        // playUrl  格式: "第1集$url1#第2集$url2$$$第1集$url3#第2集$url4"
        let flags = playFrom.components(separatedBy: "$$$").filter { !$0.isEmpty }
        let urls = playUrl.components(separatedBy: "$$$")
        
        info.playFlags = flags
        for (i, flag) in flags.enumerated() {
            if i < urls.count {
                let episodes = urls[i].components(separatedBy: "#").compactMap { item -> Episode? in
                    let parts = item.components(separatedBy: "$")
                    guard parts.count >= 2 else { return nil }
                    return Episode(name: parts[0], url: parts[1])
                }
                info.playUrlMap[flag] = episodes
            }
        }
        
        if let first = flags.first {
            info.playFlag = first
        }
        
        return info
    }
    
    var currentEpisodes: [Episode] {
        playUrlMap[playFlag] ?? []
    }
    
    var currentEpisode: Episode? {
        let eps = currentEpisodes
        guard playIndex >= 0, playIndex < eps.count else { return nil }
        return eps[playIndex]
    }
}
