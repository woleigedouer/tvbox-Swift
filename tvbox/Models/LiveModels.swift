import Foundation

/// 直播相关模型 - 对应 Android 版 LiveChannel*.java / Epginfo.java

/// 直播频道分组
struct LiveChannelGroup: Codable, Identifiable, Hashable {
    var id: String { groupName }
    var groupName: String = ""
    var groupIndex: Int = 0
    var channels: [LiveChannelItem] = []
    var isPassword: Bool = false
    
    init(groupName: String = "", groupIndex: Int = 0) {
        self.groupName = groupName
        self.groupIndex = groupIndex
    }
}

/// 直播频道
struct LiveChannelItem: Codable, Identifiable, Hashable {
    var id: String { "\(channelName)_\(channelIndex)" }
    var channelName: String = ""
    var channelIndex: Int = 0
    var channelUrls: [String] = []
    var sourceIndex: Int = 0
    var sourceNum: Int { channelUrls.count }
    var logo: String = ""
    
    init(channelName: String = "", channelIndex: Int = 0) {
        self.channelName = channelName
        self.channelIndex = channelIndex
    }
    
    var currentUrl: String? {
        guard sourceIndex >= 0, sourceIndex < channelUrls.count else { return channelUrls.first }
        return channelUrls[sourceIndex]
    }
    
    mutating func nextSource() {
        if channelUrls.count > 0 {
            sourceIndex = (sourceIndex + 1) % channelUrls.count
        }
    }
}

/// EPG 节目信息
struct Epginfo: Codable, Identifiable, Hashable {
    var id: String { "\(title)_\(startTime)" }
    var title: String = ""
    var startTime: String = ""
    var endTime: String = ""
    var index: Int = 0
    
    var isLive: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let start = formatter.date(from: startTime),
              let end = formatter.date(from: endTime) else { return false }
        
        let now = formatter.date(from: formatter.string(from: Date()))!
        return now >= start && now < end
    }
}

/// EPG 日期分组
struct LiveEpgDate: Codable, Identifiable, Hashable {
    var id: String { datePresent }
    var datePresent: String = ""  // 显示日期
    var date: String = ""         // 查询日期
    var index: Int = 0
    var isSelected: Bool = false
}
