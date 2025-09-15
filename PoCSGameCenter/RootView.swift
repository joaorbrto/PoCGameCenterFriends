//
//  RootView.swift
//  PoCSGameCenter
//
//  Created by Joao Roberto Fernandes Magalhaes on 10/09/25.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NavigationView { ContentView() }
                .tabItem {
                    Label("Game Center", systemImage: "gamecontroller")
                }
            NavigationView { ArtistsSearchView() }
                .tabItem {
                    Label("Artistas", systemImage: "music.mic")
                }
        }
    }
}

#Preview {
    RootView()
}
