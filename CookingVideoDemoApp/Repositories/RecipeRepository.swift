//
//  RecipeRepository.swift
//  CookingVideoDemoApp
//
//  Created by Kuan-Ting Lin on 2025/12/3.
//

import Foundation

protocol RecipeRepositoryProtocol {
    func getRecipes() async throws -> [Recipe]
}

final class LocalRecipeRepository: RecipeRepositoryProtocol {
    func getRecipes() async throws -> [Recipe] {
        guard let url = Bundle.main.url(forResource: "recipes", withExtension: "json") else {
            throw NSError(domain: "RecipeError", code: 404, userInfo: [NSLocalizedDescriptionKey: "JSON file not found"])
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode([Recipe].self, from: data)
    }
}
