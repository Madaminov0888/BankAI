//
//  OpenAI+Manager.swift
//  BankAI
//
//  Created by Akbar Khusanbaev on 20/04/25.
//

import Foundation

enum OpenAIEnvironment {
    static let baseURL = URL(string: "https://api.openai.com/v1")!
    static var apiKey: String = "API_KEY"
}

enum OpenAIEndpoint {
    case chatCompletion(messages: [ChatMessage], model: String)
    case textToSpeech(text: String, voice: String)
    case speechToText(audioURL: URL)

    var path: String {
        switch self {
        case .chatCompletion: return "/chat/completions"
        case .textToSpeech:   return "/audio/speech"
        case .speechToText:   return "/audio/transcriptions"
        }
    }

    var method: String { "POST" }

    var headers: [String: String] {
        switch self {
        case .chatCompletion(messages: _, model: _):
            [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(OpenAIEnvironment.apiKey)"
            ]
        case .textToSpeech(text: _, voice: _):
            [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(OpenAIEnvironment.apiKey)"
            ]
        case .speechToText(audioURL: let url):
            [
                "Content-Type": "multipart/form-data; boundary=Boundary-\(url.lastPathComponent)",
                "Authorization": "Bearer \(OpenAIEnvironment.apiKey)"
            ]
        }
    }

    var body: Data? {
        switch self {
        case .chatCompletion(messages: let messages, model: let model):
            let encodable = ChatCompletionRequest(model: model, messages: messages)
            return try? JSONEncoder().encode(encodable)
        case .textToSpeech(text: let text, voice: let voice):
            let encodable = TTSAudioRequest(model: "tts-1", voice: voice, input: text, response_format: "wav")
            
            return try? JSONEncoder().encode(encodable)
        case .speechToText(audioURL: let url):
            do {
                // Create multipart body
                var body = Data()
                
                let boundary = "Boundary-\(url.lastPathComponent)"
                
                // 1. Add file
                let filename = url.lastPathComponent
                let fileData = try Data(contentsOf: url)
                let mimetype = "audio/wav"
                
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
                body.append(fileData)
                body.append("\r\n".data(using: .utf8)!)
                
                // 2. Add model field
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
                body.append("gpt-4o-transcribe\r\n".data(using: .utf8)!)
                
                // 3. Finish
                body.append("--\(boundary)--\r\n".data(using: .utf8)!)
                
                return body
            } catch {
                print(error)
                return nil
            }
        }
    }
}

protocol OpenAINetworkManaging {
    func request<T: Decodable>(_ endpoint: OpenAIEndpoint) async throws -> T
    func stream(_ endpoint: OpenAIEndpoint) -> AsyncThrowingStream<Data, Error>
}

final class OpenAINetworkManager: OpenAINetworkManaging {
    private let session = URLSession.shared

    func request<T: Decodable>(_ endpoint: OpenAIEndpoint) async throws -> T {
        var req = URLRequest(url: OpenAIEnvironment.baseURL.appendingPathComponent(endpoint.path))
        req.httpMethod = endpoint.method
        endpoint.headers.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = endpoint.body
        let (data, resp) = try await session.data(for: req)
        // handle HTTP errors...
        return try JSONDecoder().decode(T.self, from: data)
    }

    func stream(_ endpoint: OpenAIEndpoint) -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            var req = URLRequest(url: OpenAIEnvironment.baseURL.appendingPathComponent(endpoint.path))
            req.httpMethod = endpoint.method
            endpoint.headers.forEach { req.setValue($1, forHTTPHeaderField: $0) }
            req.httpBody = endpoint.body

            let task = session.dataTask(with: req) { data, _, error in
                if let data = data { continuation.yield(data) }
                if let error = error { continuation.finish(throwing: error) }
                else { continuation.finish() }
            }
            task.resume()
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

final class OpenAIManager {
    static let shared = OpenAIManager(network: OpenAINetworkManager())

    private let network: OpenAINetworkManaging

    init(network: OpenAINetworkManaging) {
        self.network = network
    }

    func sendPrompt(_ prompt: String) async throws -> ChatCompletionResponse {
        let message = ChatMessage(role: .user, content: prompt)
        return try await network.request(.chatCompletion(messages: [message], model: "gpt-4.1"))
    }

    func synthesizeSpeech(_ text: String) -> AsyncThrowingStream<Data, Error> {
        network.stream(.textToSpeech(text: text, voice: "ash"))
    }

    func transcribeAudio(_ url: URL) async throws -> TranscriptionResponse {
        try await network.request(.speechToText(audioURL: url))
    }
}

struct ChatMessage: Codable {
    enum Role: String, Codable { case system, user, assistant }
    let role: Role
    let content: String
}

struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
}

struct TranscriptionRequest: Codable {
    let file: URL
    let model: String
}

struct TTSAudioRequest: Codable {
    let model: String
    let voice: String
    let input: String
    let response_format: String
}

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

struct TranscriptionResponse: Codable {
    let text: String
}

