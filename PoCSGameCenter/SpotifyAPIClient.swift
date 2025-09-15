//
//  SpotifyAPIClient.swift
//  PoCSGameCenter
//
//  Created by Joao Roberto Fernandes Magalhaes on 10/09/25.
//

import Foundation

struct SpotifyLeaderboardEntry: Decodable, Identifiable {
    let id: String
    let displayName: String
    let rank: Int
    let value: Double       
}

final class SpotifyAPIClient {
    private let base = URL(string: "https://SEU-BACKEND")!

    func fetchLeaderboard(window: String = "weekly",
                          metric: String = "plays",
                          completion: @escaping (Result<[SpotifyLeaderboardEntry], Error>) -> Void) {
        var comps = URLComponents(url: base.appendingPathComponent("/leaderboard"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            .init(name: "window", value: window),
            .init(name: "metric", value: metric)
        ]
        let req = URLRequest(url: comps.url!)

        URLSession.shared.dataTask(with: req) { data, _, err in
            if let err = err { completion(.failure(err)); return }
            guard let data = data else {
                completion(.failure(NSError(domain: "no-data", code: 0))); return
            }
            do {
                let list = try JSONDecoder().decode([SpotifyLeaderboardEntry].self, from: data)
                completion(.success(list))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
