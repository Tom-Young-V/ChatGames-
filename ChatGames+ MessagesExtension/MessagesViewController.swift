//
//  MessagesViewController.swift
//  ChatGames+ MessagesExtension
//
//  Created by Tom Young V on 11/28/25.
//

import UIKit
import Messages

class MessagesViewController: MSMessagesAppViewController {
    
    private var currentGame: (any Game)?
    private var currentViewController: UIViewController?
    private var localPlayerNumber: Int = 1
    private var currentSession: MSSession?
    private var hasSentMessage: Bool = false
    
    /// For development: allow playing both sides locally.
    private let debugPlayBothSides: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.subviews.forEach { $0.removeFromSuperview() }
    }
    
    // MARK: - Conversation Handling
    
    override func willBecomeActive(with conversation: MSConversation) {
        // Check if there's a selected message (game bubble was clicked)
        if conversation.selectedMessage != nil {
            hasSentMessage = false // Reset when opening a game
            if presentationStyle != .expanded {
                requestPresentationStyle(.expanded)
            }
        } else if hasSentMessage {
            // Don't auto-open if we've already sent a message
            return
        }
        presentViewController(for: conversation, with: presentationStyle)
    }
    
    override func didResignActive(with conversation: MSConversation) {
        // Clean up when extension becomes inactive
    }
   
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Decode game from message
        guard let url = message.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              let gameDataString = queryItems.first(where: { $0.name == "gameData" })?.value,
              let gameData = Data(base64Encoded: gameDataString) else {
            return
        }
        
        if let game = GameManager.shared.decodeGame(from: gameData) {
            // Record stats if game ended
            if let connect4Game = game as? Connect4Game {
                if connect4Game.gameState == .won {
                    if let winner = connect4Game.checkWin() {
                        let result = winner == localPlayerNumber ? GameResult.win(winner: winner) : GameResult.loss
                        StatsManager.shared.recordGameResult(gameType: "connect4", result: result, playerNumber: localPlayerNumber)
                    }
                } else if connect4Game.gameState == .draw {
                    StatsManager.shared.recordGameResult(gameType: "connect4", result: .draw, playerNumber: localPlayerNumber)
                }
            }
            
            currentGame = game
            currentSession = message.session ?? currentSession
            presentViewController(for: conversation, with: presentationStyle)
        }
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Message is being sent - close the interface
        hasSentMessage = true
        DispatchQueue.main.async { [weak self] in
            self?.requestPresentationStyle(.compact)
        }
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        // Message was cancelled
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Prepare for transition
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        if let conversation = activeConversation {
            if conversation.selectedMessage != nil && presentationStyle != .expanded {
                requestPresentationStyle(.expanded)
            } else {
                presentViewController(for: conversation, with: presentationStyle)
            }
        }
    }
    
    // MARK: - UI Presentation
    
    private func presentViewController(for conversation: MSConversation, with presentationStyle: MSMessagesAppPresentationStyle) {
        // Remove existing view controller
        if let existingVC = currentViewController {
            existingVC.willMove(toParent: nil)
            existingVC.view.removeFromSuperview()
            existingVC.removeFromParent()
        }
        
        // Check if there's a selected message (game bubble was clicked)
        if conversation.selectedMessage != nil {
            // Always show the game when a message is selected
            let gameVC = createGameViewController(for: conversation)
            addChild(gameVC)
            view.addSubview(gameVC.view)
            gameVC.view.frame = view.bounds
            gameVC.didMove(toParent: self)
            currentViewController = gameVC
            return
        }
        
        // Determine if we should show compact or expanded view
        guard presentationStyle == .expanded else {
            // In compact mode, show game selection
            let selectionVC = createGameSelectionViewController()
            addChild(selectionVC)
            view.addSubview(selectionVC.view)
            selectionVC.view.frame = view.bounds
            selectionVC.didMove(toParent: self)
            currentViewController = selectionVC
            return
        }
        
        // In expanded mode without selected message, show game selection
        let selectionVC = createGameSelectionViewController()
        addChild(selectionVC)
        view.addSubview(selectionVC.view)
        selectionVC.view.frame = view.bounds
        selectionVC.didMove(toParent: self)
        currentViewController = selectionVC
    }
    
    private func createGameSelectionViewController() -> UIViewController {
        let selectionVC = GameSelectionViewController()
        selectionVC.delegate = self
        return selectionVC
    }
    
    private func createGameViewController(for conversation: MSConversation) -> UIViewController {
        // Check for existing game in conversation
        var isNewGame = false
        if let selectedMessage = conversation.selectedMessage,
           let url = selectedMessage.url,
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems,
           let gameDataString = queryItems.first(where: { $0.name == "gameData" })?.value,
           let gameData = Data(base64Encoded: gameDataString),
           let game = GameManager.shared.decodeGame(from: gameData) {
            currentGame = game
            currentSession = selectedMessage.session ?? currentSession
            // Determine our player number
            if let connect4Game = game as? Connect4Game {
                if connect4Game.gameState == .waiting {
                    localPlayerNumber = 1
                } else {
                    localPlayerNumber = connect4Game.currentPlayer == 1 ? 2 : 1
                }
            }
        } else if currentGame == nil {
            return createGameSelectionViewController()
        }
        
        guard let game = currentGame as? Connect4Game else {
            let vc = UIViewController()
            vc.view.backgroundColor = .systemBackground
            return vc
        }
        
        // Determine if this is the local player's turn
        let isLocalPlayer: Bool
        if debugPlayBothSides {
            isLocalPlayer = (game.gameState == .inProgress || game.gameState == .waiting)
        } else {
            isLocalPlayer = (game.currentPlayer == localPlayerNumber || (game.gameState == .waiting && isNewGame)) &&
                            (game.gameState == .inProgress || game.gameState == .waiting)
        }
        
        let connect4VC = Connect4ViewController(
            game: game,
            isLocalPlayer: isLocalPlayer,
            localPlayerNumber: localPlayerNumber,
            debugPlayBothSides: debugPlayBothSides
        )
        connect4VC.delegate = self
        
        return connect4VC
    }
    
    // MARK: - Message Sending
    
    private func sendGameMessage(_ game: any Game, in conversation: MSConversation) {
        guard let gameData = GameManager.shared.encodeGame(game) else {
            return
        }
        
        if currentSession == nil {
            currentSession = MSSession()
        }
        guard let session = currentSession else { return }
        
        let base64String = gameData.base64EncodedString()
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "gameData", value: base64String)
        ]
        
        let layout = MSMessageTemplateLayout()
        layout.caption = "Connect 4 - Your turn!"
        if game.gameState == .won {
            layout.caption = "Connect 4 - Game Over!"
        } else if game.gameState == .draw {
            layout.caption = "Connect 4 - It's a draw!"
        }

        let message = MSMessage(session: session)
        message.url = components.url
        message.layout = layout
        message.summaryText = layout.caption
        
        conversation.insert(message) { [weak self] error in
            if let error = error {
                print("Error inserting message: \(error)")
            } else {
                guard let strongSelf = self else { return }
                // Mark as sent so we don’t auto‑reopen the game picker
                strongSelf.hasSentMessage = true
                // Collapse the UI and dismiss the extension so the regular keyboard is shown
                strongSelf.requestPresentationStyle(.compact)
                strongSelf.dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension MessagesViewController: Connect4ViewControllerDelegate {
    func didMakeMove(game: Connect4Game) {
        currentGame = game
        // Send the updated game state; sendGameMessage will handle collapsing/dismissing the UI.
        if let conversation = activeConversation {
            sendGameMessage(game, in: conversation)
        }
    }
}

extension MessagesViewController: GameSelectionViewControllerDelegate {
    func didSelectGame(_ gameType: String) {
        guard let conversation = activeConversation else { return }
        
        // Only support Connect 4 for now
        if gameType == "connect4" {
            if var newGame = GameManager.shared.createGame(type: gameType) as? Connect4Game {
                newGame.currentPlayer = 2 // Other player goes first
                newGame.gameState = .inProgress
                currentGame = newGame
                localPlayerNumber = 1
                
                // Start a fresh session for a new game
                currentSession = MSSession()
                
                // Send the game immediately - the completion handler will close the interface
                sendGameMessage(newGame, in: conversation)
            }
        } else {
            // Placeholder for other games
            let alert = UIAlertController(title: "Coming Soon", message: "\(gameType.capitalized) will be available soon!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}
