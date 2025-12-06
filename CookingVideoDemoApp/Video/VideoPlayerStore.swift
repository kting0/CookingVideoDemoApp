//
//  VideoPlayerStore.swift
//  CookingVideoDemoApp
//
//  Created by ChatGPT on 2025/12/3.
//

import Foundation
import Observation

/// Maintains shared `PlayerViewModel` instances keyed by recipe ID so playback
/// state survives navigation (e.g., when jumping to a recipe detail view and
/// returning to the feed).
@MainActor
@Observable
final class VideoPlayerStore {

    /// Cached player view models keyed by recipe ID.
    private var players: [UUID: PlayerViewModel] = [:]

    /// Fetches or creates the player for a recipe.
    func viewModel(for recipe: Recipe) -> PlayerViewModel? {
        guard let videoURL = recipe.videoURL else { return nil }

        if let cached = players[recipe.id] {
            return cached
        }

        let viewModel = PlayerViewModel(videoURL: videoURL)
        players[recipe.id] = viewModel
        return viewModel
    }

    /// Pauses all cached players except the one identified by `recipeID`.
    func pauseAll(except recipeID: UUID?) {
        for (id, player) in players where id != recipeID {
            player.pause()
        }
    }
}
