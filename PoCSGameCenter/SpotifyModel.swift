//
//  SpotifyModel.swift
//  PoCSGameCenter
//
//  Created by Joao Roberto Fernandes Magalhaes on 10/09/25.
//

import Foundation

public struct SPImage: Decodable, Hashable {
    public let url: String
    public let height: Int?
    public let width: Int?
}

public struct SPArtist: Decodable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let images: [SPImage]
}

public struct SPArtistLite: Decodable, Hashable {
    public let id: String
    public let name: String
}

public struct SPAlbum: Decodable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let release_date: String?
    public let album_group: String?
    public let images: [SPImage]
    public let artists: [SPArtistLite]?
}

struct SPSearchArtistsResponse: Decodable {
    let artists: Container
    struct Container: Decodable { let items: [SPArtist] }
}

struct SPArtistAlbumsResponse: Decodable {
    let items: [SPAlbum]
    let next: String?
}

public enum SPAPIError: Error { case unauthorized, badResponse }
