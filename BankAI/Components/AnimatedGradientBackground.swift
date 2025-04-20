//
//  AnimatedGradientBackground.swift
//  BankAI
//
//  Created by Muhammadjon Madaminov on 20/04/25.
//


// Utilities/AnimatedGradientBackground.swift
import SwiftUI

struct AnimatedGradientBackground: View {
    @State private var animate = false
    let colors: [Color] = [.purple, .blue, .teal, .pink]

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: animate ? colors : colors.reversed()),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            // This line only runs once when the view appears:
            withAnimation(.easeInOut(duration: 8)
                            .repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}
