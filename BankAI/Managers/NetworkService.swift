//
//  NetworkService.swift
//  ExampleProject
//
//  Created by Muhammadjon Madaminov on 19/04/25.
//

import Foundation

/// Namespace for all REST endpoints exposed by the network service.
/// Use these cases to build URL paths and query parameters for API calls.
enum NetworkServiceEndpoints {
    /// Fetch the list of clients from the server.
    case clients

    /// The path component for the selected endpoint.
    var path: String {
        switch self {
        case .clients:
            return "clients"
        }
    }

    /// Optional URL query items for the endpoint.
    /// Return `nil` if no additional parameters are required.
    var queryItems: [URLQueryItem]? {
        switch self {
        default:
            return nil
        }
    }

    /// Fully constructed URL including base, path, and any query items.
    /// Returns `nil` if the base URL or components are invalid.
    var url: URL? {
        let baseURL = "http://192.168.16.113:5050/"
        var components = URLComponents(string: baseURL + path)
        components?.queryItems = queryItems
        return components?.url
    }
}

/// Protocol defining the contract for a network service.
/// Provides methods to fetch and post generic Codable data.
protocol NetworkServiceProtocol {
    /// Fetches and decodes JSON data from the specified endpoint.
    /// - Parameters:
    ///   - endpoint: The target endpoint to call.
    ///   - type: The `Codable` type to decode into.
    /// - Returns: An instance of the decoded type.
    func fetchData<T: Codable>(for endpoint: NetworkServiceEndpoints, type: T.Type) async throws -> T

    /// Sends a POST request with a Codable payload to the given endpoint.
    /// - Parameters:
    ///   - endpoint: The target endpoint to call.
    ///   - data: The `Encodable` payload to send.
    func postData<T: Codable>(for endpoint: NetworkServiceEndpoints, data: T) async throws
}

/// Concrete implementation of `NetworkServiceProtocol` using `URLSession`.
/// Handles JSON encoding/decoding and HTTP response validation.
final class NetworkService: NetworkServiceProtocol {
    /// Underlying URLSession used for all HTTP calls.
    private let session: URLSession

    /// Designated initializer allowing injection of custom session (e.g., for testing).
    /// - Parameter session: The URLSession instance to use. Defaults to `.shared`.
    init(session: URLSession = .shared) {
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config)
    }
    
    /// Generic GET fetch operation.
    /// - Throws: `NetworkErrors.invalidURL` if endpoint URL is malformed.
    ///           HTTP or decoding errors propagated from URLSession or JSONDecoder.
    func fetchData<T>(for endpoint: NetworkServiceEndpoints, type: T.Type) async throws -> T where T: Decodable, T: Encodable {
        // Construct URL and validate
        guard let url = endpoint.url else {
            throw NetworkErrors.invalidURL
        }

        // Build and send GET request
        let request = URLRequest(url: url)
        let (data, response) = try await session.data(for: request)

        // Validate HTTP status code
        try handleHttpResponse(response: response, data: data)

        // Decode JSON into model
        let responseModel = try JSONDecoder().decode(T.self, from: data)
        return responseModel
    }
    
    /// Generic POST operation with Codable payload.
    /// - Throws: `NetworkErrors.invalidURL` if endpoint URL is malformed.
    ///           HTTP or encoding errors propagated from URLSession or JSONEncoder.
    func postData<T>(for endpoint: NetworkServiceEndpoints, data: T) async throws where T: Decodable, T: Encodable {
        // Construct URL and validate
        guard let url = endpoint.url else {
            throw NetworkErrors.invalidURL
        }
        
        // Encode payload to JSON
        let payload = try JSONEncoder().encode(data)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = payload
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Send POST request
        let (_, response) = try await session.data(for: request)

        // Validate HTTP status code
        try handleHttpResponse(response: response)
    }
    
    /// Validates the HTTP response, throwing an error for non-2xx status codes.
    /// - Parameters:
    ///   - response: The URLResponse from the network request.
    ///   - data: Optional response body for logging in case of failure.
    /// - Throws: `NetworkErrors.serverError` if status code indicates failure.
    func handleHttpResponse(response: URLResponse, data: Data? = nil) throws {
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            // Log raw response for easier debugging
            let rawBody = String(data: data ?? Data(), encoding: .utf8) ?? "<empty>"
            print("Error Raw response data: \(rawBody)")
            throw NetworkErrors.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }
}

/// Represents errors that can occur during network operations.
enum NetworkErrors: Error {
    /// The constructed URL was invalid.
    case invalidURL
    /// The server response was malformed or unexpected.
    case invalidResponse
    /// The received data was nil or corrupted.
    case invalidData
    /// JSON decoding failed with the provided error.
    case decodingError(Error)
    /// The server returned a non-2xx status code.
    case serverError(statusCode: Int)
}

/// Provides localized descriptions for `NetworkErrors`.
extension NetworkErrors: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString(
                "The provided URL is invalid. Please check the endpoint and try again.",
                comment: "Invalid URL error message"
            )
        case .invalidResponse:
            return NSLocalizedString(
                "The server response is invalid. Please try again later.",
                comment: "Invalid response error message"
            )
        case .invalidData:
            return NSLocalizedString(
                "The received data is invalid or corrupted. Please try again.",
                comment: "Invalid data error message"
            )
        case .decodingError(let error):
            return NSLocalizedString(
                "Failed to decode the data: \(error.localizedDescription). Please contact support.",
                comment: "Decoding error message"
            )
        case .serverError(let statusCode):
            return NSLocalizedString(
                "The server returned an error with status code: \(statusCode). Please try again later.",
                comment: "Server error message"
            )
        }
    }
}
