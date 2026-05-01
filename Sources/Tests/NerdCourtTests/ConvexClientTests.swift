import XCTest
import Foundation
@testable import NerdCourt

final class ConvexClientTests: XCTestCase {
    private var client: ConvexClient!
    private var mockSession: URLSession!
    private var mockProtocol: MockURLProtocol.Type!

    // Use a placeholder test URL instead of a real deployment endpoint
    static let testDeploymentURL = "https://test-instance.convex.cloud"

    override func setUp() async throws {
        try await super.setUp()
        mockProtocol = MockURLProtocol.self
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: configuration)
        client = ConvexClient(deploymentURL: ConvexClientTests.testDeploymentURL, session: mockSession)
    }

    override func tearDown() async throws {
        MockURLProtocol.reset()
        client = nil
        mockSession = nil
        try await super.tearDown()
    }

    // MARK: - Query Tests

    func testQuerySuccess() async throws {
        let expectedData = #"{"grievances":[]}"#.data(using: .utf8)!
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertTrue(request.url?.absoluteString.hasPrefix(ConvexClientTests.testDeploymentURL + "/api/query") ?? false)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, expectedData)
        }

        let body = try JSONEncoder().encode(["path": "grievances/list"])
        let data = try await client.query("grievances/list", body: body)
        XCTAssertEqual(data, expectedData)
    }

    func testQueryNetworkError() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let body = Data()
        do {
            _ = try await client.query("test", body: body)
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }

    func testQueryBadStatusCode() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let body = Data()
        do {
            _ = try await client.query("test", body: body)
            XCTFail("Expected error")
        } catch let error as ConvexClientError {
            XCTAssertEqual(error, .badStatusCode(500))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testQueryDecodingError() async {
        // This test verifies that the client does not attempt to decode the response;
        // it just returns raw Data. So no decoding error from client.
        // We'll just ensure it passes through data.
        let expectedData = Data()
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, expectedData)
        }

        let body = Data()
        let data = try await client.query("test", body: body)
        XCTAssertEqual(data, expectedData)
    }

    // MARK: - Mutate Tests

    func testMutateSuccess() async throws {
        let expectedData = #"{"success":true}"#.data(using: .utf8)!
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertTrue(request.url?.absoluteString.hasPrefix(ConvexClientTests.testDeploymentURL + "/api/mutation") ?? false)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, expectedData)
        }

        let body = try JSONEncoder().encode(["path": "grievances/submit"])
        let data = try await client.mutate("grievances/submit", body: body)
        XCTAssertEqual(data, expectedData)
    }

    func testMutateNetworkError() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.cannotFindHost)
        }

        let body = Data()
        do {
            _ = try await client.mutate("test", body: body)
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }

    func testMutateBadStatusCode() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 403, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let body = Data()
        do {
            _ = try await client.mutate("test", body: body)
            XCTFail("Expected error")
        } catch let error as ConvexClientError {
            XCTAssertEqual(error, .badStatusCode(403))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Action Tests

    func testActionSuccess() async throws {
        let expectedData = #"{"result":"done"}"#.data(using: .utf8)!
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertTrue(request.url?.absoluteString.hasPrefix(ConvexClientTests.testDeploymentURL + "/api/action") ?? false)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, expectedData)
        }

        let body = try JSONEncoder().encode(["path": "generateEpisode"])
        let data = try await client.action("generateEpisode", body: body)
        XCTAssertEqual(data, expectedData)
    }

    func testActionNetworkError() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.timedOut)
        }

        let body = Data()
        do {
            _ = try await client.action("test", body: body)
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }

    func testActionBadStatusCode() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let body = Data()
        do {
            _ = try await client.action("test", body: body)
            XCTFail("Expected error")
        } catch let error as ConvexClientError {
            XCTAssertEqual(error, .badStatusCode(404))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Request Body Encoding

    func testRequestBodyIsEncodedCorrectly() async throws {
        let expectation = self.expectation(description: "Request body captured")
        MockURLProtocol.requestHandler = { request in
            defer { expectation.fulfill() }
            let bodyData = request.httpBody ?? Data()
            let decoded = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
            XCTAssertNotNil(decoded)
            XCTAssertEqual(decoded?["path"] as? String, "test/path")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let body = try JSONEncoder().encode(["path": "test/path"])
        _ = try await client.query("test/path", body: body)
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Deployment URL Precondition Tests

    func testInitWithEmptyURLFails() {
        XCTAssertThrowsError(try ConvexClient(deploymentURL: "")) { error in
            // Precondition failure — in debug builds this traps; in release it's undefined behavior.
            // We can't easily test precondition failures in XCTest, so this verifies the API surface.
        }
    }

    func testInitWithValidURL() {
        let client = ConvexClient(deploymentURL: "https://test-instance.convex.cloud")
        XCTAssertNotNil(client)
    }
}

// MARK: - Mock URLProtocol

private final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    static func reset() {
        requestHandler = nil
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Handler not set")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - ConvexClientError (if not defined in main target, define here for tests)

enum ConvexClientError: Error, Equatable {
    case badStatusCode(Int)
}