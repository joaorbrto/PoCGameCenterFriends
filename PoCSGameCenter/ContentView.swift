//
//  ContentView.swift
//  PoCSGameCenter
//
//  Created by Joao Roberto Fernandes Magalhaes on 04/09/25.
//

import SwiftUI
import GameKit

struct ContentView: View {
    @StateObject private var gc = GameCenterManager()
    @StateObject private var auth = SpotifyAuthManager()
    @State private var leaderboardID: String = ""
    @State private var isLoadingFriends = false
    @State private var isCounting = false
    private let spotifyGCLeaderboardID = "com.pocsgamecenter.spotifyplays.weekly"

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Sessão")) {
                    HStack {
                        Label("Status GC", systemImage: gc.isAuthenticated ? "checkmark.seal.fill" : "xmark.seal")
                        Spacer()
                        Text(gc.isAuthenticated ? "Autenticado" : "Não autenticado")
                            .foregroundStyle(gc.isAuthenticated ? .green : .secondary)
                    }

                    if let error = gc.errorMessage, !error.isEmpty {
                        Text(error)
                            .font(.callout)
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button {
                        gc.signIn()
                    } label: {
                        Label("Entrar no Game Center", systemImage: "person.crop.circle.badge.checkmark")
                    }
                    .disabled(gc.isAuthenticated)
                }

                // Sessão Spotify (POC)
                Section(header: Text("Spotify")) {
                    HStack {
                        Label(auth.isConnected ? "Conectado" : "Desconectado",
                              systemImage: auth.isConnected ? "checkmark.seal.fill" : "bolt.slash")
                        Spacer()
                        Text(auth.displayName ?? (auth.isConnected ? "Conectado ao Spotify" : ""))
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        // Passe seu ID interno se tiver (aqui é só placeholder)
                        auth.connect(appUserId: "user_123")
                    } label: {
                        Label("Conectar Spotify", systemImage: "link")
                    }
                    .disabled(auth.isConnected)
                }

                // Ranking Spotify via Game Center (POC)
                Section(header: Text("Ranking Spotify no Game Center (POC)")) {
                    Button {
                        guard gc.isAuthenticated else { gc.errorMessage = "Entre no Game Center."; return }
                        guard auth.isConnected else { gc.errorMessage = "Conecte o Spotify antes."; return }

                        isCounting = true
                        Task {
                            do {
                                let plays = try await SpotifyPlaysService.shared.weeklyPlaysCount()
                                await MainActor.run {
                                    gc.submitSpotifyPlaysToGC(leaderboardID: spotifyGCLeaderboardID, plays: plays)
                                    isCounting = false
                                }
                            } catch {
                                await MainActor.run {
                                    gc.errorMessage = (error as NSError).localizedDescription
                                    isCounting = false
                                }
                            }
                        }
                    } label: {
                        if isCounting {
                            HStack { ProgressView(); Text("Calculando e enviando…") }
                        } else {
                            Label("Enviar minhas músicas (semana) ao GC", systemImage: "paperplane.fill")
                        }
                    }
                    .disabled(!gc.isAuthenticated || !auth.isConnected)

                    Button {
                        if #available(iOS 14.0, *) {
                            gc.presentLeaderboard(id: spotifyGCLeaderboardID,
                                                  playerScope: .friendsOnly,
                                                  timeScope: .week)
                        }
                    } label: {
                        Label("Ver ranking (amigos/semana)", systemImage: "list.number")
                    }
                    .disabled(!gc.isAuthenticated)
                }

                // Amigos (GC)
                Section(header: Text("Amigos")) {
                    Button {
                        isLoadingFriends = true
                        gc.ensureAndLoadFriends()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            isLoadingFriends = false
                        }
                    } label: {
                        Label("Carregar amigos", systemImage: "person.2")
                    }
                    .disabled(!gc.isAuthenticated)

                    if isLoadingFriends {
                        HStack {
                            ProgressView()
                            Text("Carregando…").foregroundStyle(.secondary)
                        }
                    }

                    if gc.friends.isEmpty {
                        Text("Nenhum amigo carregado.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(gc.friends, id: \.gamePlayerID) { player in
                            HStack {
                                Image(systemName: "person.crop.circle")
                                Text(player.displayName)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                    }
                }
            }
            .navigationTitle("Game Center")
        }
    }
}

#Preview {
    ContentView()
}
