//
//  Connect4BoardView.swift
//  ChatGames+ MessagesExtension
//
//  Connect 4 board UI with tap-to-drop interaction
//

import UIKit

protocol Connect4BoardViewDelegate: AnyObject {
    func didSelectColumn(_ column: Int)
}

class Connect4BoardView: UIView {
    weak var delegate: Connect4BoardViewDelegate?
    
    private var board: [[Int]] = []
    private var previousBoard: [[Int]] = []
    private var rows: Int = 6
    private var columns: Int = 7
    private var cellSize: CGFloat = 0
    private var spacing: CGFloat = 4
    private var isInteractive: Bool = true
    
    private var boardContainer: UIView!
    private var cellViews: [[UIView?]] = []
    private var tapAreas: [UIView] = []
    
    // Constants for tagging views
    private let pieceTag = 999
    private let tapAreaBaseTag = 1000
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .systemBlue
        layer.cornerRadius = 12
        clipsToBounds = true
        
        boardContainer = UIView()
        boardContainer.backgroundColor = .clear
        addSubview(boardContainer)
        
        boardContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            boardContainer.topAnchor.constraint(equalTo: topAnchor, constant: spacing),
            boardContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: spacing),
            boardContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -spacing),
            boardContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -spacing)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Only update cell frames, don't recreate or modify board state
        layoutCellsIfNeeded()
    }
    
    func updateBoard(_ game: Connect4Game, isInteractive: Bool = true) {
        let newBoard = game.getBoard()
        let newRows = game.getRows()
        let newColumns = game.getColumns()
        
        // Force layout if needed to get proper cellSize
        if boardContainer.bounds.width == 0 || boardContainer.bounds.height == 0 {
            setNeedsLayout()
            layoutIfNeeded()
        }
        
        // Find which piece was just added by comparing with previous board
        // Do this BEFORE updating previousBoard
        var newPieceRow: Int? = nil
        var newPieceCol: Int? = nil
        
        // Initialize previousBoard if empty or size changed
        if previousBoard.isEmpty || previousBoard.count != newRows || (previousBoard.count > 0 && previousBoard[0].count != newColumns) {
            previousBoard = Array(repeating: Array(repeating: 0, count: newColumns), count: newRows)
        }
        
        // Detect new piece by comparing boards
        if previousBoard.count == newBoard.count && previousBoard.count > 0 && 
           previousBoard[0].count == newBoard[0].count {
            for row in 0..<newRows {
                for col in 0..<newColumns {
                    if previousBoard[row][col] == 0 && newBoard[row][col] != 0 {
                        newPieceRow = row
                        newPieceCol = col
                        break
                    }
                }
                if newPieceRow != nil { break }
            }
        }
        
        // Update state
        self.rows = newRows
        self.columns = newColumns
        self.isInteractive = isInteractive
        self.board = newBoard
        
        // Update board UI
        updateBoardState(animateNewPiece: newPieceRow != nil ? (row: newPieceRow!, col: newPieceCol!) : nil)
        
        // Only update previousBoard AFTER we've scheduled animations
        // This ensures animations can still see the old state
        DispatchQueue.main.async { [weak self] in
            self?.previousBoard = newBoard
        }
    }
    
    private func layoutCellsIfNeeded() {
        // Only update frames, don't modify board state
        guard cellSize > 0, rows > 0, columns > 0 else { return }
        
        for row in 0..<rows {
            guard row < cellViews.count else { continue }
            for col in 0..<columns {
                guard col < cellViews[row].count, let cell = cellViews[row][col] else { continue }
                let x = CGFloat(col) * (cellSize + spacing)
                let y = CGFloat(row) * (cellSize + spacing)
                cell.frame = CGRect(x: x, y: y, width: cellSize, height: cellSize)
            }
        }
        
        // Update tap area frames
        updateTapAreaFrames()
    }
    
    private func updateBoardState(animateNewPiece: (row: Int, col: Int)? = nil) {
        // Initialize cell views array if needed
        if cellViews.count != rows {
            cellViews = Array(repeating: Array(repeating: nil as UIView?, count: columns), count: rows)
        }
        
        guard rows > 0 && columns > 0 else { return }
        
        // Ensure board array is properly sized
        guard board.count == rows, board.allSatisfy({ $0.count == columns }) else {
            return
        }
        
        let containerWidth = boardContainer.bounds.width
        let containerHeight = boardContainer.bounds.height
        
        guard containerWidth > 0 && containerHeight > 0 else { return }
        
        // Calculate cell size - must be finalized before creating cells
        let availableWidth = containerWidth - (CGFloat(columns - 1) * spacing)
        let availableHeight = containerHeight - (CGFloat(rows - 1) * spacing)
        cellSize = min(availableWidth / CGFloat(columns), availableHeight / CGFloat(rows))
        
        guard cellSize > 0 else { return }
        
        // Update or create cells
        for row in 0..<rows {
            for col in 0..<columns {
                let x = CGFloat(col) * (cellSize + spacing)
                let y = CGFloat(row) * (cellSize + spacing)
                
                if let existingCell = cellViews[row][col] {
                    // Update existing cell
                    existingCell.frame = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                    // Just update the visual state; handle animation separately to avoid double‑animating
                    updateCell(existingCell, row: row, column: col, animate: false)
                    
                    // Animate drop if this is the newly added piece
                    if let animate = animateNewPiece, animate.row == row && animate.col == col {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            self.animatePieceDrop(in: existingCell, row: row)
                        }
                    }
                } else {
                    // Create new cell
                    let cell = createCell(row: row, column: col)
                    boardContainer.addSubview(cell)
                    cell.frame = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                    cellViews[row][col] = cell
                    
                    // Animate drop if this is the new piece
                    if let animate = animateNewPiece, animate.row == row && animate.col == col {
                        // Delay slightly to ensure cell is fully laid out
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            self.animatePieceDrop(in: cell, row: row)
                        }
                    }
                }
            }
        }
        
        // Setup tap areas once if needed
        if isInteractive {
            setupTapAreasIfNeeded()
        }
    }
    
    private func animatePieceDrop(in cell: UIView, row: Int) {
        // Find the piece view using tag instead of color
        DispatchQueue.main.async { [weak self, weak cell] in
            guard let cell = cell, let self = self else { return }
            guard let piece = cell.viewWithTag(self.pieceTag) else {
                return
            }
            
            // Start the piece just above the top of the board, regardless of destination row,
            // so it always appears to fall in from the top.
            let startY = -self.boardContainer.bounds.height
            
            // Set initial position above the board
            piece.transform = CGAffineTransform(translationX: 0, y: startY)
            piece.alpha = 0.8
            
            // Animate to final position with a nice drop effect
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.0, options: .curveEaseOut, animations: {
                piece.transform = .identity
                piece.alpha = 1.0
            }, completion: nil)
        }
    }
    
    private func updateCell(_ cell: UIView, row: Int, column: Int, animate: Bool) {
        // Bounds check
        guard row >= 0 && row < rows && column >= 0 && column < columns,
              row < board.count && column < board[row].count else {
            return
        }
        
        let player = board[row][column]
        
        // Check if there's already a piece using tag
        let existingPiece = cell.viewWithTag(pieceTag)
        
        // Only update if needed
        if existingPiece == nil && player != 0 {
            // Remove any existing subviews first
            cell.subviews.forEach { $0.removeFromSuperview() }
            
            switch player {
            case 1:
                addPiece(to: cell, color: .systemRed, animate: false)
            case 2:
                addPiece(to: cell, color: .systemYellow, animate: false)
            default:
                break
            }
        } else if existingPiece != nil && player == 0 {
            // Remove piece if cell is now empty
            existingPiece?.removeFromSuperview()
        }
    }
    
    private func createCell(row: Int, column: Int) -> UIView {
        // Ensure cellSize is finalized before creating cell
        guard cellSize > 0 else {
            return UIView()
        }
        
        let cell = UIView()
        cell.backgroundColor = .white
        cell.layer.cornerRadius = cellSize / 2
        cell.clipsToBounds = true
        
        // Bounds check
        guard row >= 0 && row < rows && column >= 0 && column < columns,
              row < board.count && column < board[row].count else {
            return cell
        }
        
        let player = board[row][column]
        switch player {
        case 1:
            addPiece(to: cell, color: .systemRed, animate: false)
        case 2:
            addPiece(to: cell, color: .systemYellow, animate: false)
        default:
            break
        }
        
        return cell
    }
    
    private func addPiece(to cell: UIView, color: UIColor, animate: Bool) {
        guard cellSize > 0 else { return }
        
        let piece = UIView()
        piece.tag = pieceTag // Tag for reliable detection
        piece.backgroundColor = color
        piece.layer.cornerRadius = cellSize / 2
        piece.clipsToBounds = true
        piece.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(piece)
        
        NSLayoutConstraint.activate([
            piece.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
            piece.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            piece.widthAnchor.constraint(equalTo: cell.widthAnchor),
            piece.heightAnchor.constraint(equalTo: cell.heightAnchor)
        ])
        
        if !animate {
            piece.alpha = 1
        }
    }
    
    private func setupTapAreasIfNeeded() {
        // Only create tap areas if they don't exist or count changed
        if tapAreas.count != columns {
            // Remove old tap areas
            tapAreas.forEach { $0.removeFromSuperview() }
            tapAreas.removeAll()
            
            // Create new tap areas
            for col in 0..<columns {
                let tapArea = UIView()
                tapArea.tag = tapAreaBaseTag + col
                tapArea.backgroundColor = .clear
                tapArea.isUserInteractionEnabled = true
                
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(columnTapped(_:)))
                tapArea.addGestureRecognizer(tapGesture)
                
                boardContainer.addSubview(tapArea)
                tapAreas.append(tapArea)
            }
        }
        
        // Update frames
        updateTapAreaFrames()
    }
    
    private func updateTapAreaFrames() {
        guard cellSize > 0, columns > 0 else { return }
        
        for (index, tapArea) in tapAreas.enumerated() {
            guard index < columns else { break }
            let x = CGFloat(index) * (cellSize + spacing)
            tapArea.frame = CGRect(x: x, y: 0, width: cellSize, height: boardContainer.bounds.height)
        }
    }
    
    @objc private func columnTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }
        let column = view.tag - tapAreaBaseTag
        delegate?.didSelectColumn(column)
    }
}

// Helper extension for safe array access
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


