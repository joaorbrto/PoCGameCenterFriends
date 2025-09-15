//
//  PKCE.swift
//  PoCSGameCenter
//
//  Created by Joao Roberto Fernandes Magalhaes on 10/09/25.
//

import Foundation
import CryptoKit

struct PKCE {
    let verifier: String
    let challenge: String

    init() {
        self.verifier = Self.randomURLSafeString(length: 64)
        self.challenge = Self.sha256Base64URLEncoded(verifier)
    }

    private static func randomURLSafeString(length: Int) -> String {
        let chars = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return String((0..<length).compactMap { _ in chars.randomElement() })
    }

    private static func sha256Base64URLEncoded(_ input: String) -> String {
        let data = Data(input.utf8)
        let hashed = SHA256.hash(data: data)
        return Data(hashed).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    func weeklyPlaysCount() async throws -> Int {
        try await SpotifyPlaysService.shared.weeklyPlaysCount()
    }
}
