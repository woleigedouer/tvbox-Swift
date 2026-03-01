import Foundation

/// 播放器引擎类型
enum PlayerEngine: Int, CaseIterable, Identifiable {
    case system = 0
    case vlc = 10
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .system:
            return "系统播放器"
        case .vlc:
            return "VLC播放器"
        }
    }
    
    static var isVLCAvailable: Bool {
        #if canImport(VLCKitSPM)
        return true
        #else
        return false
        #endif
    }
    
    static var availableEngines: [PlayerEngine] {
        var engines: [PlayerEngine] = [.system]
        if isVLCAvailable {
            engines.append(.vlc)
        }
        return engines
    }
    
    static func fromStoredValue(_ rawValue: Int) -> PlayerEngine {
        guard let engine = PlayerEngine(rawValue: rawValue) else {
            return .system
        }
        
        if engine == .vlc && !isVLCAvailable {
            return .system
        }
        
        return engine
    }
}

/// 视频解码模式
enum VideoDecodeMode: Int, CaseIterable, Identifiable {
    case auto = 0
    case hardware = 1
    case software = 2
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .auto:
            return "自动"
        case .hardware:
            return "硬解码"
        case .software:
            return "软解码"
        }
    }
    
    static func fromStoredValue(_ rawValue: Int) -> VideoDecodeMode {
        VideoDecodeMode(rawValue: rawValue) ?? .auto
    }
    
    /// VLC 媒体选项
    var vlcHardwareDecodeOption: String? {
        switch self {
        case .auto:
            // 自动模式默认硬解优先，异常时用户仍可手动切到软解。
            return "any"
        case .hardware:
            return "any"
        case .software:
            return "none"
        }
    }
}

/// VLC 缓冲策略
enum VLCBufferMode: Int, CaseIterable, Identifiable {
    case lowLatency = 0
    case balanced = 1
    case smooth = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .lowLatency:
            return "低延迟"
        case .balanced:
            return "均衡"
        case .smooth:
            return "流畅优先"
        }
    }

    static var defaultMode: VLCBufferMode { .balanced }

    static func fromStoredValue(_ rawValue: Int) -> VLCBufferMode {
        VLCBufferMode(rawValue: rawValue) ?? defaultMode
    }

    var enableFrameDrop: Bool {
        self == .lowLatency
    }

    func cacheConfig(isLive: Bool) -> (network: Int, live: Int, file: Int) {
        switch self {
        case .lowLatency:
            if isLive {
                return (network: 1200, live: 1200, file: 1600)
            }
            return (network: 1800, live: 1600, file: 2400)
        case .balanced:
            if isLive {
                return (network: 2600, live: 2600, file: 3200)
            }
            return (network: 3800, live: 3200, file: 4400)
        case .smooth:
            if isLive {
                return (network: 4200, live: 4200, file: 5200)
            }
            return (network: 5600, live: 4800, file: 6400)
        }
    }
}
