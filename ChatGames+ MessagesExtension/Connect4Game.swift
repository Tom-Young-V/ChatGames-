//
//  Connect4Game.swift
//  ChatGames+ MessagesExtension
//
//  Connect 4 game implementation
//

import Foundation

struct Connect4Game: Game {
    var gameType: String { "connect4" }
    var currentPlayer: Int
    var gameState: GameState
    
    private var board: [[Int]] // 0 = empty, 1 = player 1, 2 = player 2
    private let rows: Int = 6
    private let columns: Int = 7
    
    init() {
        self.currentPlayer = 1
        self.gameState = .waiting
        self.board = Array(repeating: Array(repeating: 0, count: columns), count: rows)
    }
    
    init(currentPlayer: Int, gameState: GameState, board: [[Int]]) {
        self.currentPlayer = currentPlayer
        self.gameState = gameState
        self.board = board
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case currentPlayer
        case gameState
        case board
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentPlayer = try container.decode(Int.self, forKey: .currentPlayer)
        gameState = try container.decode(GameState.self, forKey: .gameState)
        board = try container.decode([[Int]].self, forKey: .board)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(currentPlayer, forKey: .currentPlayer)
        try container.encode(gameState, forKey: .gameState)
        try container.encode(board, forKey: .board)
    }
    
    // MARK: - Game Logic
    
    func isValidMove(_ move: GameMove) -> Bool {
        guard move.column >= 0 && move.column < columns else { return false }
        guard gameState == .inProgress || gameState == .waiting else { return false }
        return board[0][move.column] == 0 // Column has space at top
    }
    
    mutating func makeMove(_ move: GameMove) -> Bool {
        guard isValidMove(move) else { return false }
        
        // Find the lowest empty row in the column
        for row in stride(from: rows - 1, through: 0, by: -1) {
            if board[row][move.column] == 0 {
                board[row][move.column] = currentPlayer
                gameState = .inProgress
                
                // Check for win or draw
                if let winner = checkWin() {
                    gameState = .won
                    return true
                } else if checkDraw() {
                    gameState = .draw
                    return true
                }
                
                // Switch player
                currentPlayer = currentPlayer == 1 ? 2 : 1
                return true
            }
        }
        
        return false
    }
    
    func checkWin() -> Int? {
        // Check horizontal
        for row in 0..<rows {
            for col in 0..<(columns - 3) {
                let player = board[row][col]
                if player != 0 &&
                   board[row][col + 1] == player &&
                   board[row][col + 2] == player &&
                   board[row][col + 3] == player {
                    return player
                }
            }
        }
        
        // Check vertical
        for row in 0..<(rows - 3) {
            for col in 0..<columns {
                let player = board[row][col]
                if player != 0 &&
                   board[row + 1][col] == player &&
                   board[row + 2][col] == player &&
                   board[row + 3][col] == player {
                    return player
                }
            }
        }
        
        // Check diagonal (top-left to bottom-right)
        for row in 0..<(rows - 3) {
            for col in 0..<(columns - 3) {
                let player = board[row][col]
                if player != 0 &&
                   board[row + 1][col + 1] == player &&
                   board[row + 2][col + 2] == player &&
                   board[row + 3][col + 3] == player {
                    return player
                }
            }
        }
        
        // Check diagonal (top-right to bottom-left)
        for row in 0..<(rows - 3) {
            for col in 3..<columns {
                let player = board[row][col]
                if player != 0 &&
                   board[row + 1][col - 1] == player &&
                   board[row + 2][col - 2] == player &&
                   board[row + 3][col - 3] == player {
                    return player
                }
            }
        }
        
        return nil
    }
    
    func checkDraw() -> Bool {
        // Check if board is full
        for col in 0..<columns {
            if board[0][col] == 0 {
                return false
            }
        }
        return true
    }
    
    // MARK: - Helper Methods
    
    func getBoard() -> [[Int]] {
        return board
    }
    
    func getCell(row: Int, column: Int) -> Int {
        guard row >= 0 && row < rows && column >= 0 && column < columns else {
            return 0
        }
        return board[row][column]
    }
    
    func getRows() -> Int {
        return rows
    }
    
    func getColumns() -> Int {
        return columns
    }
}

