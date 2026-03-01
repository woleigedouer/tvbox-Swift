import Foundation

/// 电影/视频数据模型 - 对应 Android 版 Movie.java
struct Movie: Codable {
    var videoList: [Video] = []
    var pagecount: Int = 0
    var page: Int = 0
    var total: Int = 0
    var limit: Int = 0
    
    /// 单个视频条目
    struct Video: Codable, Identifiable, Hashable {
        var id: String
        var name: String = ""
        var pic: String = ""
        var note: String = ""       // 备注（如"更新至第20集"）
        var year: String = ""
        var area: String = ""
        var type: String = ""       // 类型/分类名
        var director: String = ""
        var actor: String = ""
        var des: String = ""        // 简介
        var sourceKey: String = ""  // 来源站点 key
        var tid: String = ""        // 分类 ID
        var last: String = ""       // 最后更新
        var dt: String = ""         // 日期
        
        init(id: String = UUID().uuidString, name: String = "", pic: String = "",
             note: String = "", sourceKey: String = "") {
            self.id = id
            self.name = name
            self.pic = pic
            self.note = note
            self.sourceKey = sourceKey
        }
        
        enum CodingKeys: String, CodingKey {
            case id = "vod_id"
            case name = "vod_name"
            case pic = "vod_pic"
            case note = "vod_remarks"
            case year = "vod_year"
            case area = "vod_area"
            case type = "type_name"
            case director = "vod_director"
            case actor = "vod_actor"
            case des = "vod_content"
            case tid = "type_id"
            case last = "vod_time"
            case dt = "vod_play_from"
            case sourceKey
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            // 支持 String 或 Int 类型的 id
            if let intId = try? container.decode(Int.self, forKey: .id) {
                self.id = String(intId)
            } else {
                self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
            }
            self.name = (try? container.decode(String.self, forKey: .name)) ?? ""
            self.pic = (try? container.decode(String.self, forKey: .pic)) ?? ""
            self.note = (try? container.decode(String.self, forKey: .note)) ?? ""
            self.year = (try? container.decode(String.self, forKey: .year)) ?? ""
            self.area = (try? container.decode(String.self, forKey: .area)) ?? ""
            self.type = (try? container.decode(String.self, forKey: .type)) ?? ""
            self.director = (try? container.decode(String.self, forKey: .director)) ?? ""
            self.actor = (try? container.decode(String.self, forKey: .actor)) ?? ""
            self.des = (try? container.decode(String.self, forKey: .des)) ?? ""
            self.tid = {
                if let intTid = try? container.decode(Int.self, forKey: .tid) {
                    return String(intTid)
                }
                return (try? container.decode(String.self, forKey: .tid)) ?? ""
            }()
            self.last = (try? container.decode(String.self, forKey: .last)) ?? ""
            self.dt = (try? container.decode(String.self, forKey: .dt)) ?? ""
            self.sourceKey = (try? container.decode(String.self, forKey: .sourceKey)) ?? ""
        }
    }
}
