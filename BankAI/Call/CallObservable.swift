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
}
