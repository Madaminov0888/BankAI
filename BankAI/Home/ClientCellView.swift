//
//  ClientCellView.swift
//  BankAI
//
//  Created by Muhammadjon Madaminov on 20/04/25.
//


// Views/ClientCellView.swift
import SwiftUI

struct ClientCardView: View {
    let client: Client
    var namespace: Namespace.ID

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .white.opacity(0.6), radius: 6, x: -4, y: -4)
                .shadow(color: .black.opacity(0.3), radius: 6, x: 4, y: 4)

            HStack(spacing: 16) {
                Circle()
                    .fill(LinearGradient(
                        colors: [.pink, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .matchedGeometryEffect(id: "avatar\(client.id)", in: namespace)
                    .frame(width: 60, height: 60)
                    .overlay(Text(client.fullName.prefix(1))
                                .font(.title)
                                .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(client.fullName)
                        .font(.headline)
                        .matchedGeometryEffect(id: "name\(client.id)", in: namespace)
                    Text("\(client.age) yrs • \(client.preferredLang.uppercased())")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let status = client.currentCall?.callStatus {
                    Text(status.capitalized)
                        .font(.caption).bold()
                        .padding(8)
                        .background(Color.accentColor.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .padding()
        }
        .frame(height: 100)
    }
}
