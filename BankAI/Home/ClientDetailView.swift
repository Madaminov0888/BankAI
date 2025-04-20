//
//  ClientDetailView.swift
//  BankAI
//
//  Created by Muhammadjon Madaminov on 20/04/25.
//


// Views/ClientDetailView.swift
import SwiftUI

struct ClientDetailView: View {
    let client: Client
    var namespace: Namespace.ID
    
    @State private var showCallFullScreen: Bool = false

    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.ultraThinMaterial)
                            .frame(height: 300)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: .white.opacity(0.5), radius: 8, x: -6, y: -6)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 6, y: 6)

                        VStack(spacing: 16) {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.pink, .orange],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                .matchedGeometryEffect(id: "avatar\(client.id)", in: namespace)
                                .frame(width: 120, height: 120)
                                .overlay(Text(client.fullName.prefix(1))
                                            .font(.largeTitle)
                                            .foregroundColor(.white)
                                )

                            Text(client.fullName)
                                .font(.title).bold()
                                .matchedGeometryEffect(id: "name\(client.id)", in: namespace)
                                .foregroundStyle(Color(.lightGray))

                            Text("\(client.age) years old • \(client.preferredLang.capitalized)")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal)

                    // Calls History
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Previous Calls")
                            .font(.headline)
                            .foregroundStyle(.white)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(client.previousCalls, id: \.callId) { call in
                                    CallCardView(call: call)
                                        .padding()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Action Buttons
                    HStack(spacing: 24) {
                        DetailActionButton(label: "Start Call", systemImage: "phone.fill") {
                            self.showCallFullScreen.toggle()
                        }
                        DetailActionButton(label: "Add Note", systemImage: "pencil") {
                            
                        }
                    }
                    .padding(.bottom, 50)
                    .padding(.horizontal)
                }
            }
        }
        .toolbarBackground(.ultraThinMaterial.opacity(0.1), for: .navigationBar)
        .navigationBarBackButtonHidden(false)
        .fullScreenCover(isPresented: $showCallFullScreen) {
            CallView(client: client)
        }
    }
}


