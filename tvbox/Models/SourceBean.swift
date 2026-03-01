import Foundation

/// 视频源站点配置 - 对应 Android 版 SourceBean.java
struct SourceBean: Codable, Identifiable, Hashable {
    var id: String { key }
    
    let key: String
    let name: String
    let api: String
    let searchable: Int       // 0:关闭搜索 1:启用搜索
    let filterable: Int       // 0:首页不可选 1:首页可选
    let playerType: Int       // 0:系统 1:IJK 2:EXO
    let type: Int             // 0:xml 1:json 3:jar 4:remote
    let ext: String?
    
    init(key: String = "", name: String = "", api: String = "",
         searchable: Int = 1, filterable: Int = 1,
         playerType: Int = 0, type: Int = 1, ext: String? = nil) {
        self.key = key
        self.name = name
        self.api = api
        self.searchable = searchable
        self.filterable = filterable
        self.playerType = playerType
        self.type = type
        self.ext = ext
    }
    
    var isSearchable: Bool { searchable == 1 }
    var isFilterable: Bool { filterable == 1 }
    
    /// 是否在 Swift 版中受支持（type=3 为 JAR/Spider，需要 Java 运行时，暂不支持）
    var isSupportedInSwift: Bool {
        return type == 0 || type == 1 || type == 4
    }
    
    /// 类型描述
    var typeDescription: String {
        switch type {
        case 0: return "XML"
        case 1: return "JSON"
        case 3: return "JAR"
        case 4: return "Remote"
        default: return "未知"
        }
    }
    
    /// api 字段是否为有效 HTTP URL
    var isHttpApi: Bool {
        return api.hasPrefix("http://") || api.hasPrefix("https://")
    }
}
