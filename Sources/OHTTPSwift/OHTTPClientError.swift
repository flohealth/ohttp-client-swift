import Foundation

public enum OHTTPClientError: Error {
    case invalidKey
    case invalidResponse(statusCode: Int?, description: String?)
    
    static var `default`: Self { .invalidResponse(statusCode: nil, description: nil) }
}
