//
//  DetailActionButton.swift
//  BankAI
//
//  Created by Muhammadjon Madaminov on 20/04/25.
//


// Views/DetailActionButton.swift
import SwiftUI

struct DetailActionButton: View {
    let label: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: systemImage)
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .background(Color.offWhite) // define offWhite in Color extension
        .cornerRadius(20)
        .shadow(color: .white.opacity(0.7), radius: 6, x: -6, y: -6)
        .shadow(color: .black.opacity(0.2), radius: 6, x: 6, y: 6)
    }
}
