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
    let colors = [Color.purple, Color.blue, Color.teal, Color.pink]

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: animate ? colors : colors.reversed()),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animate)
        .onAppear { animate.toggle() }
        .ignoresSafeArea()
    }
}
