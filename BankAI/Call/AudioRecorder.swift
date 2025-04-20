//
//  AudioRecorder.swift
//  BankAI
//
//  Created by Muhammadjon Madaminov on 20/04/25.
//


import Foundation
import AVKit


class AudioRecorder: ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    @Published var volume: Float = 0.0
    var audioURL: URL?
    
    func checkPermissions() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if !granted {
                print("Microphone permission denied.")
            }
        }
    }
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let tempDir = FileManager.default.temporaryDirectory
            audioURL = tempDir.appendingPathComponent(UUID().uuidString + ".m4a")
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioURL!, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            startMonitoringVolume()
            print("Recording started at: \(audioURL!)")
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        stopMonitoringVolume()
    }
    
    private func startMonitoringVolume() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.audioRecorder?.updateMeters()
            self.volume = self.audioRecorder?.averagePower(forChannel: 0) ?? 0
            self.volume = max(0.0, min(1.0, (self.volume + 50) / 50)) // Normalize to 0...1
        }
    }
    
    private func stopMonitoringVolume() {
        timer?.invalidate()
        timer = nil
    }
}
