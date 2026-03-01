import Foundation

/// 网络请求封装 - 对应 Android 版 OkGo
class NetworkManager {
    static let shared = NetworkManager()
    
    private let session: URLSession
    private let decoder = JSONDecoder()
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.httpMaximumConnectionsPerHost = 5
        self.session = URLSession(configuration: config)
    }
    
    /// GET 请求获取字符串
    func getString(from urlString: String, headers: [String: String]? = nil) async throws -> String {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw NetworkError.invalidURL(urlString)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        guard let str = String(data: data, encoding: .utf8) else {
            throw NetworkError.decodingError("UTF-8 解码失败")
        }
        
        return str
    }
    
    /// GET 请求解码 JSON
    func getJSON<T: Decodable>(from urlString: String, type: T.Type, headers: [String: String]? = nil) async throws -> T {
        let str = try await getString(from: urlString, headers: headers)
        guard let data = str.data(using: .utf8) else {
            throw NetworkError.decodingError("字符串转 Data 失败")
        }
        return try decoder.decode(T.self, from: data)
    }
    
    /// GET 请求获取原始 Data
    func getData(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw NetworkError.invalidURL(urlString)
        }
        let (data, _) = try await session.data(from: url)
        return data
    }
}

enum NetworkError: LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case httpError(Int)
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(let url): return "无效的URL: \(url)"
        case .invalidResponse: return "无效的响应"
        case .httpError(let code): return "HTTP 错误: \(code)"
        case .decodingError(let msg): return "解码错误: \(msg)"
        }
    }
}
