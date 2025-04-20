//
//  HomeObservable.swift
//  BankAI
//
//  Created by Akbar Khusanbaev on 19/04/25.
//

import Observation

/// ViewModel for the Home screen, exposing client data and search/filter logic.
/// Marked with `@Observable` to automatically publish changes to any observing views.
@Observable
final class HomeObservable {
    // MARK: - Published Properties

    /// The complete list of clients loaded from the network.
    private(set) var clients: [Client] = []

    /// Flag indicating whether a network fetch is in progress.
    var isLoading: Bool = false

    /// Current text in the search field, used to filter `clients`.
    var searchText: String = ""

    // MARK: - Dependencies

    /// Network service abstraction for fetching and posting clients.
    let manager: NetworkServiceProtocol

    // MARK: - Initialization

    /// Creates a new `HomeObservable`, optionally injecting a custom network service (e.g., for testing).
    /// - Parameter manager: Conforms to `NetworkServiceProtocol`. Defaults to production `NetworkService()`.
    init(manager: NetworkServiceProtocol = NetworkService()) {
        self.manager = manager
    }

    // MARK: - Computed Properties

    /// Returns the list of clients filtered by `searchText` (name or preferred language).
    /// If `searchText` is empty, returns the full `clients` list.
    var filteredClients: [Client] {
        guard !searchText.isEmpty else {
            return clients
        }
        return clients.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            $0.preferredLang.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Network Operations

    /// Fetches the list of clients asynchronously and updates `clients` on the main actor.
    /// - Note: If an error occurs, it logs to the console.
    func fetchClients() async {
        do {
            // Retrieve clients from the network
            let clients = try await manager.fetchData(for: .clients, type: [Client].self)
            // Ensure UI updates happen on the main thread
            await MainActor.run {
                self.clients = clients
            }
        } catch {
            // TODO: Replace print with user-facing error handling as needed
            print(#function, error)
        }
    }

    /// Posts a new call result or client data to the server.
    /// - Parameter postRequest: Encodable request object containing call result details.
    func postClient(_ postRequest: PostCallResultRequest) async {
        do {
            try await manager.postData(for: .clients, data: postRequest)
        } catch {
            // TODO: Handle errors appropriately (alerts, retry logic, etc.)
            print(#function, error)
        }
    }
}
