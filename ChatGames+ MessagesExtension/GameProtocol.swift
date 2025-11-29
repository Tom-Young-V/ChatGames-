//
//  GameProtocol.swift
//  ChatGames+ MessagesExtension
//
//  Created for extensible game system
//

import Foundation

/// Protocol for all games in the system
protocol Game: Codable {
    var gameType: String { get }
    var currentPlayer: Int { get set }
    var gameState: GameState { get set }
    
    mutating func makeMove(_ move: GameMove) -> Bool
    func checkWin() -> Int? // Returns player number if won, nil otherwise
    func checkDraw() -> Bool
    func isValidMove(_ move: GameMove) -> Bool
}

/// Game state enumeration
enum GameState: String, Codable {
    case waiting
    case inProgress
    case won
    case draw
    case ended
}

/// Base structure for game moves
struct GameMove: Codable {
    let column: Int
    let row: Int?
    
    init(column: Int, row: Int? = nil) {
        self.column = column
        self.row = row
    }
}

/// Game message wrapper for JSON encoding
struct GameMessage: Codable {
    let gameType: String
    let gameData: Data
    let version: Int
    
    enum CodingKeys: String, CodingKey {
        case gameType
        case gameData
        case version
    }
    
    init(gameType: String, gameData: Data, version: Int = 1) {
        self.gameType = gameType
        self.gameData = gameData
        self.version = 1
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gameType = try container.decode(String.self, forKey: .gameType)
        gameData = try container.decode(Data.self, forKey: .gameData)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(gameType, forKey: .gameType)
        try container.encode(gameData, forKey: .gameData)
        try container.encode(version, forKey: .version)
    }
}

