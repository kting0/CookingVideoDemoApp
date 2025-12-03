//
//  SavedRecipesStore.swift
//  CookingVideoDemoApp
//
//  Created by Kuan-Ting Lin on 2025/12/3.
//

import Foundation
import Observation

/// Store that manages saved/bookmarked recipe state using UserDefaults.
/// Uses Swift 5.9's @Observable for automatic UI updates.
@MainActor
@Observable
final class SavedRecipesStore {
    
    // MARK: - Properties
    
    /// Set of saved recipe IDs for fast lookup
    private(set) var savedRecipeIDs: Set<UUID> = []
    
    private let userDefaultsKey = "savedRecipeIDs"
    
    // MARK: - Initialization
    
    init() {
        loadSavedRecipes()
    }
    
    // MARK: - Public Methods
    
    /// Check if a recipe is currently saved
    func isSaved(_ recipeID: UUID) -> Bool {
        savedRecipeIDs.contains(recipeID)
    }
    
    /// Toggle the saved state of a recipe
    func toggleSaved(_ recipeID: UUID) {
        if savedRecipeIDs.contains(recipeID) {
            savedRecipeIDs.remove(recipeID)
        } else {
            savedRecipeIDs.insert(recipeID)
        }
        persistSavedRecipes()
    }
    
    /// Save a recipe (add to bookmarks)
    func saveRecipe(_ recipeID: UUID) {
        guard !savedRecipeIDs.contains(recipeID) else { return }
        savedRecipeIDs.insert(recipeID)
        persistSavedRecipes()
    }
    
    /// Unsave a recipe (remove from bookmarks)
    func unsaveRecipe(_ recipeID: UUID) {
        guard savedRecipeIDs.contains(recipeID) else { return }
        savedRecipeIDs.remove(recipeID)
        persistSavedRecipes()
    }
    
    // MARK: - Private Methods
    
    /// Load saved recipe IDs from UserDefaults
    private func loadSavedRecipes() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let uuidStrings = try? JSONDecoder().decode([String].self, from: data) else {
            savedRecipeIDs = []
            return
        }
        
        // Convert strings back to UUIDs
        savedRecipeIDs = Set(uuidStrings.compactMap { UUID(uuidString: $0) })
    }
    
    /// Persist saved recipe IDs to UserDefaults
    private func persistSavedRecipes() {
        // Convert UUIDs to strings for JSON encoding
        let uuidStrings = savedRecipeIDs.map { $0.uuidString }
        
        guard let data = try? JSONEncoder().encode(uuidStrings) else {
            print("❌ Failed to encode saved recipe IDs")
            return
        }
        
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
        print("✅ Persisted \(savedRecipeIDs.count) saved recipes")
    }
}
