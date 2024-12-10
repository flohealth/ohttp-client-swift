import Foundation

struct URLSessionClient {
    struct Request {
        let url: URL
        let method: String
        let headers: [String: String]
        let body: Data?
        let useCache: Bool
    }
    
    var sendRequest: (Request, Bool) async throws -> (Data, URLResponse)
}

extension URLSessionClient {
    
    static func live(userAgent: String) -> Self {
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpAdditionalHeaders = [
            "User-Agent": userAgent,
            "Accept-Language": "*"
        ]
        sessionConfig.urlCache = URLCache()
        let session = URLSession(configuration: sessionConfig)
        
        return URLSessionClient(
            sendRequest: { req, invalidateCache in
                var request = URLRequest(url: req.url)
                request.httpMethod = req.method
                for (header, value) in req.headers {
                    request.addValue(value, forHTTPHeaderField: header)
                }
                request.httpBody = req.body
                
                if !req.useCache {
                    request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
                } else if invalidateCache {
                    session.configuration.urlCache?.extra_removeCachedResponse(for: request)
                }
                
                return try await session.data(for: request)
            }
        )
    }
}

private extension URLCache {
    
    // This is a workaround for system bug described here
    // https://forums.developer.apple.com/thread/65561
    func extra_removeCachedResponse(for request: URLRequest) {
        
        guard self.cachedResponse(for: request)?.response as? HTTPURLResponse != nil,
              let url = request.url,
              let responseWithZeroTTL = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Cache-Control": "max-age=0"]) else {
            return
        }
        
        let cachedResponse = CachedURLResponse(response: responseWithZeroTTL, data: Data())
        storeCachedResponse(cachedResponse, for: request)
    }
}
