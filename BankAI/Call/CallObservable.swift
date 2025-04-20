//
//  CallObservable.swift
//  BankAI
//
//  Created by Akbar Khusanbaev on 19/04/25.
//

import Observation
import Combine
import Foundation

@Observable
final class CallObservable {
    
    private let openAI = OpenAIManager.shared
    private let networkManager = NetworkService()
    private let fileManager = LocalFileManager()
    
    private var history: [SpeechTemplate] = []
    
    var introductionAudioGenerated: URL? = nil
    
    
    private var timerCancellable: AnyCancellable?
    var isAnswered = false
    var elapsedSeconds: Int = 0

    func startCall() {
        isAnswered = true
        elapsedSeconds = 0
        // create a timer that fires every second on the main run loop :contentReference[oaicite:5]{index=5}
        timerCancellable = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.elapsedSeconds += 1
            }
    }

    func endCall() {
        timerCancellable?.cancel()
    }

    var formattedTime: String {
        String(format: "%02d:%02d", elapsedSeconds / 60, elapsedSeconds % 60)
    }
    
    func generateIntroduction(clientName: String) async {
        do {
            // Generating Audio with GPT TTS
            let fileName = UUID().uuidString
            let introductionSpeechTemplate = SpeechTemplate(id: "welcome_preferred_language", questionType: .welcomeAndPreferredLanguage("Ipak Yuli Bank", clientName), answerType: .preferredLanguage)
            let ttsStream = openAI.synthesizeSpeech(introductionSpeechTemplate.questionType.questionPrompt)
            let fileUrl = fileManager.getPath(key: fileName, media: .audio)
            guard let fileUrl else { return }
            
            guard let fileHandle = try? FileHandle(forWritingTo: fileUrl) else {
                print("Unable to open file handle.")
                return
            }
            
            for try await audioBuffer in ttsStream {
                try fileHandle.write(contentsOf: audioBuffer)
            }
            
            try fileHandle.close()
            
            history.append(introductionSpeechTemplate)
            
            // Notify View that TTS is generated
            await MainActor.run {
                introductionAudioGenerated = fileManager.getPath(key: fileName, media: .audio)
            }
        } catch {
            print(error)
        }
    }
    
    func choosePreferredLanguage(audioUrl: URL) async {
        do {
            // STT
            guard let speechTemplate = history.last else { return }
            
        } catch {
            print(error)
        }
    }
    
    
    
    func postClientData() async {
        do {
            try await networkManager.postData(for: .clients, data: <#T##Decodable & Encodable#>)
        } catch {
            print(error)
        }
    }
}
