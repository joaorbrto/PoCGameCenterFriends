//
//  SpotifyArtistsAPI.swift
//  PoCSGameCenter
//
//  Created by Joao Roberto Fernandes Magalhaes on 10/09/25.
//

import Foundation

final class SpotifyArtistsAPI {
    static let shared = SpotifyArtistsAPI()
    private init() {}

    /// Busca artistas usando o token do usuário (PKCE)
    func searchArtists(query: String, limit: Int = 24) async throws -> [SPArtist] {
        let token = try await SpotifyTokenService.shared.refreshIfNeeded()

        var comps = URLComponents(string: "https://api.spotify.com/v1/search")!
        comps.queryItems = [
            .init(name: "q", value: query),
            .init(name: "type", value: "artist"),
            .init(name: "limit", value: String(limit))
        ]
        var req = URLRequest(url: comps.url!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw SPAPIError.badResponse }
        guard http.statusCode == 200 else {
            if http.statusCode == 401 { throw SPAPIError.unauthorized }
            throw SPAPIError.badResponse
        }
        return try JSONDecoder().decode(SPSearchArtistsResponse.self, from: data).artists.items
    }

    /// Busca capas de álbuns do artista (pagina até esgotar), dedup e ordena por data desc.
    func fetchArtistAlbums(
        artistId: String,
        includeGroups: String = "album,single",
        market: String = "from_token"
    ) async throws -> [SPAlbum] {
        let token = try await SpotifyTokenService.shared.refreshIfNeeded()

        var results: [SPAlbum] = []
        var nextURL: URL? = {
            var comps = URLComponents(string: "https://api.spotify.com/v1/artists/\(artistId)/albums")!
            comps.queryItems = [
                .init(name: "include_groups", value: includeGroups),
                .init(name: "limit", value: "50"),
                .init(name: "market", value: market)
            ]
            return comps.url
        }()

        while let url = nextURL {
            var req = URLRequest(url: url)
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
                throw SPAPIError.badResponse
            }
            let page = try JSONDecoder().decode(SPArtistAlbumsResponse.self, from: data)
            results.append(contentsOf: page.items)
            nextURL = page.next.flatMap(URL.init(string:))
        }

        // Dedup por ID e ordena por release_date (string YYYY|YYYY-MM|YYYY-MM-DD) decrescente
        let unique = Dictionary(grouping: results, by: { $0.id }).compactMap { $0.value.first }
        return unique.sorted { (a, b) in (a.release_date ?? "") > (b.release_date ?? "") }
    }
}
