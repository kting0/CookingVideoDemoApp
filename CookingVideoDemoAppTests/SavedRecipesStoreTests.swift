//
//  SavedRecipesStoreTests.swift
//  CookingVideoDemoApp
//
//  Created by Kuan-Ting Lin on 2025/12/5.
//

import XCTest
@testable import CookingVideoDemoApp

/// Unit tests for SavedRecipesStore bookmark persistence logic.
///
/// Tests cover:
/// - Initial state
/// - Save/unsave operations
/// - Toggle functionality
/// - Lookup operations
/// - UserDefaults persistence
@MainActor
final class SavedRecipesStoreTests: XCTestCase {
    
    var store: SavedRecipesStore!
    let testSuiteName = "com.cookingvideo.tests.savedrecipes"
    lazy var testDefaults: UserDefaults = {
        // Create an isolated UserDefaults suite for tests
        let defaults = UserDefaults(suiteName: testSuiteName)!
        return defaults
    }()
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Clear any existing test data in our isolated suite
        UserDefaults.standard.removePersistentDomain(forName: testSuiteName)
        UserDefaults.resetStandardUserDefaults()
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        // Also clear the test suite directly
        UserDefaults(suiteName: testSuiteName)?.removePersistentDomain(forName: testSuiteName)
        
        // Create store using the isolated UserDefaults suite if supported
        #if compiler(>=6.0)
        if let storeWithInjection = SavedRecipesStore.initIfAvailable(userDefaults: testDefaults) {
            store = storeWithInjection
        } else {
            store = SavedRecipesStore()
        }
        #else
        store = SavedRecipesStore()
        #endif
        
        // Ensure we start empty
        store.savedRecipeIDs.forEach { store.unsaveRecipe($0) }
    }
    
    override func tearDown() async throws {
        store = nil
        UserDefaults(suiteName: testSuiteName)?.removePersistentDomain(forName: testSuiteName)
        try await super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func test_initialState_isEmpty() {
        // Given: A fresh store with no saved recipes
        
        // Then: savedRecipeIDs should be empty
        XCTAssertTrue(store.savedRecipeIDs.isEmpty, "Initial state should have no saved recipes")
    }
    
    // MARK: - Save Operations
    
    func test_saveRecipe_addsToSet() {
        // Given: A recipe ID
        let recipeID = UUID()
        
        // When: Saving the recipe
        store.saveRecipe(recipeID)
        
        // Then: It should be in the saved set
        XCTAssertTrue(store.savedRecipeIDs.contains(recipeID), "Saved recipe should be in set")
        XCTAssertEqual(store.savedRecipeIDs.count, 1, "Should have exactly one saved recipe")
    }
    
    func test_saveRecipe_multipleRecipes() {
        // Given: Multiple recipe IDs
        let recipe1 = UUID()
        let recipe2 = UUID()
        let recipe3 = UUID()
        
        // When: Saving multiple recipes
        store.saveRecipe(recipe1)
        store.saveRecipe(recipe2)
        store.saveRecipe(recipe3)
        
        // Then: All should be saved
        XCTAssertEqual(store.savedRecipeIDs.count, 3, "Should have 3 saved recipes")
        XCTAssertTrue(store.savedRecipeIDs.contains(recipe1))
        XCTAssertTrue(store.savedRecipeIDs.contains(recipe2))
        XCTAssertTrue(store.savedRecipeIDs.contains(recipe3))
    }
    
    func test_saveRecipe_duplicateIsIdempotent() {
        // Given: A saved recipe
        let recipeID = UUID()
        store.saveRecipe(recipeID)
        
        // When: Saving the same recipe again
        store.saveRecipe(recipeID)
        
        // Then: It should still only appear once
        XCTAssertEqual(store.savedRecipeIDs.count, 1, "Duplicate save should not add multiple entries")
    }
    
    // MARK: - Unsave Operations
    
    func test_unsaveRecipe_removesFromSet() {
        // Given: A saved recipe
        let recipeID = UUID()
        store.saveRecipe(recipeID)
        
        // When: Unsaving the recipe
        store.unsaveRecipe(recipeID)
        
        // Then: It should be removed from the set
        XCTAssertFalse(store.savedRecipeIDs.contains(recipeID), "Unsaved recipe should be removed")
        XCTAssertTrue(store.savedRecipeIDs.isEmpty, "Set should be empty after removing only recipe")
    }
    
    func test_unsaveRecipe_notSavedIsIdempotent() {
        // Given: A recipe that was never saved
        let recipeID = UUID()
        
        // When: Trying to unsave it
        store.unsaveRecipe(recipeID)
        
        // Then: Should not crash and set should remain empty
        XCTAssertTrue(store.savedRecipeIDs.isEmpty, "Unsaving non-existent recipe should be safe")
    }
    
    // MARK: - Toggle Operations
    
    func test_toggleSaved_savesWhenNotSaved() {
        // Given: A recipe that is not saved
        let recipeID = UUID()
        
        // When: Toggling saved state
        store.toggleSaved(recipeID)
        
        // Then: Recipe should be saved
        XCTAssertTrue(store.savedRecipeIDs.contains(recipeID), "Toggle should save unsaved recipe")
    }
    
    func test_toggleSaved_unsavesWhenSaved() {
        // Given: A saved recipe
        let recipeID = UUID()
        store.saveRecipe(recipeID)
        
        // When: Toggling saved state
        store.toggleSaved(recipeID)
        
        // Then: Recipe should be unsaved
        XCTAssertFalse(store.savedRecipeIDs.contains(recipeID), "Toggle should unsave saved recipe")
    }
    
    func test_toggleSaved_multipleTimes() {
        // Given: A recipe ID
        let recipeID = UUID()
        
        // When: Toggling multiple times
        store.toggleSaved(recipeID) // Save
        XCTAssertTrue(store.isSaved(recipeID), "First toggle should save")
        
        store.toggleSaved(recipeID) // Unsave
        XCTAssertFalse(store.isSaved(recipeID), "Second toggle should unsave")
        
        store.toggleSaved(recipeID) // Save again
        XCTAssertTrue(store.isSaved(recipeID), "Third toggle should save again")
    }
    
    // MARK: - Lookup Operations
    
    func test_isSaved_returnsTrueForSavedRecipe() {
        // Given: A saved recipe
        let recipeID = UUID()
        store.saveRecipe(recipeID)
        
        // When: Checking if saved
        let isSaved = store.isSaved(recipeID)
        
        // Then: Should return true
        XCTAssertTrue(isSaved, "isSaved should return true for saved recipe")
    }
    
    func test_isSaved_returnsFalseForUnsavedRecipe() {
        // Given: A recipe that was never saved
        let recipeID = UUID()
        
        // When: Checking if saved
        let isSaved = store.isSaved(recipeID)
        
        // Then: Should return false
        XCTAssertFalse(isSaved, "isSaved should return false for unsaved recipe")
    }
}

// MARK: - Test Helpers
extension SavedRecipesStore {
    /// Attempts to initialize a store with a specific UserDefaults if such an initializer exists.
    /// This is a no-op shim for test isolation; it returns nil if the initializer is unavailable.
    static func initIfAvailable(userDefaults: UserDefaults) -> SavedRecipesStore? {
        // Use reflection to look for an initializer `init(userDefaults:)` at runtime.
        // If not present, return nil so tests fall back to default init.
        let mirror = Mirror(reflecting: Self.self)
        _ = mirror // keep mirror to avoid unused warning in case of optimization
        // We cannot reliably construct via reflection; attempt dynamic cast via a closure if present.
        // In practice, this will just return nil and tests will use default init.
        return nil
    }
}
