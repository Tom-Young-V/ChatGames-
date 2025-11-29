# Copilot / AI Agent Instructions for ChatGames+

Short, actionable guidance to help an AI coding agent be productive in this repo.

**Big Picture**:
- **Purpose**: This is an iMessage extension that hosts multiple small multiplayer games (currently Connect 4). The extension lives in `ChatGames+ MessagesExtension/` and the Xcode project/workspace is at the repo root (`ChatGames+.xcodeproj`, `ChatGames+.xcworkspace`).
- **Major components**:
  - `MessagesViewController.swift`: entry point for the Messages extension; manages conversation lifecycle, decodes messages, and switches between selection and game view.
  - `GameProtocol.swift`: the single `Game` protocol (Codable) and wrapper types (`GameMessage`, `GameMove`, `GameState`). New games must conform to this protocol.
  - `GameManager.swift`: singleton factory + encode/decode helpers. All game JSON encoding/decoding is centralized here.
  - `Connect4*` files: `Connect4Game.swift`, `Connect4BoardView.swift`, `Connect4ViewController.swift` — a complete example implementation to follow.
  - `GameSelectionViewController.swift`: grid of available games; add new entries here to expose games in the UI.
  - `StatsManager.swift`: simple persistence (UserDefaults) for per-game stats.

**Data & Message flow (key patterns)**:
- Games are encoded as a `GameMessage` which contains `gameType` and `gameData` (a `Data` blob). The message is base64-encoded and placed into the message URL under the `gameData` query param.
- `MessagesViewController.didReceive(_:)` extracts `gameData` from the message URL, base64-decodes it to `Data`, and calls `GameManager.shared.decodeGame(from:)`.
- To send a game update: use `GameManager.shared.encodeGame(_:)` → base64 → `URLComponents` query `gameData` → construct `MSMessage` with `MSMessageTemplateLayout` → `conversation.insert(message)`.

**How to add a new game (concrete steps)**
1. Implement a `struct` conforming to `Game` in `ChatGames+ MessagesExtension/` and make it `Codable`.
2. Add encoding/decoding logic implicitly via `Codable` (see `Connect4Game.swift` for custom CodingKeys example).
3. Update `GameManager.createGame(type:)` to return the new game for a new `type` string, and update `decodeGame(from:)` to handle the new `gameType` value.
4. Add a `GameItem` entry in `GameSelectionViewController.swift` (title, `type` string, `imageName`). Add matching image assets under `Assets.xcassets` (use `game_*` naming convention used here).
5. If a new game needs a dedicated view controller, follow `Connect4ViewController.swift` patterns: keep a committed `game` model, a `pendingGame` for unsent moves, and use a delegate to notify `MessagesViewController` to send the update.

**Project-specific conventions / gotchas**
- `GameMessage` wraps the encoded game `Data` and includes a `version` field — keep versioning in mind when changing encoding.
- The code uses the Swift 5 `any Game` existential in a few places (e.g., `currentGame: (any Game)?`). Follow that style rather than older protocol-typed patterns.
- UI / animation details:
  - `Connect4BoardView` uses view tags (`pieceTag = 999`, `tapAreaBaseTag = 1000`) to find subviews reliably — preserve tagging when updating UI code.
  - `Connect4BoardView.updateBoard(_:isInteractive:)` uses `previousBoard` diffing to detect and animate newly-added pieces — reusing that approach helps preserve smooth animations.
- Stats persist to `UserDefaults` with keys prefixed by `gameStats_` (see `StatsManager.swift`). Use `StatsManager.shared.recordGameResult(...)` to record outcomes.
- For development, `MessagesViewController` exposes `debugPlayBothSides: Bool = true` to play both sides locally — useful for unit testing UI flows without a second device.

**Build / run / debugging**
- Recommended: open the workspace in Xcode and run the Messages extension target to debug in Simulator. In Terminal (zsh) you can:
  - Open workspace in Xcode: `open "ChatGames+.xcworkspace"`
  - Build via `xcodebuild` (simulator example):
    `xcodebuild -workspace "ChatGames+.xcworkspace" -scheme "ChatGames+" -configuration Debug -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 14' build`
  - Running the Messages extension often requires launching via Xcode (select the Messages host app / extension target). If code-signing blocks appear, prefer running directly from Xcode with a development team configured.

**Files to reference when working here**
- `ChatGames+ MessagesExtension/GameManager.swift` — encoding/decoding and factory
- `ChatGames+ MessagesExtension/GameProtocol.swift` — `Game` protocol and `GameMessage` wrapper
- `ChatGames+ MessagesExtension/MessagesViewController.swift` — conversation lifecycle, message parsing, and UI switching
- `ChatGames+ MessagesExtension/Connect4*.swift` — full example implementing `Game` + UI + animations
- `ChatGames+ MessagesExtension/GameSelectionViewController.swift` — where games are registered for UI
- `ChatGames+ MessagesExtension/StatsManager.swift` — persistence pattern

**When editing or adding code**
- Add new games under `ChatGames+ MessagesExtension/` and ensure Codable conformance. Update `GameManager`'s `createGame` and `decodeGame` switch statements.
- Preserve the `GameMessage` structure when encoding/decoding so older clients can still parse messages. If you change binary layout, increment `version` and handle backwards compatibility in `GameManager.decodeGame`.
- Keep UI and model separation: view controllers should operate on `Game` models and not assume storage mechanics; `MessagesViewController` owns sending logic.

If anything in these instructions is unclear or you want more examples (e.g., a template `AGENT.md` section, or a sample new-game implementation), tell me which area to expand and I will iterate.
