//
//  CallCardView.swift
//  BankAI
//
//  Created by Muhammadjon Madaminov on 20/04/25.
//


// Views/CallCardView.swift
import SwiftUI

struct CallCardView: View {
    let call: Call

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(call.notificationType.capitalized)
                .font(.caption).bold()
            Text(call.callDatetime.toReadableDate())
                .font(.footnote)
            if let result = call.callResult {
                Text("Result: \(result.capitalized)")
                    .font(.caption2)
            }
        }
        .padding()
        .frame(width: 140)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .white.opacity(0.4), radius: 4, x: -4, y: -4)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 4, y: 4)
    }
}
