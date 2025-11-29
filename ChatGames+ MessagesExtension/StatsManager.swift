//
//  StatsManager.swift
//  ChatGames+ MessagesExtension
//
//  Manages local statistics using UserDefaults
//

import Foundation

struct GameStats: Codable {
    var gamesPlayed: Int
    var gamesWon: Int
    var gamesLost: Int
    var gamesDrawn: Int
    
    init() {
        gamesPlayed = 0
        gamesWon = 0
        gamesLost = 0
        gamesDrawn = 0
    }
}

class StatsManager {
    static let shared = StatsManager()
    private let defaults = UserDefaults.standard
    private let statsKeyPrefix = "gameStats_"
    
    private init() {}
    
    /// Get stats for a specific game type
    func getStats(for gameType: String) -> GameStats {
        let key = statsKeyPrefix + gameType
        if let data = defaults.data(forKey: key),
           let stats = try? JSONDecoder().decode(GameStats.self, from: data) {
            return stats
        }
        return GameStats()
    }
    
    /// Save stats for a specific game type
    func saveStats(_ stats: GameStats, for gameType: String) {
        let key = statsKeyPrefix + gameType
        if let data = try? JSONEncoder().encode(stats) {
            defaults.set(data, forKey: key)
        }
    }
    
    /// Record a game result
    func recordGameResult(gameType: String, result: GameResult, playerNumber: Int) {
        var stats = getStats(for: gameType)
        stats.gamesPlayed += 1
        
        switch result {
        case .win(let winner):
            // Check if the current player won
            if let winner = winner, winner == playerNumber {
                stats.gamesWon += 1
            } else {
                stats.gamesLost += 1
            }
        case .draw:
            stats.gamesDrawn += 1
        case .loss:
            stats.gamesLost += 1
        }
        
        saveStats(stats, for: gameType)
    }
    
    /// Get all stats as a dictionary
    func getAllStats() -> [String: GameStats] {
        var allStats: [String: GameStats] = [:]
        let knownGameTypes = ["connect4"]
        
        for gameType in knownGameTypes {
            allStats[gameType] = getStats(for: gameType)
        }
        
        return allStats
    }
}

enum GameResult {
    case win(winner: Int?)
    case draw
    case loss
}

