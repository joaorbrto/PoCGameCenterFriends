//
//  SpotifyLeaderboardView.swift
//  PoCSGameCenter
//
//  Created by Joao Roberto Fernandes Magalhaes on 10/09/25.
//

import SwiftUI

struct SpotifyLeaderboardView: View {
    @StateObject private var auth = SpotifyAuthManager()
    private let api = SpotifyAPIClient()
    @State private var entries: [SpotifyLeaderboardEntry] = []
    @State private var loading = false
    @State private var errorMsg: String?
    @State private var isCounting = false

    // Identifique seu usuário (substitua pelo ID real no seu app)
    private let appUserId = "user_123"

    var body: some View {
        List {
            Section("Spotify") {
                if auth.isConnected {
                    HStack {
                        Label("Conectado", systemImage: "checkmark.seal.fill")
                        Spacer()
                        Text(auth.displayName ?? "Você").foregroundStyle(.secondary)
                    }
                    Button {
                        loadBoard()
                    } label: {
                        loading ? AnyView(ProgressView()) :
                                  AnyView(Label("Atualizar ranking", systemImage: "arrow.clockwise"))
                    }
                } else {
                    Button {
                        auth.connect(appUserId: appUserId)
                    } label: {
                        Label("Conectar Spotify", systemImage: "link")
                    }
                }
                if let errorMsg { Text(errorMsg).foregroundStyle(.red) }
            }

            Section("Top (músicas na última semana)") {
                if entries.isEmpty {
                    Text("Sem dados ainda. Conecte e aguarde a coleta do servidor.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entries) { e in
                        HStack {
                            Text("#\(e.rank)").frame(width: 36, alignment: .leading)
                            VStack(alignment: .leading) {
                                Text(e.displayName).font(.headline)
                                Text("\(Int(e.value)) músicas")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle("Ranking 🎧")
        .onAppear { if auth.isConnected { loadBoard() } }
    }

    private func loadBoard() {
        loading = true; errorMsg = nil
        api.fetchLeaderboard(window: "weekly", metric: "plays") { result in
            DispatchQueue.main.async {
                loading = false
                switch result {
                case .success(let list): entries = list
                case .failure(let err): errorMsg = err.localizedDescription
                }
            }
        }
    }
}

#Preview {
    SpotifyLeaderboardView()
}
