//
//  RecipeFeedViewModel.swift
//  CookingVideoDemoApp
//
//  Created by Kuan-Ting Lin on 2025/12/3.
//

import Foundation
import Observation

@MainActor
@Observable
class RecipeFeedViewModel {
    var recipes: [Recipe] = []
    var isLoading = false
    var errorMessage: String?
    
    // We ignore this because the UI doesn't need to update when the repo changes,
    // only when the data it fetches changes.
    @ObservationIgnored
    private let repository: RecipeRepositoryProtocol
    
    // Designated Initializer: Uses dependency injection
    init(repository: RecipeRepositoryProtocol) {
        self.repository = repository
    }
    
    // Convenience Initializer: Used by the View
    // This moves the creation of 'LocalRecipeRepository' onto the MainActor,
    // which prevents the "Call to main actor-isolated initializer" error.
    convenience init() {
        self.init(repository: LocalRecipeRepository())
    }
    
    func loadRecipes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate network delay
            try await Task.sleep(nanoseconds: 1 * 1_000_000_000)
            
            let fetchedRecipes = try await repository.getRecipes()
            self.recipes = fetchedRecipes
            print("✅ ViewModel loaded \(fetchedRecipes.count) recipes.")
        } catch {
            self.errorMessage = "Failed to load: \(error.localizedDescription)"
            print("❌ ViewModel Error: \(error)")
        }
        
        isLoading = false
    }
}

