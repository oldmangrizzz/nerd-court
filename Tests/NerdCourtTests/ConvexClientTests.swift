import XCTest
import Foundation
@testable import NerdCourt

final class ConvexClientTests: XCTestCase {
    private var client: ConvexClient!
    private var mockSession: URLSession!

    // Use a placeholder test URL instead of a real deployment endpoint
    static let testDeploymentURL = "https://test-instance.convex.cloud"

    override func setUp() async throws {
        try await super.setUp()
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

        let result: MockResponse = try await client.query("grievances/list")
        XCTAssertEqual(result.grievances, [])
    }

    func testQueryNetworkError() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        do {
            let _: MockResponse = try await client.query("test")
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

        do {
            let _: MockResponse = try await client.query("test")
            XCTFail("Expected error")
        } catch {
            // The client propagulates raw URLError or decoding errors; no custom error enum.
            XCTAssertTrue(true)
        }
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

        let data = try await client.mutation("grievances/submit", args: ["foo": "bar"])
        XCTAssertEqual(data, expectedData)
    }

    func testMutateNetworkError() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.cannotFindHost)
        }

        do {
            _ = try await client.mutation("test", args: [:])
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

        do {
            _ = try await client.mutation("test", args: [:])
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(true)
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

        let data = try await client.action("generateEpisode", args: ["input": "test"])
        XCTAssertEqual(data, expectedData)
    }

    func testActionNetworkError() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.timedOut)
        }

        do {
            _ = try await client.action("test", args: [:])
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

        do {
            _ = try await client.action("test", args: [:])
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(true)
        }
    }

    // MARK: - Deployment URL Precondition Tests

    func testInitWithValidURL() {
        let client = ConvexClient(deploymentURL: "https://test-instance.convex.cloud")
        XCTAssertNotNil(client)
    }
}

// MARK: - Mock Response Model

private struct MockResponse: Codable, Equatable {
    let grievances: [String]
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
