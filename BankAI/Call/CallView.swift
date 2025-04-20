//
//  CallView.swift
//  BankAI
//
//  Created by Akbar Khusanbaev on 19/04/25.
//

import SwiftUI

struct CallView: View {
    let client: Client
    @State var observable = CallObservable()
    @Environment(\.dismiss) private var dismiss
    @Namespace private var buttonAnim

    var body: some View {
        ZStack {
            // Animated gradient backdrop
            AnimatedGradientBackground()

            VStack(spacing: 40) {
                // Profile avatar always visible from the start
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 150, height: 150)
                    .overlay(
                        Text(String(client.fullName.prefix(1)))
                            .font(.system(size: 64, weight: .bold))
                            .foregroundColor(.primary)
                    )
                    .padding(.top, 260)

                Spacer()

                if !observable.isAnswered {
                    // Incoming call UI
                    VStack(spacing: 20) {
                        Text("Incoming Call")
                            .font(.title2)
                            .foregroundColor(.white)

                        HStack(spacing: 80) {
                            // Decline button
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
                            .matchedGeometryEffect(id: "decline", in: buttonAnim)
                            

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
                            .matchedGeometryEffect(id: "answer", in: buttonAnim)
                        }
                    }
                } else {
                    
                    // Active call UI
                    VStack(spacing: 30) {
                        // Call timer
                        Text(observable.formattedTime)
                            .font(.title)
                            .bold()
                            .foregroundColor(.white)

                        // Hold-to-speak button
                        Button {
                            // speaking action
                        } label: {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                                .padding(40)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .onLongPressGesture(minimumDuration: 0.1) {
                            // finalize speak action
                        }

                        // End call button
                        Button {
                            withAnimation {
                                observable.endCall()
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
                        .matchedGeometryEffect(id: "decline", in: buttonAnim)
                    }
                }

                Spacer()
            }
            .padding(.horizontal)
        }
        .ignoresSafeArea()
        .animation(.spring(), value: observable.isAnswered)
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
