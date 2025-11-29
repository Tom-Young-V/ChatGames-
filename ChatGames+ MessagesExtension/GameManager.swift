//
//  GameManager.swift
//  ChatGames+ MessagesExtension
//
//  Manages game encoding/decoding and factory
//

import Foundation

class GameManager {
    static let shared = GameManager()
    
    private init() {}
    
    /// Decode game from JSON data
    func decodeGame(from data: Data) -> (any Game)? {
        do {
            let message = try JSONDecoder().decode(GameMessage.self, from: data)
            
            switch message.gameType {
            case "connect4":
                return try JSONDecoder().decode(Connect4Game.self, from: message.gameData)
            default:
                return nil
            }
        } catch {
            print("Error decoding game: \(error)")
            return nil
        }
    }
    
    /// Encode game to JSON data
    func encodeGame(_ game: any Game) -> Data? {
        do {
            let gameData = try JSONEncoder().encode(game)
            let message = GameMessage(gameType: game.gameType, gameData: gameData)
            return try JSONEncoder().encode(message)
        } catch {
            print("Error encoding game: \(error)")
            return nil
        }
    }
    
    /// Create a new game of the specified type
    func createGame(type: String) -> (any Game)? {
        switch type {
        case "connect4":
            var game = Connect4Game()
            game.gameState = .inProgress
            return game
        default:
            return nil
        }
    }
}

