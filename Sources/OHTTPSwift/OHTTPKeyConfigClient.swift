import Foundation

public struct OHTTPKeyConfigClient {
    public var fetchKeyConfiguration: (Bool) async throws -> Data
}

extension OHTTPKeyConfigClient {
    static func live(client: URLSessionClient, configUrl: URL) -> Self {
        let actor = OHTTPKeyConfigActor(client: client, configUrl: configUrl)
        return .init(fetchKeyConfiguration: actor.fetchKeyConfiguration)
    }
}

actor OHTTPKeyConfigActor {
    private var activeTask: Task<Data, Error>?
    
    private let client: URLSessionClient
    private let configUrl: URL
    
    init(client: URLSessionClient, configUrl: URL) {
        self.client = client
        self.configUrl = configUrl
    }
    
    func fetchKeyConfiguration(invalidateCache: Bool) async throws -> Data {
        let task: Task<Data, Error>
        if let activeTask {
            task = activeTask
        } else {
            task = Task {
                try await performFetch(invalidateCache: invalidateCache)
            }
            activeTask = task
        }
        return try await task.value
    }
    
    private func performFetch(invalidateCache: Bool) async throws -> Data {
        let request = URLSessionClient.Request(
            url: configUrl,
            method: "GET",
            headers: [:],
            body: nil,
            useCache: true
        )
        let (data, response) = try await client.sendRequest(request, invalidateCache)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OHTTPClientError.default
        }
        
        guard Self.successfulStatusCodes.contains(httpResponse.statusCode) else {
            let errorDescription = String(data: data, encoding: .utf8)
            let error = OHTTPClientError.invalidResponse(statusCode: httpResponse.statusCode, description: errorDescription)
            throw error
        }
        
        activeTask = nil
        return data
    }
    
    static let successfulStatusCodes = 200..<300
}
