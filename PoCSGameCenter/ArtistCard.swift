//
//  ArtistCard.swift
//  PoCSGameCenter
//
//  Created by Joao Roberto Fernandes Magalhaes on 10/09/25.
//

import SwiftUI

struct ArtistCard: View {
    let artist: SPArtist

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Preview: maior imagem do Spotify (apenas para o card)
            let preview = artist.images.max {
                (($0.width ?? 0) * ($0.height ?? 0)) < (($1.width ?? 0) * ($1.height ?? 0))
            }?.url

            if let urlStr = preview, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack { Rectangle().fill(.gray.opacity(0.2)); ProgressView() }
                    case .success(let img):
                        img.resizable().scaledToFill()
                    case .failure:
                        ZStack { Rectangle().fill(.gray.opacity(0.2)); Image(systemName: "photo") }
                    @unknown default: Color.clear
                    }
                }
                .frame(height: 150).clipped().cornerRadius(12)
            } else {
                ZStack {
                    Rectangle().fill(.gray.opacity(0.15))
                    Image(systemName: "person.crop.square").imageScale(.large).foregroundStyle(.secondary)
                }
                .frame(height: 150).cornerRadius(12)
            }

            Text(artist.name).font(.headline).lineLimit(1)

            // Botão explícito para ir ao detalhe
            NavigationLink {
                ArtistDetailView(artist: artist)
            } label: {
                Label("Ver fotos e capas", systemImage: "photo.on.rectangle")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 1, y: 1)
    }
}

#Preview {
    ArtistCard(artist: .init(id: "1", name: "Artista", images: []))
        .padding()
}
