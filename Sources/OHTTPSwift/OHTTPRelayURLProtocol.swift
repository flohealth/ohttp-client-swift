import Foundation
import OHTTPEncapsulation
import BinaryHTTP

class OHTTPRelayURLProtocol: URLProtocol {
    static var isActive = false
    
    private var loadingTask: Task<Void, Never>?

    override public class func canInit(with request: URLRequest) -> Bool {
        #if DEBUG
        assert(config != nil, "Call OHTTPSwift.configure BEFORE requests start going through this protocol")
        #endif
        
        return isActive && config != nil
    }

    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    override public func startLoading() {
        loadingTask = Task {
            do {
                let (response, body) = try await loadAsync()
                try Task.checkCancellation()
                self.client?.urlProtocol(self, didLoad: body)
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
                self.client?.urlProtocolDidFinishLoading(self)
            } catch {
                self.client?.urlProtocol(self, didFailWithError: error)
            }
        }
    }
    
    private func loadAsync() async throws -> (HTTPURLResponse, Data) {
        guard let config else { throw AppRelayURLProtocolError.configIsMissing }
        
        return try await config.relayClient()
            .relayRequest(
                originalRequest: request,
                keyConfigClient: config.keyConfigClient(),
                encapsulation: EncapsulationClient.live(config:)
            )
    }
    
    override public func stopLoading() {
        loadingTask?.cancel()
    }
}

enum AppRelayURLProtocolError: Error {
    case configIsMissing
    case urlIsMissing
}
