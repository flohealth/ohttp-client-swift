import Foundation

var config: OHTTPConfiguration?

public var urlProtocol: AnyClass = OHTTPRelayURLProtocol.self

public func configure(userAgent: String, configURL: URL, relayURL: URL) {
    config = OHTTPConfiguration.live(
        userAgent: userAgent,
        configURL: configURL,
        relayURL: relayURL
    )
}

public func configure(userAgent: String, configClient: OHTTPKeyConfigClient, relayURL: URL) {
    config = OHTTPConfiguration.live(
        userAgent: userAgent,
        keyConfigClient: configClient,
        relayURL: relayURL
    )
}

public var isEnabled: Bool {
    get { OHTTPRelayURLProtocol.isActive }
    set { OHTTPRelayURLProtocol.isActive = newValue }
}

public func fetchOHTTPKeyConfig() {
    Task.detached {
        _ = try? await config?.keyConfigClient().fetchKeyConfiguration(true)
    }
}


struct OHTTPConfiguration {
    var keyConfigClient: () -> OHTTPKeyConfigClient
    var relayClient: () -> OHTTPRelayClient

    static func live(
        userAgent: String,
        configURL: URL,
        relayURL: URL
    ) -> Self {
        let urlSessionClient = URLSessionClient.live(userAgent: userAgent)
        let keyConfigClient = OHTTPKeyConfigClient.live(client: urlSessionClient, configUrl: configURL)
        let relayClient = OHTTPRelayClient.live(client: urlSessionClient, relayUrl: relayURL)
        return .init(
            keyConfigClient: { keyConfigClient },
            relayClient: { relayClient }
        )
    }
    
    static func live(
        userAgent: String,
        keyConfigClient: OHTTPKeyConfigClient,
        relayURL: URL
    ) -> Self {
        let urlSessionClient = URLSessionClient.live(userAgent: userAgent)
        let relayClient = OHTTPRelayClient.live(client: urlSessionClient, relayUrl: relayURL)
        return .init(
            keyConfigClient: { keyConfigClient },
            relayClient: { relayClient }
        )
    }
}
