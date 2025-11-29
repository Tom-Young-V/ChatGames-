//
//  Connect4ViewController.swift
//  ChatGames+ MessagesExtension
//
//  View controller for Connect 4 game
//

import UIKit
import Messages

class Connect4ViewController: UIViewController {
    private var game: Connect4Game
    private var boardView: Connect4BoardView!
    private var statusLabel: UILabel!
    private var sendButton: UIButton!
    private var isLocalPlayer: Bool
    private var localPlayerNumber: Int
    private var pendingGame: Connect4Game? // Game state with pending move
    private var debugPlayBothSides: Bool
    
    weak var delegate: Connect4ViewControllerDelegate?
    
    init(game: Connect4Game, isLocalPlayer: Bool, localPlayerNumber: Int, debugPlayBothSides: Bool = false) {
        self.game = game
        self.isLocalPlayer = isLocalPlayer
        self.localPlayerNumber = localPlayerNumber
        self.debugPlayBothSides = debugPlayBothSides
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Status label
        statusLabel = UILabel()
        statusLabel.text = ""
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        statusLabel.numberOfLines = 0
        view.addSubview(statusLabel)
        
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        // Board view
        boardView = Connect4BoardView()
        boardView.delegate = self
        view.addSubview(boardView)
        
        boardView.translatesAutoresizingMaskIntoConstraints = false
        let top = boardView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20)
        let centerX = boardView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        let width = boardView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9)
        let height = boardView.heightAnchor.constraint(equalTo: boardView.widthAnchor, multiplier: 6.0/7.0)
        // Lower the priority a bit so Auto Layout can break this first if needed
        height.priority = .defaultHigh
        // Don't constrain bottom to safe area - let send button handle that
        let bottom = boardView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -70)
        
        NSLayoutConstraint.activate([top, centerX, width, height, bottom])
        
        // Send button (initially hidden)
        sendButton = UIButton(type: .system)
        sendButton.setTitle("Send Move", for: .normal)
        sendButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        sendButton.backgroundColor = .systemBlue
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.layer.cornerRadius = 8
        sendButton.isHidden = true
        sendButton.addTarget(self, action: #selector(sendMove), for: .touchUpInside)
        view.addSubview(sendButton)
        
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sendButton.topAnchor.constraint(equalTo: boardView.bottomAnchor, constant: 16),
            sendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 200),
            sendButton.heightAnchor.constraint(equalToConstant: 44),
            sendButton.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    private func updateUI() {
        // Base (committed) game state used for evaluating turn ownership
        let baseGame = game
        let displayGame = pendingGame ?? baseGame
        let hasPendingMove = pendingGame != nil
        
        // Determine if player can make (or edit) a move based on base game
        let canStartMove: Bool
        if debugPlayBothSides {
            canStartMove = (baseGame.gameState == .inProgress || baseGame.gameState == .waiting)
        } else {
            canStartMove = isLocalPlayer &&
                           baseGame.currentPlayer == localPlayerNumber &&
                           (baseGame.gameState == .inProgress || baseGame.gameState == .waiting)
        }
        
        // Show/hide send button based on whether there's a pending move
        sendButton.isHidden = !hasPendingMove
        
        // Allow board interaction if we can start a move OR we're adjusting an existing pending move
        let shouldAllowInteraction = canStartMove || hasPendingMove
        boardView.updateBoard(displayGame, isInteractive: shouldAllowInteraction)
        
        // Update status label
        switch displayGame.gameState {
        case .waiting:
            statusLabel.text = "Waiting to start..."
        case .inProgress:
            if hasPendingMove {
                statusLabel.text = "Move ready! Tap 'Send Move' to send."
            } else if canStartMove {
                statusLabel.text = "Your turn! Tap a column to drop your piece."
            } else {
                statusLabel.text = "Waiting for opponent..."
            }
        case .won:
            if let winner = displayGame.checkWin() {
                if winner == localPlayerNumber {
                    statusLabel.text = "🎉 You won!"
                    statusLabel.textColor = .systemGreen
                } else {
                    statusLabel.text = "You lost 😢"
                    statusLabel.textColor = .systemRed
                }
            } else {
                statusLabel.text = "Game over"
            }
        case .draw:
            statusLabel.text = "It's a draw!"
            statusLabel.textColor = .systemOrange
        case .ended:
            statusLabel.text = "Game ended"
        }
        
        if displayGame.gameState == .inProgress || displayGame.gameState == .waiting {
            statusLabel.textColor = .label
        }
    }
    
    func updateGame(_ newGame: Connect4Game) {
        self.game = newGame
        self.pendingGame = nil // Clear any pending moves when receiving a new game
        updateUI()
    }
}

extension Connect4ViewController: Connect4BoardViewDelegate {
    func didSelectColumn(_ column: Int) {
        // Check if move is allowed (based on committed game state)
        let baseGame = game
        let canMove: Bool
        if debugPlayBothSides {
            canMove = (baseGame.gameState == .inProgress || baseGame.gameState == .waiting)
        } else {
            canMove = isLocalPlayer &&
                     baseGame.currentPlayer == localPlayerNumber &&
                     (baseGame.gameState == .inProgress || baseGame.gameState == .waiting)
        }
        
        guard canMove else { return }
        
        // Build pending move off of the committed game state so tapping a new column replaces the pending move
        var updatedGame = baseGame
        if updatedGame.makeMove(GameMove(column: column)) {
            // Store as pending move (don't send yet)
            pendingGame = updatedGame
            updateUI()
        }
    }
    
    @objc private func sendMove() {
        guard let pending = pendingGame else { return }
        
        // Update stats if game ended
        if pending.gameState == .won {
            if let winner = pending.checkWin() {
                let result = winner == localPlayerNumber ? GameResult.win(winner: winner) : GameResult.loss
                StatsManager.shared.recordGameResult(gameType: "connect4", result: result, playerNumber: localPlayerNumber)
            }
        } else if pending.gameState == .draw {
            StatsManager.shared.recordGameResult(gameType: "connect4", result: .draw, playerNumber: localPlayerNumber)
        }
        
        // Commit the move and send
        game = pending
        pendingGame = nil
        delegate?.didMakeMove(game: pending)
        updateUI()
    }
}

protocol Connect4ViewControllerDelegate: AnyObject {
    func didMakeMove(game: Connect4Game)
}

