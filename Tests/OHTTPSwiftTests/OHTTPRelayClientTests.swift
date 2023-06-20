import XCTest
import OHTTPEncapsulation

@testable import OHTTPSwift

class OHTTPRelayClientTests: XCTestCase {
    func testRelayRequestHappyPath() async throws {
        let encapsulatedResponseData = try XCTUnwrap("Encapsulated Response".data(using: .utf8))
        var client = OHTTPRelayClient { body in
            XCTAssertEqual(String(data: body, encoding: .utf8), "Encapsulated Request")
            return encapsulatedResponseData
        }
        
        let keyConfigClient = OHTTPKeyConfigClient { _ in keyConfig }
        var encapsulatedRequestDropCalled = false
        let encapsulatedRequestData = try XCTUnwrap("Encapsulated Request".data(using: .utf8))
        let encapsulation = EncapsulationClient { _ in
            return EncapsulatedRequest(
                encapsulatedRequestData: encapsulatedRequestData,
                decapsulateResponse: { encapsulatedResponse in
                    XCTAssertEqual(String(data: encapsulatedResponse, encoding: .utf8), "Encapsulated Response")
                    return knownLengthResponseData
                },
                drop: {
                    encapsulatedRequestDropCalled = true
                }
            )
        }
        
        let originalUrl = try XCTUnwrap(URL(string: "https://original"))
        var request = URLRequest(url: originalUrl)
        request.httpBody = try XCTUnwrap("Request".data(using: .utf8))
        
        let (response, body) = try await client.relayRequest(
            originalRequest: request,
            keyConfigClient: keyConfigClient,
            encapsulation: { _ in encapsulation }
        )
        
        XCTAssertEqual(encapsulatedRequestDropCalled, true)
        XCTAssertEqual(String(data: body, encoding: .utf8), "Response")
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.url, originalUrl)
    }
    
    func testRelayRequestInvalidKey() async throws {
        var client = OHTTPRelayClient { _ in
            throw OHTTPClientError.invalidKey
        }
        
        var getAppRelayKeyCalled = 0
        let keyConfigClient = OHTTPKeyConfigClient { _ in
            getAppRelayKeyCalled += 1
            return keyConfig
        }
        
        let requestUrl = try XCTUnwrap(URL(string: "https://request"))
        do {
            _ = try await client.relayRequest(
                originalRequest: URLRequest(url: requestUrl),
                keyConfigClient: keyConfigClient,
                encapsulation: { _ in .passthrough }
            )
            XCTFail("Expected to throw OHTTPClientError.invalidKey")
        } catch OHTTPClientError.invalidKey {
            XCTAssertEqual(getAppRelayKeyCalled, 2)
        }
    }
}

fileprivate let keyConfig = Data(bytes: [
    0x00, 0x00, 0x20, 0xA7, 0x68, 0x19, 0xC4, 0x38, 0x80, 0xEF,
    0xA5, 0xA0, 0x6C, 0x4A, 0xDD, 0x10, 0x6C, 0x58, 0x6D, 0x98,
    0x71, 0x70, 0x2A, 0xFB, 0x75, 0xDC, 0xF9, 0x60, 0xED, 0x32,
    0x54, 0xB9, 0x09, 0x21, 0x57, 0x00, 0x04, 0x00, 0x01, 0x00,
    0x01
] as [UInt8], count: 41)

fileprivate let knownLengthResponseData = Data(bytes: [
    0x01, // Framing indicator
    0x40, 0xc8, // Status code(200)
    0x00, // Header section length (0)
    0x08, // Content length (8)
    0x52, 0x65, 0x73, 0x70, 0x6F, 0x6E, 0x73, 0x65, // Content (Response)
    0x00, // Trailer section length (0)
] as [UInt8], count: 14)
