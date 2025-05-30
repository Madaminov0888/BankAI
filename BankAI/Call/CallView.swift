//
//  CallView.swift
//  BankAI
//
//  Created by Akbar Khusanbaev on 19/04/25.
//
import SwiftUI
import AVKit
import Combine

struct CallView: View {
    let client: Client
    @State var observable = CallObservable()
    @StateObject private var audioRecorder = AudioRecorder()
    @Environment(\.dismiss) private var dismiss
    @Namespace private var buttonAnim
    @State private var player: AVAudioPlayer? = nil
    @State private var playerIsDisabled: Bool = false

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            VStack(spacing: 40) {
                // Always-visible frosted-glass avatar
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 160, height: 160)
                    .overlay(
                        Text(String(client.fullName.prefix(1)))
                            .font(.system(size: 68, weight: .bold))
                            .foregroundColor(.primary)
                    )
                    .padding(.top, 60)
                    .onAppear {
                        audioRecorder.checkPermissions()
                    }

                Spacer()

                if !observable.isAnswered {
                    // Incoming call UI
                    VStack(spacing: 16) {
                        Text("Incoming Call")
                            .font(.title2)
                            .foregroundColor(.white)

                        HStack(spacing: 80) {
                            // Decline button (source when incoming)
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "phone.down.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.red)
                                    .clipShape(Circle())
                            }
                            .matchedGeometryEffect(id: "decline", in: buttonAnim, isSource: !observable.isAnswered)

                            // Answer button
                            Button {
                                withAnimation(.spring()) {
                                    observable.startCall()
                                }
                            } label: {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.green)
                                    .clipShape(Circle())
                            }
                            .matchedGeometryEffect(id: "answer", in: buttonAnim, isSource: !observable.isAnswered)
                        }
                    }
                    .transition(.opacity)
                } else {
                    // Active call UI
                    callDetails()
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .ignoresSafeArea()
        .animation(.spring(), value: observable.isAnswered)
        .onChange(of: audioRecorder.audioURL) { oldValue, newValue in
            if let audioURL = newValue {
                print(audioURL)
                if let lastTemp = observable.history.last {
                    Task {
                        switch lastTemp.questionType {
                        case .welcomeAndPreferredLanguage(let bank, let client):
                            await observable.choosePreferredLanguage(audioUrl: audioURL)
                        case .isConvenientTime(let language):
                            await observable.askIfConvenientToTalkRightNow()
                        case .whatIsConvenientTime(let language):
                            await observable.userRespondsWhenHeCanTalk(audioURL: audioURL)
                        case .
                        @unknown default:
                            break
                        }
                    }
                }
            }
        }
        .onChange(of: observable.isAnswered) { oldValue, newValue in
            if newValue {
                Task {
                    await observable.generateIntroduction(clientName: client.fullName)
                }
            }
        }
        .onChange(of: observable.introductionAudioGenerated) { oldValue, newValue in
            if let newValue {
                player = try? AVAudioPlayer(contentsOf: newValue)
                player?.play()
            }
        }
        .onChange(of: observable.preferredLanguageSelected) { oldValue, newValue in
            if let newValue {
                player = try? AVAudioPlayer(contentsOf: newValue)
                player?.play()
            }
        }
        .onChange(of: observable.isConvenientTimeAudioGenerated) { oldValue, newValue in
            if let newValue {
                player = try? AVAudioPlayer(contentsOf: newValue)
                player?.play()
            }
        }
        .onChange(of: observable.userCanTalkRightNow) { oldValue, newValue in
            if let newValue {
                //..
            } else {
                Task {
                    await observable.askWhatIsConvenientTime()
                }
            }
        }
        .onChange(of: observable.askCanTalkInTimeAudio) { oldValue, newValue in
            if let newValue {
                player = try? AVAudioPlayer(contentsOf: newValue)
                player?.play()
            }
        }
    }
}



extension CallView {
    @ViewBuilder private func callDetails() -> some View {
        VStack(spacing: 30) {
            // Call timer
            Text(observable.formattedTime)
                .font(.title)
                .bold()
                .foregroundColor(.white)

            // Hold-to-speak button with reactive scale
            Button(action: {}) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .padding(40)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .scaleEffect(1 + CGFloat(max(audioRecorder.volume, 0.1)) * 1.0)
                    .animation(.easeOut(duration: 0.05), value: audioRecorder.volume)
            }
            .onLongPressGesture(
                minimumDuration: 0.1,
                pressing: { isPressing in
                    if isPressing {
                        audioRecorder.startRecording()
                    } else {
                        audioRecorder.stopRecording()
                    }
                },
                perform: {}
            )

            // End call button (source when active)
            Button {
                withAnimation(.spring()) {
                    observable.endCall()
                    audioRecorder.stopRecording()
                    dismiss()
                }
            } label: {
                Image(systemName: "phone.down.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .clipShape(Circle())
            }
            .matchedGeometryEffect(id: "decline", in: buttonAnim, isSource: observable.isAnswered)
        }
        .transition(.scale)
    }
}

#Preview {
    CallView(client: Client(
        id: 12,
        fullName: "SHARBATBORMI",
        age: 14,
        preferredLang: "Anjancha",
        previousCalls: [],
        currentCall: nil
    ))
}
