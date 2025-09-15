//
//  SpotifyTokenService.swift
//  PoCSGameCenter
//
//  Created by Joao Roberto Fernandes Magalhaes on 10/09/25.
//

import Foundation
import Security

struct SpotifyTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
}

final class SpotifyTokenService {
    static let shared = SpotifyTokenService()
    private init() {}

    private let tokenURL = URL(string: "https://accounts.spotify.com/api/token")!
    private let clientId = "7d66b47018304877afa13d489aa53977"
    private let redirectURI = "pocsgamecenter://auth/spotify/callback"

    func exchangeCodePKCE(code: String, codeVerifier: String) async throws -> SpotifyTokens {
        var req = URLRequest(url: tokenURL)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = [
            "grant_type":"authorization_code",
            "code":code,
            "redirect_uri":redirectURI,
            "client_id":clientId,
            "code_verifier":codeVerifier
        ].map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        req.httpBody = body.data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: req)
        struct R: Decodable { let access_token:String; let refresh_token:String; let expires_in:Int }
        let r = try JSONDecoder().decode(R.self, from: data)
        let t = SpotifyTokens(
            accessToken: r.access_token,
            refreshToken: r.refresh_token,
            expiresAt: Date().addingTimeInterval(TimeInterval(r.expires_in))
        )
        try save(t); return t
    }

    func refreshIfNeeded() async throws -> String {
        guard var t = try? load() else { throw NSError(domain:"no-token", code:0) }
        if t.expiresAt > Date().addingTimeInterval(60) { return t.accessToken }

        var req = URLRequest(url: tokenURL)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = [
            "grant_type":"refresh_token",
            "refresh_token":t.refreshToken,
            "client_id":clientId
        ].map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        req.httpBody = body.data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: req)
        struct R: Decodable { let access_token:String; let expires_in:Int }
        let r = try JSONDecoder().decode(R.self, from: data)
        t = SpotifyTokens(accessToken: r.access_token,
                          refreshToken: t.refreshToken,
                          expiresAt: Date().addingTimeInterval(TimeInterval(r.expires_in)))
        try save(t); return t.accessToken
    }

    // Keychain simplificado p/ POC
    private let kcKey = "spotify_tokens"
    private func save(_ t: SpotifyTokens) throws {
        let d = try JSONEncoder().encode(t)
        let q: [String:Any] = [kSecClass as String:kSecClassGenericPassword,
                               kSecAttrAccount as String: kcKey]
        SecItemDelete(q as CFDictionary)
        var attrs = q; attrs[kSecValueData as String] = d
        let st = SecItemAdd(attrs as CFDictionary, nil)
        guard st == errSecSuccess else { throw NSError(domain:"kc", code:Int(st)) }
    }
    private func load() throws -> SpotifyTokens {
        let q: [String:Any] = [kSecClass as String:kSecClassGenericPassword,
                               kSecAttrAccount as String: kcKey,
                               kSecReturnData as String:true]
        var out: CFTypeRef?
        let st = SecItemCopyMatching(q as CFDictionary, &out)
        guard st == errSecSuccess, let d = out as? Data else { throw NSError(domain:"kc", code:Int(st)) }
        return try JSONDecoder().decode(SpotifyTokens.self, from: d)
    }
}
