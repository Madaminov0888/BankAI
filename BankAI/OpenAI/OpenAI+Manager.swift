//
//  OpenAI+Manager.swift
//  BankAI
//
//  Created by Akbar Khusanbaev on 20/04/25.
//

import Foundation

/// Stores configuration values for the OpenAI API.
enum OpenAIEnvironment {
    /// The base URL for all OpenAI REST endpoints.
    static let baseURL = URL(string: "https://api.openai.com/v1")!

    /// The API key for authenticating requests. Should be replaced or injected securely.
    static var apiKey: String = "API_KEY"
}

/// Represents every supported OpenAI API endpoint along with any associated parameters.
enum OpenAIEndpoint {
    /// Endpoint for chat-based completions (e.g., GPT models).
    case chatCompletion(messages: [ChatMessage], model: String)
    /// Endpoint for Text-to-Speech synthesis.
    case textToSpeech(text: String, voice: String)
    /// Endpoint for Speech-to-Text transcription.
    case speechToText(audioURL: URL)

    /// The URL path component for this endpoint.
    var path: String {
        switch self {
        case .chatCompletion: return "/chat/completions"
        case .textToSpeech:   return "/audio/speech"
        case .speechToText:   return "/audio/transcriptions"
        }
    }

    /// HTTP method (all endpoints use POST).
    var method: String { "POST" }

    /// HTTP headers required for the given endpoint.
    var headers: [String: String] {
        switch self {
        case .chatCompletion:
            return [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(OpenAIEnvironment.apiKey)"
            ]

        case .textToSpeech:
            return [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(OpenAIEnvironment.apiKey)"
            ]

        case .speechToText(let url):
            // For multipart form uploads, boundary must be unique per file
            let boundary = "Boundary-\(url.lastPathComponent)"
            return [
                "Content-Type": "multipart/form-data; boundary=\(boundary)",
                "Authorization": "Bearer \(OpenAIEnvironment.apiKey)"
            ]
        }
    }

    /// Encodes the request body as JSON or multipart data.
    var body: Data? {
        switch self {
        case .chatCompletion(let messages, let model):
            // Encode chat messages and model into JSON payload
            let request = ChatCompletionRequest(model: model, messages: messages)
            return try? JSONEncoder().encode(request)

        case .textToSpeech(let text, let voice):
            // Build TTS request JSON
            let request = TTSAudioRequest(model: "tts-1",
                                         voice: voice,
                                         input: text,
                                         response_format: "wav")
            return try? JSONEncoder().encode(request)

        case .speechToText(let url):
            // Assemble multipart/form-data body with audio file + model parameter
            do {
                var body = Data()
                let boundary = "Boundary-\(url.lastPathComponent)"

                // 1. Audio file part
                let filename = url.lastPathComponent
                let fileData = try Data(contentsOf: url)
                let mimeType = "audio/wav"
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
                body.append(fileData)
                body.append("\r\n".data(using: .utf8)!)

                // 2. Model name part
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
                body.append("gpt-4o-mini-transcribe\r\n".data(using: .utf8)!)

                // 3. Closing boundary
                body.append("--\(boundary)--\r\n".data(using: .utf8)!)
                return body
            } catch {
                debugPrint("Failed to read audio file at \(url): \(error)")
                return nil
            }
        }
    }
}

/// Protocol defining core network operations against OpenAI endpoints.
protocol OpenAINetworkManaging {
    /// Performs a one-off request and decodes the JSON response.
    /// - Parameter endpoint: The OpenAI endpoint with its parameters.
    /// - Returns: A decoded Swift type conforming to `Decodable`.
    func request<T: Decodable>(_ endpoint: OpenAIEndpoint) async throws -> T

    /// Opens a streaming connection, yielding raw data chunks.
    /// - Parameter endpoint: The OpenAI endpoint to stream from.
    /// - Returns: An async stream of `Data`.
    func stream(_ endpoint: OpenAIEndpoint) -> AsyncThrowingStream<Data, Error>
}

/// Default implementation of `OpenAINetworkManaging` using `URLSession`.
final class OpenAINetworkManager: OpenAINetworkManaging {
    private let session = URLSession.shared

    func request<T: Decodable>(_ endpoint: OpenAIEndpoint) async throws -> T {
        var request = URLRequest(
            url: OpenAIEnvironment.baseURL
                  .appendingPathComponent(endpoint.path)
        )
        request.httpMethod = endpoint.method
        endpoint.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.httpBody = endpoint.body

        let (data, response) = try await session.data(for: request)
        // TODO: Validate `response` status code and handle errors appropriately
        return try JSONDecoder().decode(T.self, from: data)
    }

    func stream(_ endpoint: OpenAIEndpoint) -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            var request = URLRequest(
                url: OpenAIEnvironment.baseURL
                      .appendingPathComponent(endpoint.path)
            )
            request.httpMethod = endpoint.method
            endpoint.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
            request.httpBody = endpoint.body

            let task = session.dataTask(with: request) { data, _, error in
                if let data = data {
                    continuation.yield(data)
                }
                if let error = error {
                    continuation.finish(throwing: error)
                } else {
                    continuation.finish()
                }
            }
            task.resume()
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}

/// High-level facade for performing OpenAI operations across the app.
final class OpenAIManager {
    /// Shared singleton instance for easy access.
    static let shared = OpenAIManager(network: OpenAINetworkManager())

    private let network: OpenAINetworkManaging

    /// Allows dependency injection for better testability.
    init(network: OpenAINetworkManaging) {
        self.network = network
    }

    /// Sends a user prompt to the chat completion API and returns the response.
    /// - Parameter prompt: The message content from the user.
    /// - Returns: A `ChatCompletionResponse` with generated text and metadata.
    func sendPrompt(_ prompt: String) async throws -> ChatCompletionResponse {
        let message = ChatMessage(role: .user, content: prompt)
        return try await network.request(
            .chatCompletion(messages: [message], model: "gpt-4.1")
        )
    }

    /// Streams synthesized speech audio data for a given text.
    /// - Parameter text: The text to convert to audio.
    /// - Returns: An async data stream of audio chunks.
    func synthesizeSpeech(_ text: String) -> AsyncThrowingStream<Data, Error> {
        network.stream(.textToSpeech(text: text, voice: "ash"))
    }

    /// Transcribes an audio file into text using the API.
    /// - Parameter url: Local file URL of the audio resource.
    /// - Returns: A `TranscriptionResponse` containing the transcribed text.
    func transcribeAudio(_ url: URL) async throws -> TranscriptionResponse {
        try await network.request(.speechToText(audioURL: url))
    }
}

// MARK: - Data Models

/// A single chat message used in chat completions.
struct ChatMessage: Codable {
    enum Role: String, Codable {
        case system  // Instructions or context for the model
        case user    // User-provided prompt or message
        case assistant // Model-generated response
    }

    let role: Role
    let content: String
}

/// Request body for chat completions.
struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
}

/// Request body used internally for speech transcription (not public API).
struct TranscriptionRequest: Codable {
    let file: URL
    let model: String
}

/// Request body for text-to-speech synthesis.
struct TTSAudioRequest: Codable {
    let model: String            // e.g. "tts-1"
    let voice: String            // voice identifier
    let input: String            // text to synthesize
    let response_format: String  // audio format, e.g. "wav"
}

/// Response format for chat completions.
struct ChatCompletionResponse: Codable {
    let id: String
    let object: String
    let created: Date
    let model: String
    let choices: [Choice]
    let service_tier: String
    let system_fingerprint: String

    struct Choice: Codable {
        let index: Int
        let message: Message

        struct Message: Codable {
            let role: String
            let content: String
        }
    }
}

/// Response format for audio transcription.
struct TranscriptionResponse: Codable {
    let text: String
}
