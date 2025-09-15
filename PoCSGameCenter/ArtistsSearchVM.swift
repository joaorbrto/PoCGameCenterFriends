//
//  ArtistsSearchVM.swift
//  PoCSGameCenter
//
//  Created by Joao Roberto Fernandes Magalhaes on 10/09/25.
//

import Foundation

@MainActor
final class ArtistsSearchVM: ObservableObject {
    @Published var query: String = ""
    @Published var results: [SPArtist] = []
    @Published var loading = false
    @Published var error: String?

    func search() {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { results = []; error = nil; return }
        loading = true; error = nil
        Task {
            do {
                let items = try await SpotifyArtistsAPI.shared.searchArtists(query: q)
                self.results = items
            } catch SPAPIError.unauthorized {
                self.error = "Sessão Spotify expirada. Refaça a conexão."
            } catch {
                self.error = "Falha ao buscar: \(error.localizedDescription)"
            }
            self.loading = false
        }
    }
}
