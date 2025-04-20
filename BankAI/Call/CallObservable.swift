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
    
    var history: [SpeechTemplate] = []
    
    var introductionAudioGenerated: URL? = nil
    var preferredLanguageSelected: String? = nil
    var isConvenientTimeAudioGenerated: URL? = nil
    var userCanTalkRightNow: Bool? = nil
    var askCanTalkInTimeAudio: URL? = nil
    var userCanTalkInDate: Date? = nil
    var endCallAudioGenerated: URL? = nil
    var askInitialQuestionAudio: URL? = nil
    var userInterestedInInitialQuestion: Bool? = nil
    var askCallBackQuestionAudio: URL? = nil
    
    
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
            let sttResponse = try await openAI.transcribeAudio(audioUrl)
            let sttText = sttResponse.text
            
            let response = try await openAI.sendPrompt(sttText, systemPrompt: speechTemplate.answerType.answerPrompt)
            
            // Notify View that preferred Language is generated
            if let preferredLanguage = response.choices.first?.message.content {
                await MainActor.run {
                    self.preferredLanguageSelected = preferredLanguage.lowercased()
                }
            }
            
        } catch {
            print(error)
        }
    }
    
    func askIfConvenientToTalkRightNow() async {
        do {
            // Generate question
            guard let preferredLanguageSelected else { return }
            let speechTemplate = SpeechTemplate(id: "is_convenient_time", questionType: .isConvenientTime(preferredLanguageSelected), answerType: .yesOrNo)
            
            let response = try await openAI.sendPrompt("\(speechTemplate.questionType.questionPrompt)", systemPrompt: "Write only a message that should be said on the speech. It should be very short!")
            
            // TTS
            if let question = response.choices.first?.message.content {
                let ttsStream = openAI.synthesizeSpeech(question)
                let fileName = UUID().uuidString
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
                
                history.append(speechTemplate)
                
                // Notify View that TTS is generated
                await MainActor.run {
                    isConvenientTimeAudioGenerated = fileManager.getPath(key: fileName, media: .audio)
                }
            }
        } catch {
            print(error)
        }
    }
    
    func userRespondsToConvenientTime(audioURL: URL) async {
        do {
            // STT
            guard let speechTemplate = history.last else { return }
            
            let sttResponse = try await openAI.transcribeAudio(audioURL)
            let sttText = sttResponse.text
            
            let response = try await openAI.sendPrompt(sttText, systemPrompt: speechTemplate.answerType.answerPrompt)
            
            if let completionAnswer = response.choices.first?.message.content {
                // Notify here
                if completionAnswer.lowercased() == "yes" {
                    await MainActor.run {
                        self.userCanTalkRightNow = true
                    }
                } else {
                    await MainActor.run {
                        self.userCanTalkRightNow = false
                    }
                }
            }
            
        } catch {
            print(error)
        }
    }
    
    func askWhatIsConvenientTime() async {
        do {
            guard let preferredLanguageSelected else { return }
            let speechTemplate = SpeechTemplate(id: "what_is_convenient_time", questionType: .whatIsConvenientTime(preferredLanguageSelected), answerType: .time)
            
            let response = try await openAI.sendPrompt("\(speechTemplate.questionType.questionPrompt)", systemPrompt: speechTemplate.answerType.answerPrompt)
            
            // TTS
            if let question = response.choices.first?.message.content {
                let ttsStream = openAI.synthesizeSpeech(question)
                let fileName = UUID().uuidString
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
                
                history.append(speechTemplate)
                
                // Notify View that TTS is generated
                await MainActor.run {
                    self.askCanTalkInTimeAudio = fileManager.getPath(key: fileName, media: .audio)
                }
            }
            
        } catch {
            print(error)
        }
    }
    
    func userRespondsWhenHeCanTalk(audioURL: URL) async {
        do {
            guard let speechTemplate = history.last else { return }
            
            let sttResponse = try await openAI.transcribeAudio(audioURL)
            let sttText = sttResponse.text
            
            let response = try await openAI.sendPrompt(sttText, systemPrompt: speechTemplate.answerType.answerPrompt)
            
            if let completionAnswer = response.choices.first?.message.content {
                // Notify here
                if let date = completionAnswer.toDate() {
                    await MainActor.run {
                        self.userCanTalkInDate = date
                    }
                } else {
                    await MainActor.run {
                        self.userCanTalkInDate = Date.distantFuture
                    }
                }
            }
        } catch {
            print(error)
        }
    }
    
    func endUserRespondsWhenHeCanTalk() async {
        do {
            guard let preferredLanguageSelected else { return }
            
            let speechTemplate = SpeechTemplate(id: "end", questionType: .end(preferredLanguageSelected), answerType: .none)
            
            let response = try await openAI.sendPrompt("\(speechTemplate.questionType.questionPrompt)", systemPrompt: speechTemplate.answerType.answerPrompt)
            
            // TTS
            if let question = response.choices.first?.message.content {
                let ttsStream = openAI.synthesizeSpeech(question)
                let fileName = UUID().uuidString
                let fileUrl = fileManager.getPath(key: fileName, media: .audio)
                guard let fileUrl else { return }
                
                guard let fileHandle = try? FileHandle(forWritingTo: fileUrl) else { return }
                
                for try await audioBuffer in ttsStream {
                    try fileHandle.write(contentsOf: audioBuffer)
                }
                
                try fileHandle.close()
                
                history.append(speechTemplate)
                
                // Notify View that TTS is generated
                await MainActor.run {
                    self.endCallAudioGenerated = fileManager.getPath(key: fileName, media: .audio)
                }
            }
        } catch {
            print(error)
        }
    }
    
    func askInitialQuestion(clientName: String, clientAge: Int) async {
        do {
            guard let preferredLanguageSelected else { return }
            let speechTemplate = SpeechTemplate(id: "init_describe_student_loan_options", questionType: .initialDescribeStudentLoanOptions(preferredLanguageSelected, clientName, clientAge), answerType: .yesOrNo)
            
            let response = try await openAI.sendPrompt(speechTemplate.questionType.questionPrompt, systemPrompt: speechTemplate.answerType.answerPrompt)
            
            // TTS
            if let question = response.choices.first?.message.content {
                let ttsStream = openAI.synthesizeSpeech(question)
                let fileName = UUID().uuidString
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
                
                history.append(speechTemplate)
                
                // Notify View that TTS is generated
                await MainActor.run {
                    self.askInitialQuestionAudio = fileManager.getPath(key: fileName, media: .audio)
                }
            }
        } catch {
            print(error)
        }
    }
    
    func userRespondsInInitialQuestion(audioURL: URL) async {
        do {
            guard let speechTemplate = history.last else { return }
            
            let sttResponse = try await openAI.transcribeAudio(audioURL)
            let sttText = sttResponse.text
            
            let response = try await openAI.sendPrompt(sttText, systemPrompt: speechTemplate.answerType.answerPrompt)
            
            if let completionAnswer = response.choices.first?.message.content {
                // Notify here
                if completionAnswer == "yes" {
                    await MainActor.run {
                        self.userInterestedInInitialQuestion = true
                    }
                } else {
                    await MainActor.run {
                        self.userInterestedInInitialQuestion = false
                    }
                }
            }
        } catch {
            print(error)
        }
    }
    
    func askCallbackQuestion(callDate: Date, resultOfPrevCall: String) async {
        do {
            guard let preferredLanguageSelected else { return }
            let speechTemplate = SpeechTemplate(id: "callback_remind_prev_call", questionType: .callbackRemindPrevCalls(preferredLanguageSelected, callDate, resultOfPrevCall), answerType: .none)
            
            let response = try await openAI.sendPrompt(speechTemplate.questionType.questionPrompt, systemPrompt: "Just wrtie what should be said. Do not write anything else")
            
            if let question = response.choices.first?.message.content {
                let ttsStream = openAI.synthesizeSpeech(question)
                let fileName = UUID().uuidString
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
                
                history.append(speechTemplate)
                
                // Notify View that TTS is generated
                await MainActor.run {
                    self.askCallBackQuestionAudio = fileManager.getPath(key: fileName, media: .audio)
                }
            }
        } catch {
            print(error)
        }
    }
    
    func postClientData() async {
        do {
            
        } catch {
            print(error)
        }
    }
}
