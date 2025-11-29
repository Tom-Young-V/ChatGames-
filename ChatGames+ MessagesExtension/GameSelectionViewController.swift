//
//  GameSelectionViewController.swift
//  ChatGames+ MessagesExtension
//
//  Game selection interface
//

import UIKit

protocol GameSelectionViewControllerDelegate: AnyObject {
    func didSelectGame(_ gameType: String)
}

struct GameItem {
    let title: String
    let type: String
    let imageName: String
}

class GameSelectionViewController: UIViewController {
    weak var delegate: GameSelectionViewControllerDelegate?
    
    // 5x5 grid (25 items) – only "connect4" is implemented, others are placeholders
    private let games: [GameItem] = [
        GameItem(title: "Connect 4", type: "connect4", imageName: "game_connect4"),
        GameItem(title: "Pool", type: "pool", imageName: "game_pool"),
        GameItem(title: "Mini Golf", type: "minigolf", imageName: "game_minigolf"),
        GameItem(title: "Checkers", type: "checkers", imageName: "game_checkers"),
        GameItem(title: "Chess", type: "chess", imageName: "game_chess"),
        GameItem(title: "Reversi", type: "reversi", imageName: "game_reversi"),
        GameItem(title: "Tic-Tac-Toe", type: "tictactoe", imageName: "game_tictactoe"),
        GameItem(title: "Dots & Boxes", type: "dotsboxes", imageName: "game_dotsboxes"),
        GameItem(title: "Battleship", type: "battleship", imageName: "game_battleship"),
        GameItem(title: "Word Duel", type: "wordduel", imageName: "game_wordduel"),
        GameItem(title: "Sudoku Duel", type: "sudokuduel", imageName: "game_sudokuduel"),
        GameItem(title: "Trivia", type: "trivia", imageName: "game_trivia"),
        GameItem(title: "Hangman", type: "hangman", imageName: "game_hangman"),
        GameItem(title: "Scramble", type: "scramble", imageName: "game_scramble"),
        GameItem(title: "Bingo", type: "bingo", imageName: "game_bingo"),
        GameItem(title: "Mines", type: "mines", imageName: "game_mines"),
        GameItem(title: "2048 Duel", type: "duel2048", imageName: "game_2048"),
        GameItem(title: "Fast Tap", type: "fasttap", imageName: "game_fasttap"),
        GameItem(title: "Memory", type: "memory", imageName: "game_memory"),
        GameItem(title: "Match 3", type: "match3", imageName: "game_match3"),
        GameItem(title: "Snake Race", type: "snake", imageName: "game_snake"),
        GameItem(title: "Runner", type: "runner", imageName: "game_runner"),
        GameItem(title: "Air Hockey", type: "airhockey", imageName: "game_airhockey"),
        GameItem(title: "Quiz Rush", type: "quizrush", imageName: "game_quizrush"),
        GameItem(title: "Rock Paper", type: "rps", imageName: "game_rps")
    ]
    
    private let gridColumns: CGFloat = 5
    private let cellSpacing: CGFloat = 8
    private let sectionInset: CGFloat = 8
    
    private var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        let titleLabel = UILabel()
        titleLabel.text = "Choose a Game"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = cellSpacing
        layout.minimumInteritemSpacing = cellSpacing
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.register(GameCell.self, forCellWithReuseIdentifier: GameCell.reuseIdentifier)
        view.addSubview(collectionView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: sectionInset),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -sectionInset),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -4)
        ])
    }
}

extension GameSelectionViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return games.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GameCell.reuseIdentifier, for: indexPath) as? GameCell else {
            return UICollectionViewCell()
        }
        let game = games[indexPath.item]
        cell.configure(with: game)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let game = games[indexPath.item]
        delegate?.didSelectGame(game.type)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing = cellSpacing * (gridColumns - 1) + sectionInset * 2
        let width = (collectionView.bounds.width - totalSpacing) / gridColumns
        // Square cells for 1:1 aspect ratio images
        return CGSize(width: width, height: width + 16) // extra space for label
    }
}

final class GameCell: UICollectionViewCell {
    static let reuseIdentifier = "GameCell"
    
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        contentView.addSubview(imageView)
        
        titleLabel.font = .systemFont(ofSize: 10, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        contentView.addSubview(titleLabel)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor), // 1:1 aspect
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -2)
        ])
    }
    
    func configure(with item: GameItem) {
        titleLabel.text = item.title
        imageView.image = UIImage(named: item.imageName)
    }
}

