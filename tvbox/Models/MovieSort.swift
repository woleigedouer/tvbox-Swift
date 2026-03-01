import Foundation

/// 分类排序模型 - 对应 Android 版 MovieSort.java
struct MovieSort: Codable {
    var sortList: [SortData] = []
    
    /// 单个分类数据
    struct SortData: Codable, Identifiable, Hashable {
        var id: String
        var name: String = ""
        var flag: String = ""
        var filters: [SortFilter] = []
        
        init(id: String = "", name: String = "", flag: String = "") {
            self.id = id
            self.name = name
            self.flag = flag
        }
        
        static func home() -> SortData {
            SortData(id: "home", name: "推荐", flag: "1")
        }
    }
    
    /// 筛选条件
    struct SortFilter: Codable, Hashable {
        var key: String = ""
        var name: String = ""
        var values: [SortFilterValue] = []
        
        struct SortFilterValue: Codable, Hashable {
            var n: String = ""  // 显示名
            var v: String = ""  // 值
        }
    }
}
