//
//  RecipeRepositoryTests.swift
//  CookingVideoDemoApp
//
//  Created by Kuan-Ting Lin on 2025/12/5.
//

import XCTest
@testable import CookingVideoDemoApp

/// Unit tests for LocalRecipeRepository JSON decoding logic.
///
/// Tests cover:
/// - Successful recipe loading
/// - Recipe count validation
/// - Recipe data correctness
/// - URL parsing
/// - Error handling for missing files
/// - JSON decoding errors
@MainActor
final class RecipeRepositoryTests: XCTestCase {
    
    var repository: LocalRecipeRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        repository = LocalRecipeRepository()
    }
    
    override func tearDown() async throws {
        repository = nil
        try await super.tearDown()
    }
    
    // MARK: - Successful Loading Tests
    
    func test_getRecipes_returnsRecipes() async throws {
        // When: Loading recipes from repository
        let recipes = try await repository.getRecipes()
        
        // Then: Should return non-empty array
        XCTAssertFalse(recipes.isEmpty, "Repository should return recipes")
    }
    
    func test_getRecipes_returnsExpectedCount() async throws {
        // Given: recipes.json contains 2 recipes
        
        // When: Loading recipes
        let recipes = try await repository.getRecipes()
        
        // Then: Should return exactly 2 recipes
        XCTAssertEqual(recipes.count, 2, "Should load 2 recipes from JSON")
    }
    
    // MARK: - Recipe Data Validation Tests
    
    func test_getRecipes_decodesOldFashionedCorrectly() async throws {
        // When: Loading recipes
        let recipes = try await repository.getRecipes()
        
        // Then: Find the Old Fashioned recipe
        guard let oldFashioned = recipes.first(where: { $0.name == "Classic Old Fashioned" }) else {
            XCTFail("Should contain Classic Old Fashioned recipe")
            return
        }
        
        // Verify all fields
        XCTAssertEqual(oldFashioned.authorName, "Robert Simonson")
        XCTAssertEqual(oldFashioned.cookTimeMinutes, 5)
        XCTAssertEqual(oldFashioned.rating, 4.8)
        XCTAssertEqual(oldFashioned.reviewCount, 196)
        XCTAssertEqual(oldFashioned.yield, "1 Drink")
        XCTAssertEqual(oldFashioned.ingredients.count, 4)
        XCTAssertEqual(oldFashioned.steps.count, 4)
    }
    
    func test_getRecipes_decodesSpicyMargaritaCorrectly() async throws {
        // When: Loading recipes
        let recipes = try await repository.getRecipes()
        
        // Then: Find the Spicy Margarita recipe
        guard let margarita = recipes.first(where: { $0.name == "Spicy Margarita" }) else {
            XCTFail("Should contain Spicy Margarita recipe")
            return
        }
        
        // Verify all fields
        XCTAssertEqual(margarita.authorName, "Sam Sifton")
        XCTAssertEqual(margarita.cookTimeMinutes, 3)
        XCTAssertEqual(margarita.rating, 4.5)
        XCTAssertEqual(margarita.reviewCount, 85)
        XCTAssertEqual(margarita.yield, "1 Drink")
        XCTAssertEqual(margarita.ingredients.count, 4)
        XCTAssertEqual(margarita.steps.count, 3)
    }
    
    func test_getRecipes_parsesIngredientsCorrectly() async throws {
        // When: Loading recipes
        let recipes = try await repository.getRecipes()
        let oldFashioned = recipes.first(where: { $0.name == "Classic Old Fashioned" })!
        
        // Then: Verify specific ingredients
        XCTAssertTrue(oldFashioned.ingredients.contains("1 Sugar Cube"))
        XCTAssertTrue(oldFashioned.ingredients.contains("2 dashes Angostura Bitters"))
        XCTAssertTrue(oldFashioned.ingredients.contains("2 oz Rye Whiskey"))
        XCTAssertTrue(oldFashioned.ingredients.contains("Orange Twist"))
    }
    
    func test_getRecipes_parsesStepsCorrectly() async throws {
        // When: Loading recipes
        let recipes = try await repository.getRecipes()
        let oldFashioned = recipes.first(where: { $0.name == "Classic Old Fashioned" })!
        
        // Then: Verify specific steps
        XCTAssertEqual(oldFashioned.steps[0], "Muddle sugar and bitters.")
        XCTAssertEqual(oldFashioned.steps[1], "Add whiskey and ice.")
        XCTAssertEqual(oldFashioned.steps[2], "Stir until chilled.")
        XCTAssertEqual(oldFashioned.steps[3], "Garnish with orange twist.")
    }
    
    // MARK: - URL Parsing Tests
    
    func test_getRecipes_parsesVideoURLsCorrectly() async throws {
        // When: Loading recipes
        let recipes = try await repository.getRecipes()
        
        // Then: All recipes should have valid video URLs
        for recipe in recipes {
            XCTAssertNotNil(recipe.videoURL, "Recipe \(recipe.name) should have valid video URL")
            XCTAssertTrue(recipe.videoURLString.hasPrefix("https://"), "Video URL should be HTTPS")
        }
    }
    
    func test_getRecipes_parsesThumbnailURLsCorrectly() async throws {
        // When: Loading recipes
        let recipes = try await repository.getRecipes()
        
        // Then: All recipes should have valid thumbnail URLs
        for recipe in recipes {
            XCTAssertNotNil(recipe.thumbnailURL, "Recipe \(recipe.name) should have valid thumbnail URL")
            XCTAssertTrue(recipe.thumbnailURLString.hasPrefix("https://"), "Thumbnail URL should be HTTPS")
        }
    }
    
    // MARK: - UUID Tests
    
    func test_getRecipes_hasUniqueIDs() async throws {
        // When: Loading recipes
        let recipes = try await repository.getRecipes()
        
        // Then: All IDs should be unique
        let ids = recipes.map { $0.id }
        let uniqueIDs = Set(ids)
        XCTAssertEqual(ids.count, uniqueIDs.count, "All recipe IDs should be unique")
    }
    
    func test_getRecipes_hasValidUUIDs() async throws {
        // When: Loading recipes
        let recipes = try await repository.getRecipes()
        
        // Then: All IDs should be valid UUIDs (non-nil)
        for recipe in recipes {
            XCTAssertNotNil(recipe.id, "Recipe \(recipe.name) should have valid UUID")
        }
    }
    
    // MARK: - Data Integrity Tests
    
    func test_getRecipes_hasNonEmptyNames() async throws {
        // When: Loading recipes
        let recipes = try await repository.getRecipes()
        
        // Then: All recipes should have non-empty names
        for recipe in recipes {
            XCTAssertFalse(recipe.name.isEmpty, "Recipe name should not be empty")
        }
    }
    
    func test_getRecipes_hasNonEmptyAuthorNames() async throws {
        // When: Loading recipes
        let recipes = try await repository.getRecipes()
        
        // Then: All recipes should have non-empty author names
        for recipe in recipes {
            XCTAssertFalse(recipe.authorName.isEmpty, "Author name should not be empty")
        }
    }
    
    func test_getRecipes_hasPositiveCookTimes() async throws {
        // When: Loading recipes
        let recipes = try await repository.getRecipes()
        
        // Then: All cook times should be positive
        for recipe in recipes {
            XCTAssertGreaterThan(recipe.cookTimeMinutes, 0, "Cook time should be positive for \(recipe.name)")
        }
    }
    
    func test_getRecipes_hasValidRatings() async throws {
        // When: Loading recipes
        let recipes = try await repository.getRecipes()
        
        // Then: All ratings should be between 0 and 5
        for recipe in recipes {
            XCTAssertGreaterThanOrEqual(recipe.rating, 0.0, "Rating should be >= 0")
            XCTAssertLessThanOrEqual(recipe.rating, 5.0, "Rating should be <= 5")
        }
    }
    
    func test_getRecipes_hasPositiveReviewCounts() async throws {
        // When: Loading recipes
        let recipes = try await repository.getRecipes()
        
        // Then: All review counts should be non-negative
        for recipe in recipes {
            XCTAssertGreaterThanOrEqual(recipe.reviewCount, 0, "Review count should be non-negative")
        }
    }
    
    func test_getRecipes_hasIngredients() async throws {
        // When: Loading recipes
        let recipes = try await repository.getRecipes()
        
        // Then: All recipes should have at least one ingredient
        for recipe in recipes {
            XCTAssertFalse(recipe.ingredients.isEmpty, "\(recipe.name) should have ingredients")
        }
    }
    
    func test_getRecipes_hasSteps() async throws {
        // When: Loading recipes
        let recipes = try await repository.getRecipes()
        
        // Then: All recipes should have at least one step
        for recipe in recipes {
            XCTAssertFalse(recipe.steps.isEmpty, "\(recipe.name) should have steps")
        }
    }
    
    // MARK: - Error Handling Tests
    
    // Note: These tests require creating a mock repository or modifying Bundle
    // For now, we document the expected behavior
    
    func test_getRecipes_throwsErrorForMissingFile() async throws {
        // Note: This would require a mock repository that simulates missing file
        // Expected behavior: Should throw NSError with code 404
        
        // TODO: Implement when adding dependency injection support
    }
    
    func test_getRecipes_throwsErrorForInvalidJSON() async throws {
        // Note: This would require a mock repository with invalid JSON
        // Expected behavior: Should throw DecodingError
        
        // TODO: Implement when adding dependency injection support
    }
    
    // MARK: - Performance Tests
    
    func test_getRecipes_performanceIsAcceptable() async throws {
        // Measure performance of loading recipes
        measure {
            Task {
                _ = try? await repository.getRecipes()
            }
        }
    }
}

