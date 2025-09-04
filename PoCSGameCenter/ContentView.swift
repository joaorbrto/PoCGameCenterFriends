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
    @State private var leaderboardID: String = ""
    @State private var isLoadingFriends = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Sessão")) {
                    HStack {
                        Label("Status", systemImage: gc.isAuthenticated ? "checkmark.seal.fill" : "xmark.seal")
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
                    .disabled(gc.isAuthenticated) // evita spam quando já autenticado
                }

                Section(header: Text("Leaderboards")) {
                    Button {
                        // Abre o painel de leaderboards
                        gc.presentFriendsList() // no seu manager, este método já apresenta state: .leaderboards
                    } label: {
                        Label("Abrir Leaderboards", systemImage: "list.number")
                    }

                    HStack {
                        TextField("Leaderboard ID (ex.: com.seujogo.pontos)", text: $leaderboardID)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                        if !leaderboardID.isEmpty {
                            Button {
                                leaderboardID = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button {
                        if #available(iOS 14.0, *) {
                            gc.presentLeaderboard(id: leaderboardID)
                        }
                    } label: {
                        Label("Abrir Leaderboard por ID", systemImage: "arrow.forward.circle")
                    }
                    .disabled(!gc.isAuthenticated || leaderboardID.isEmpty)
                }

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
                            Text("Carregando…")
                                .foregroundStyle(.secondary)
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
#Preview{
    ContentView()
}
