//
//  HomeView.swift
//  BankAI
//
//  Created by Akbar Khusanbaev on 19/04/25.
//
import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeObservable()
    @Namespace private var animation

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()

                VStack {

                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                            .padding()
                    } else if viewModel.filteredClients.isEmpty {
                        Text("No clients found.")
                            .foregroundStyle(.white.opacity(0.8))
                            .padding()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 20) {
                                ForEach(viewModel.filteredClients) { client in
                                    NavigationLink {
                                        ClientDetailView(client: client, namespace: animation)
                                    } label: {
                                        ClientCardView(client: client, namespace: animation)
                                    }
                                }
                            }
                            .padding()
                        }
                        .refreshable {
                            await viewModel.fetchClients()
                        }
                    }
                }
            }
            .tint(.black)
            // — Applying searchable here
            .searchable(text: $viewModel.searchText, prompt: "Search Clients")
            // — Show the bar so that the search field can appear —
            .navigationBarHidden(false)
            .task { await viewModel.fetchClients() }
        }
        .navigationTitle("Clients")
        .toolbarBackground(.ultraThinMaterial.opacity(0.1), for: .navigationBar)
        .navigationBarBackButtonHidden(true)

    }
}


#Preview {
    NavigationStack {
        HomeView()
    }
}
