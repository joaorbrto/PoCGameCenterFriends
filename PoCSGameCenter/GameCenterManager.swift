//
//  GameCenterManager.swift
//  PoCSGameCenter
//
//  Created by Joao Roberto Fernandes Magalhaes on 04/09/25.
//

import Foundation
import GameKit

final class GameCenterManager: NSObject, ObservableObject, GKGameCenterControllerDelegate {
    @Published var isAuthenticated = false
    @Published var friends: [GKPlayer] = []
    @Published var errorMessage: String?
    
    override init() {
        super.init()
        authenticate()
        // Ativa o Access Point (opcional)
        GKAccessPoint.shared.location = .topLeading
        GKAccessPoint.shared.isActive = true
    }
    
    private func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] vc, error in
            if let vc, let root = Self.topViewController() {
                root.present(vc, animated: true)
                return
            }
            if GKLocalPlayer.local.isAuthenticated {
                DispatchQueue.main.async { self?.isAuthenticated = true }
            } else if let error {
                DispatchQueue.main.async { self?.errorMessage = error.localizedDescription }
            } else {
                DispatchQueue.main.async { self?.errorMessage = "Jogador não autenticado no Game Center." }
            }
        }
    }
    
    func presentFriendsList() {
        guard let root = Self.topViewController() else { return }
        let gcVC = GKGameCenterViewController(state: .leaderboards)
        gcVC.gameCenterDelegate = self
        root.present(gcVC, animated: true)
    }
    
    func signIn() {
        authenticate()
    }
    
    @available(iOS 14.0, *)
    func presentLeaderboard(id: String,
                            playerScope: GKLeaderboard.PlayerScope = .global,
                            timeScope: GKLeaderboard.TimeScope = .allTime) {
        guard let root = Self.topViewController() else { return }
        let gcVC = GKGameCenterViewController(leaderboardID: id,
                                              playerScope: playerScope,
                                              timeScope: timeScope)
        gcVC.gameCenterDelegate = self
        root.present(gcVC, animated: true)
    }
    
    func loadFriends() {
        guard GKLocalPlayer.local.isAuthenticated else {
            self.errorMessage = "Autentique-se no Game Center primeiro."
            return
        }
        GKLocalPlayer.local.loadFriends { [weak self] players, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.friends = []
                } else {
                    self?.errorMessage = nil
                    self?.friends = players ?? []
                }
            }
        }
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
    
    private static func topViewController(base: UIViewController? = {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
    }()) -> UIViewController? {
        if let nav = base as? UINavigationController { return topViewController(base: nav.visibleViewController) }
        if let tab = base as? UITabBarController { return topViewController(base: tab.selectedViewController) }
        if let presented = base?.presentedViewController { return topViewController(base: presented) }
        return base
    }
}

extension GameCenterManager {
    enum FriendsAccess {
        case authorized, notDetermined, deniedOrRestricted
    }

    func checkFriendsAccess(completion: @escaping (FriendsAccess) -> Void) {
        GKLocalPlayer.local.loadFriendsAuthorizationStatus { status, _ in
            switch status {
            case .authorized:
                completion(.authorized)
            case .notDetermined:
                completion(.notDetermined)
            case .denied, .restricted:
                completion(.deniedOrRestricted)
            @unknown default:
                completion(.deniedOrRestricted)
            }
        }
    }

    /// Fluxo recomendado: checa status e então carrega
    func ensureAndLoadFriends() {
        guard GKLocalPlayer.local.isAuthenticated else {
            self.errorMessage = "Autentique-se no Game Center primeiro."
            return
        }
        checkFriendsAccess { [weak self] access in
            DispatchQueue.main.async {
                switch access {
                case .authorized:
                    self?.loadFriends() // já existe no seu manager
                case .notDetermined:
                    // Opcional: mostrar um aviso amigável na UI
                    self?.errorMessage = "Vamos pedir acesso à sua lista de amigos…"
                    // Chamar loadFriends dispara o prompt do sistema quando status é notDetermined
                    self?.loadFriends()
                case .deniedOrRestricted:
                    self?.friends = []
                    self?.errorMessage =
                    "Sem acesso à lista de amigos. Ative nas Ajustes > Game Center > Amigos/Privacidade."
                }
            }
        }
    }
}
