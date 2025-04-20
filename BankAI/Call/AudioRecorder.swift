//
//  AudioRecorder.swift
//  BankAI
//
//  Created by Muhammadjon Madaminov on 20/04/25.
//


import Foundation
import AVKit

/// `AudioRecorder` manages audio recording sessions and volume metering.
/// Conforms to `ObservableObject` to publish real-time volume updates to SwiftUI views.
final class AudioRecorder: ObservableObject {
    // MARK: - Private Properties

    /// Underlying `AVAudioRecorder` instance handling file recording.
    private var audioRecorder: AVAudioRecorder?

    /// Timer used to periodically poll audio power levels.
    private var timer: Timer?

    // MARK: - Published Properties

    /// Normalized recording volume level (0.0 to 1.0).
    @Published var volume: Float = 0.0

    /// File URL where the recorded audio is stored.
    var audioURL: URL?

    // MARK: - Permission Handling

    /// Requests microphone permission from the user.
    /// Prints a message if access is denied.
    func checkPermissions() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if !granted {
                print("Microphone permission denied.")
            }
        }
    }

    // MARK: - Recording Control

    /// Starts an audio recording session.
    /// Configures the audio session, sets output URL and settings, and begins metering.
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            // Configure session for recording and playback
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)

            // Create a temporary file URL for audio
            let tempDir = FileManager.default.temporaryDirectory
            audioURL = tempDir.appendingPathComponent(UUID().uuidString + ".m4a")

            // Recorder settings: AAC, 44.1kHz, stereo, high quality
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            // Initialize recorder
            audioRecorder = try AVAudioRecorder(url: audioURL!, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()

            // Begin updating volume property
            startMonitoringVolume()
            print("Recording started at: \(audioURL!)")
        } catch {
            // Log errors initializing recording
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }

    /// Stops the recording session and invalidates the metering timer.
    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        stopMonitoringVolume()
    }

    // MARK: - Volume Monitoring

    /// Sets up a timer to update `volume` every 0.1 seconds based on audio meters.
    private func startMonitoringVolume() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.audioRecorder?.updateMeters()
            // Convert decibels (-50...0) to normalized 0...1 range
            let power = self.audioRecorder?.averagePower(forChannel: 0) ?? -50
            let normalized = max(0.0, min(1.0, (power + 50) / 50))
            self.volume = normalized
        }
    }

    /// Invalidates the volume monitoring timer.
    private func stopMonitoringVolume() {
        timer?.invalidate()
        timer = nil
    }
}
