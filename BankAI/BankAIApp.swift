//
//  BankAIApp.swift
//  BankAI
//
//  Created by Muhammadjon Madaminov on 19/04/25.
//

import SwiftUI


// Home -> User Details -> Call
//
@main
struct BankAIApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
            .preferredColorScheme(.light)
        }
    }
}
