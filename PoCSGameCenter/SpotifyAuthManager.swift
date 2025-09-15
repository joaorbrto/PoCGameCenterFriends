//
//  SpotifyAuthManager.swift
//  PoCSGameCenter
//
//  Created by Joao Roberto Fernandes Magalhaes on 10/09/25.
//

//
//  SpotifyAuthManager.swift
//  PoCSGameCenter
//

import Foundation
import AuthenticationServices
import SwiftUI

/// Troca o code por tokens **no device** (PKCE) — sem backend.
final class SpotifyAuthManager: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var displayName: String?
    private var session: ASWebAuthenticationSession?
    private var pkce: PKCE?

    // Ajuste estes valores:
    private let spotifyClientId = "7d66b47018304877afa13d489aa53977"
    private let redirectURI = "pocsgamecenter://auth/spotify/callback"
    private let scopes = "user-read-recently-played%20user-read-email"

    func connect(appUserId: String) {
        // 1) Gera PKCE
        let pkce = PKCE()
        self.pkce = pkce
        let state = UUID().uuidString

        // 2) Monta URL de autorização
        var comps = URLComponents(string: "https://accounts.spotify.com/authorize")!
        comps.queryItems = [
            .init(name: "response_type", value: "code"),
            .init(name: "client_id", value: spotifyClientId),
            .init(name: "redirect_uri", value: redirectURI),
            .init(name: "scope", value: scopes),
            .init(name: "state", value: state),
            .init(name: "code_challenge_method", value: "S256"),
            .init(name: "code_challenge", value: pkce.challenge)
        ]
        guard let url = comps.url else { return }

        // 3) Abre ASWebAuthenticationSession
        session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "pocsgamecenter"   // tem que bater com seu URL Scheme no Xcode
        ) { [weak self] callbackURL, error in
            guard let self else { return }
            if let error { print("Spotify auth cancel/err:", error.localizedDescription); return }
            guard let callbackURL else { return }

            // 4) Extrai o "code" do callback
            let qi = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
            guard let code = qi.first(where: { $0.name == "code" })?.value,
                  let verifier = self.pkce?.verifier else {
                return
            }

            // 5) **AQUI é o “3)”**: troca do code por tokens **no device** (PKCE),
            //    em vez de chamar exchangeCodeAtBackend(...)
            Task {
                do {
                    _ = try await SpotifyTokenService.shared.exchangeCodePKCE(
                        code: code,
                        codeVerifier: verifier
                    )
                    // (Opcional) buscar o /me para exibir nome de perfil
                    await MainActor.run {
                        self.isConnected = true
                        self.displayName = "Conectado ao Spotify"
                    }
                } catch {
                    print("token exchange err:", error)
                }
            }
        }
        session?.prefersEphemeralWebBrowserSession = true
        session?.presentationContextProvider = self
        _ = session?.start()
    }

    func disconnect(appUserId: String) {
        // Sem backend: apenas “limpe” estado local se desejar (tokens no Keychain, etc.)
        // Ex.: criar um método SpotifyTokenService.shared.clear() se quiser invalidar.
        DispatchQueue.main.async {
            self.isConnected = false
            self.displayName = nil
        }
    }
}

extension SpotifyAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first ?? UIWindow()
    }
}

private extension UIWindowScene { var keyWindow: UIWindow? { windows.first { $0.isKeyWindow } } }
