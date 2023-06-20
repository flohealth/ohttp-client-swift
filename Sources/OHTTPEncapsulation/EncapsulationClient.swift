import AppRelayObjc
import Foundation

public struct EncapsulationClient {
    public var encapsulateRequest: (Data) throws -> EncapsulatedRequest
    
    public init(encapsulateRequest: @escaping (Data) throws -> EncapsulatedRequest) {
        self.encapsulateRequest = encapsulateRequest
    }
}

public struct EncapsulationError: Error {
    public var description: String
}

public struct EncapsulatedRequest: Equatable {
    public var encapsulatedRequestData: Data
    public var decapsulateResponse: (Data) throws -> Data
    public var drop: () -> Void
    
    public init(
        encapsulatedRequestData: Data,
        decapsulateResponse: @escaping (Data) throws -> Data,
        drop: @escaping () -> Void
    ) {
        self.encapsulatedRequestData = encapsulatedRequestData
        self.decapsulateResponse = decapsulateResponse
        self.drop = drop
    }
    
    public static func == (lhs: EncapsulatedRequest, rhs: EncapsulatedRequest) -> Bool {
        lhs.encapsulatedRequestData == rhs.encapsulatedRequestData
    }
}

extension EncapsulationClient {
    public static let passthrough = Self {
        EncapsulatedRequest(
            encapsulatedRequestData: $0,
            decapsulateResponse: { $0 },
            drop: {}
        )
    }
    
    public static func live(config: Data) -> Self {
        .init(
            encapsulateRequest: {
                guard let context = AppRelayClientLibraryWrapper.encapsulateRequest($0, config: config) else {
                    throw EncapsulationError(description: AppRelayClientLibraryWrapper.lastErrorMessage() ?? "")
                }
                
                let encapsulatedRequestData = AppRelayClientLibraryWrapper.encapsulatedRequest(from: context)
                
                var contextDropped = false

                return EncapsulatedRequest(
                    encapsulatedRequestData: encapsulatedRequestData,
                    decapsulateResponse: {
                        guard !contextDropped else {
                            throw EncapsulationError(description: "Context has been already dropped")
                        }
                        
                        contextDropped = true
                        
                        guard let data = AppRelayClientLibraryWrapper.decapsulateResponse(from: context, encapsulatedResponse: $0) else {
                            throw EncapsulationError(description: AppRelayClientLibraryWrapper.lastErrorMessage() ?? "")
                        }
                        
                        return data
                    },
                    drop: {
                        guard !contextDropped else { return }
                        contextDropped = true
                        AppRelayClientLibraryWrapper.drop(context)
                    }
                )
            }
        )
    }
}
