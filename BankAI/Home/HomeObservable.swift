//
//  HomeObservable.swift
//  BankAI
//
//  Created by Akbar Khusanbaev on 19/04/25.
//

import Observation

@Observable
final class HomeObservable {
    private(set) var clients: [Client] = []
    var isLoading: Bool = false
    var searchText: String = ""
    
    let manager: NetworkServiceProtocol
    
    init(manager: NetworkServiceProtocol = NetworkService()) {
        self.manager = manager
    }
    
    var filteredClients: [Client] {
        guard !searchText.isEmpty else { return clients }
        return clients.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            $0.preferredLang.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    
    func fetchClients() async {
        do {
            let clients = try await manager.fetchData(for: .clients, type: [Client].self)
            await MainActor.run {
                self.clients = clients
            }
        } catch {
            print(#function, error)
        }
    }
    
    func postClient(_ postRequest: PostCallResultRequest) async {
        do {
            try await manager.postData(for: .clients, data: postRequest)
        } catch {
            print(#function, error)
        }
    }
    
}
