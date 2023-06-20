import Foundation
import OHTTPEncapsulation

struct OHTTPRelayClient {
    var relayRequest: (Data) async throws -> Data
}

extension OHTTPRelayClient {
    static func live(client: URLSessionClient, relayUrl: URL) -> Self {
        .init(
            relayRequest: { body in
                let request = URLSessionClient.Request(
                    url: relayUrl,
                    method: "POST",
                    headers: ["Content-Type": "message/ohttp-req"],
                    body: body,
                    useCache: false
                )
                let (data, response) = try await client.sendRequest(request, false)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw OHTTPClientError.default
                }
                
                if httpResponse.statusCode == invalidKeyStatusCode {
                    throw OHTTPClientError.invalidKey
                } else if
                    successfulStatusCodes.contains(httpResponse.statusCode),
                    httpResponse.value(forHTTPHeaderField: contentTypeHeader) == OHTTPResponseContentType {
                    return data
                } else {
                    let errorDescription = String(data: data, encoding: .utf8)
                    throw OHTTPClientError.invalidResponse(statusCode: httpResponse.statusCode, description: errorDescription)
                }
            }
        )
    }
    
    func relayRequest(
        originalRequest: URLRequest,
        keyConfigClient: OHTTPKeyConfigClient,
        encapsulation: (Data) -> EncapsulationClient
    ) async throws -> (HTTPURLResponse, Data) {
        guard let url = originalRequest.url else { throw AppRelayURLProtocolError.urlIsMissing }
        
        let body = try originalRequest.asBinaryHTTP()
        
        func requestAttempt(invalidateKeyCache: Bool) async throws -> (HTTPURLResponse, Data) {
            try Task.checkCancellation()
            let decapsulatedData = try await relayRequest(
                body: body,
                keyConfigClient: keyConfigClient,
                encapsulation: encapsulation,
                invalidateKeyCache: invalidateKeyCache
            )
            return try HTTPURLResponse.from(url: url, binaryHTTPData: decapsulatedData)
        }
        
        do {
            return try await requestAttempt(invalidateKeyCache: false)
        } catch OHTTPClientError.invalidKey {
            // try again with cache invalidation
            return try await requestAttempt(invalidateKeyCache: true)
        }
    }
    
    func relayRequest(
        body: Data,
        keyConfigClient: OHTTPKeyConfigClient,
        encapsulation: (Data) -> EncapsulationClient,
        invalidateKeyCache: Bool
    ) async throws -> Data {
        let key = try await keyConfigClient.fetchKeyConfiguration(invalidateKeyCache)
        try Task.checkCancellation()
        
        let encapsulatedRequest = try encapsulation(key).encapsulateRequest(body)
        
        defer {
            encapsulatedRequest.drop()
        }
        
        let encapsulatedResponseData = try await relayRequest(encapsulatedRequest.encapsulatedRequestData)
        
        return try encapsulatedRequest.decapsulateResponse(encapsulatedResponseData)
    }
    
    static let invalidKeyStatusCode = 401
    static let successfulStatusCodes = 200..<300
    static let contentTypeHeader = "Content-Type"
    static let OHTTPResponseContentType = "message/ohttp-res"
}
