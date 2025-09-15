//
//  SpotifyPlaysService.swift
//  PoCSGameCenter
//
//  Created by Joao Roberto Fernandes Magalhaes on 10/09/25.
//

import Foundation

import Foundation

struct SpotifyPlayHistory: Decodable {
    struct Item: Decodable {
        struct Track: Decodable { let id: String; let duration_ms: Int }
        let track: Track
        let played_at: String
    }
    let items: [Item]
}

struct SpotifyAPIErrorEnvelope: Decodable {
    struct Err: Decodable { let status: Int; let message: String }
    let error: Err
}

final class SpotifyPlaysService {
    static let shared = SpotifyPlaysService()
    private init() {}

    func weeklyPlaysCount() async throws -> Int {
        let token = try await SpotifyTokenService.shared.refreshIfNeeded()

        var comps = URLComponents(string: "https://api.spotify.com/v1/me/player/recently-played")!
        comps.queryItems = [URLQueryItem(name: "limit", value: "50")]

        var req = URLRequest(url: comps.url!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await URLSession.shared.data(for: req)
        let http = resp as! HTTPURLResponse

        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "<binário>"
            print("Spotify API FAIL \(http.statusCode): \(body)")

            if let env = try? JSONDecoder().decode(SpotifyAPIErrorEnvelope.self, from: data) {
                throw NSError(domain: "spotify-api", code: env.error.status,
                              userInfo: [NSLocalizedDescriptionKey: env.error.message])
            }

            if http.statusCode == 401 {
                throw NSError(domain: "spotify-api", code: 401,
                              userInfo: [NSLocalizedDescriptionKey: "Token expirado ou inválido. Reconecte o Spotify."])
            }
            if http.statusCode == 403 {
                throw NSError(domain: "spotify-api", code: 403,
                              userInfo: [NSLocalizedDescriptionKey: "Permissão insuficiente. Garanta o escopo user-read-recently-played."])
            }
            throw NSError(domain: "spotify-api", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "Falha \(http.statusCode) ao consultar o histórico."])
        }

        let respObj = try JSONDecoder().decode(SpotifyPlayHistory.self, from: data)

        let cal = Calendar(identifier: .iso8601)
        let week = cal.dateInterval(of: .weekOfYear, for: Date())!

        return respObj.items
            .compactMap { ISO8601DateFormatter().date(from: $0.played_at) }
            .filter { week.contains($0) }
            .count
    }
}
