//
//  ArtistsSearchView.swift
//  PoCSGameCenter
//
//  Created by Joao Roberto Fernandes Magalhaes on 10/09/25.
//

import SwiftUI

struct ArtistsSearchView: View {
    @StateObject private var vm = ArtistsSearchVM()
    private let cols = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack {
                    TextField("Buscar artista no Spotify…", text: $vm.query)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button { vm.search() } label: {
                        Image(systemName: "magnifyingglass").padding(8)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)

                if vm.loading { ProgressView("Carregando…").padding(.top, 8) }
                if let err = vm.error { Text(err).foregroundStyle(.red).padding(.horizontal) }

                ScrollView {
                    LazyVGrid(columns: cols, spacing: 16) {
                        ForEach(vm.results) { artist in
                            ArtistCard(artist: artist)
                        }
                    }
                    .padding()
                }
                .refreshable { vm.search() }
            }
            .navigationTitle("Artistas")
        }
    }
}

#Preview { ArtistsSearchView() }
