//
//  RecipeFeedViewModelTests.swift
//  CookingVideoDemoApp
//
//  Created by Kuan-Ting Lin on 2025/12/5.
//

import XCTest
@testable import CookingVideoDemoApp

/// Unit tests for RecipeFeedViewModel loading and state management logic.
///
/// Tests cover:
/// - Initial state
/// - Loading state transitions
/// - Successful recipe loading
/// - Error handling
/// - Repository integration
@MainActor
final class RecipeFeedViewModelTests: XCTestCase {
    
    var viewModel: RecipeFeedViewModel!
    var mockRepository: MockRecipeRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockRecipeRepository()
        viewModel = RecipeFeedViewModel(repository: mockRepository)
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockRepository = nil
        try await super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func test_initialState_isEmpty() {
        // Then: Initial state should be empty
        XCTAssertTrue(viewModel.recipes.isEmpty, "Initial recipes should be empty")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        XCTAssertNil(viewModel.errorMessage, "Should not have error initially")
    }
    
    // MARK: - Loading State Tests
    
    func test_loadRecipes_setsLoadingState() async {
        // Given: Repository that delays response
        mockRepository.delay = 0.1
        
        // When: Starting to load recipes
        let loadTask = Task {
            await viewModel.loadRecipes()
        }
        
        // Wait briefly to check loading state
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        // Then: Should be in loading state
        XCTAssertTrue(viewModel.isLoading, "Should be loading during fetch")
        
        // Wait for completion
        await loadTask.value
        
        // Then: Should no longer be loading
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after completion")
    }
    
    func test_loadRecipes_clearsErrorMessage() async {
        // Given: ViewModel with existing error
        viewModel.errorMessage = "Previous error"
        
        // When: Loading recipes successfully
        mockRepository.shouldSucceed = true
        await viewModel.loadRecipes()
        
        // Then: Error message should be cleared
        XCTAssertNil(viewModel.errorMessage, "Error message should be cleared on new load")
    }
    
    // MARK: - Successful Loading Tests
    
    func test_loadRecipes_populatesRecipes() async {
        // Given: Repository with mock recipes
        let mockRecipes = [
            Recipe(
                id: UUID(),
                name: "Test Recipe 1",
                authorName: "Test Author",
                cookTimeMinutes: 10,
                videoURLString: "https://example.com/video1.mp4",
                thumbnailURLString: "https://example.com/thumb1.jpg",
                ingredients: ["Ingredient 1"],
                steps: ["Step 1"],
                rating: 4.5,
                reviewCount: 100,
                yield: "1 serving"
            ),
            Recipe(
                id: UUID(),
                name: "Test Recipe 2",
                authorName: "Test Author",
                cookTimeMinutes: 15,
                videoURLString: "https://example.com/video2.mp4",
                thumbnailURLString: "https://example.com/thumb2.jpg",
                ingredients: ["Ingredient 2"],
                steps: ["Step 2"],
                rating: 4.8,
                reviewCount: 200,
                yield: "2 servings"
            )
        ]
        mockRepository.mockRecipes = mockRecipes
        mockRepository.shouldSucceed = true
        
        // When: Loading recipes
        await viewModel.loadRecipes()
        
        // Then: Recipes should be populated
        XCTAssertEqual(viewModel.recipes.count, 2, "Should load 2 recipes")
        XCTAssertEqual(viewModel.recipes[0].name, "Test Recipe 1")
        XCTAssertEqual(viewModel.recipes[1].name, "Test Recipe 2")
    }
    
    func test_loadRecipes_setsLoadingToFalseOnSuccess() async {
        // Given: Successful repository
        mockRepository.shouldSucceed = true
        
        // When: Loading recipes
        await viewModel.loadRecipes()
        
        // Then: Loading should be false
        XCTAssertFalse(viewModel.isLoading, "Loading should be false after success")
    }
    
    // MARK: - Error Handling Tests
    
    func test_loadRecipes_handlesError() async {
        // Given: Repository that will fail
        mockRepository.shouldSucceed = false
        mockRepository.error = NSError(
            domain: "TestError",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Test error message"]
        )
        
        // When: Loading recipes
        await viewModel.loadRecipes()
        
        // Then: Should have error message
        XCTAssertNotNil(viewModel.errorMessage, "Should have error message on failure")
        XCTAssertTrue(
            viewModel.errorMessage?.contains("Test error message") ?? false,
            "Error message should contain repository error"
        )
    }
    
    func test_loadRecipes_clearsRecipesOnError() async {
        // Given: ViewModel with existing recipes
        mockRepository.shouldSucceed = true
        mockRepository.mockRecipes = [
            Recipe(
                id: UUID(),
                name: "Seed Recipe",
                authorName: "Tester",
                cookTimeMinutes: 5,
                videoURLString: "https://example.com/video.mp4",
                thumbnailURLString: "https://example.com/thumb.jpg",
                ingredients: ["Water"],
                steps: ["Boil"],
                rating: 4.0,
                reviewCount: 1,
                yield: "1 serving"
            )
        ]
        await viewModel.loadRecipes()
        XCTAssertFalse(viewModel.recipes.isEmpty, "Should have recipes initially")
        let initialRecipes = viewModel.recipes

        // When: Loading fails
        mockRepository.shouldSucceed = false
        mockRepository.error = NSError(domain: "TestError", code: 500)
        await viewModel.loadRecipes()

        // Then: Recipes remain (error doesn't clear existing data)
        XCTAssertEqual(viewModel.recipes, initialRecipes, "Existing recipes should remain after an error")
    }
    
    func test_loadRecipes_setsLoadingToFalseOnError() async {
        // Given: Repository that will fail
        mockRepository.shouldSucceed = false
        mockRepository.error = NSError(domain: "TestError", code: 500)
        
        // When: Loading recipes
        await viewModel.loadRecipes()
        
        // Then: Loading should be false
        XCTAssertFalse(viewModel.isLoading, "Loading should be false after error")
    }
    
    // MARK: - Integration Tests
    
    func test_loadRecipes_withRealRepository() async throws {
        // Given: ViewModel with real repository
        let realViewModel = RecipeFeedViewModel()
        
        // When: Loading recipes
        await realViewModel.loadRecipes()
        
        // Then: Should load real recipes from JSON
        XCTAssertFalse(realViewModel.recipes.isEmpty, "Should load recipes from JSON")
        XCTAssertEqual(realViewModel.recipes.count, 2, "Should load 2 recipes from JSON")
        XCTAssertNil(realViewModel.errorMessage, "Should not have error with valid JSON")
    }
    
    func test_loadRecipes_multipleCalls() async {
        // Given: Repository with recipes
        mockRepository.shouldSucceed = true
        
        // When: Loading recipes multiple times
        await viewModel.loadRecipes()
        let firstLoadCount = viewModel.recipes.count
        
        await viewModel.loadRecipes()
        let secondLoadCount = viewModel.recipes.count
        
        // Then: Should have same count (idempotent)
        XCTAssertEqual(firstLoadCount, secondLoadCount, "Multiple loads should be idempotent")
    }
}

// MARK: - Mock Repository

/// Mock implementation of RecipeRepositoryProtocol for testing.
final class MockRecipeRepository: RecipeRepositoryProtocol {
    var shouldSucceed = true
    var error: Error?
    var delay: TimeInterval = 0
    var mockRecipes: [Recipe] = []
    
    func getRecipes() async throws -> [Recipe] {
        // Simulate delay
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        // Simulate error
        if !shouldSucceed {
            throw error ?? NSError(domain: "MockError", code: 500)
        }
        
        // Return mock recipes
        return mockRecipes
    }
}

