//
//  ArtistDetailView.swift
//  PoCSGameCenter
//
//  Created by Joao Roberto Fernandes Magalhaes on 10/09/25.
//

//
//  ArtistDetailView.swift
//  PoCSGameCenter
//

import SwiftUI

struct ArtistDetailView: View {
    let artist: SPArtist
    @State private var albums: [SPAlbum] = []
    @State private var loadingAlbums = true
    @State private var albumsError: String?

    // MARK: - Helpers

    /// Retorna a URL da MAIOR imagem (por área) de um array do Spotify
    private func bestImageURL(from images: [SPImage]) -> URL? {
        guard let best = images.max(by: { (a, b) -> Bool in
            let aw = a.width ?? 0
            let ah = a.height ?? 0
            let bw = b.width ?? 0
            let bh = b.height ?? 0
            return (aw * ah) < (bw * bh)
        }) else { return nil }
        return URL(string: best.url)
    }

    /// Foto de perfil (maior)
    private var profileURL: URL? {
        bestImageURL(from: artist.images)
    }

    /// URL da capa (maior) de um álbum
    private func coverURL(for album: SPAlbum) -> URL? {
        bestImageURL(from: album.images)
    }

    /// Cartão de foto grande com o mesmo estilo em todas
    @ViewBuilder
    private func BigPhoto(_ url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ZStack { Rectangle().fill(.gray.opacity(0.15)); ProgressView() }
            case .success(let image):
                image.resizable().scaledToFit()
            case .failure:
                ZStack { Rectangle().fill(.gray.opacity(0.15)); Image(systemName: "photo") }
            @unknown default:
                Color.clear
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - View

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(artist.name).font(.title).bold()

                if let p = profileURL {
                    BigPhoto(p)
                }

                if loadingAlbums {
                    ProgressView("Carregando…")
                } else if let albumsError {
                    Text(albumsError).foregroundStyle(.red)
                } else if albums.isEmpty {
                    Text("Nenhuma capa encontrada.").foregroundStyle(.secondary)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(albums) { album in
                            if let u = coverURL(for: album) {
                                BigPhoto(u)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Imagens")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadAlbums() }
    }

    // MARK: - Data

    private func loadAlbums() async {
        loadingAlbums = true
        albumsError = nil
        do {
            let list = try await SpotifyArtistsAPI.shared.fetchArtistAlbums(
                artistId: artist.id,
                includeGroups: "album,single" // adicione "compilation,appears_on" se quiser
            )
            await MainActor.run {
                self.albums = list
                self.loadingAlbums = false
            }
        } catch SPAPIError.unauthorized {
            await MainActor.run {
                self.albums = []
                self.loadingAlbums = false
                self.albumsError = "Sessão Spotify expirada. Refaça a conexão."
            }
        } catch {
            await MainActor.run {
                self.albums = []
                self.loadingAlbums = false
                self.albumsError = "Falha ao carregar álbuns: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    ArtistDetailView(artist: .init(id: "1", name: "Artista", images: []))
} 

#Preview {
    ArtistDetailView(artist: .init(id: "1", name: "Artista", images: []))
}
