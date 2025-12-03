//
//  Recipe.swift
//  CookingVideoDemoApp
//
//  Created by Kuan-Ting Lin on 2025/12/3.
//

import Foundation

struct Recipe: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let authorName: String
    let cookTimeMinutes: Int
    let videoURLString: String
    let thumbnailURLString: String
    let ingredients: [String]
    let steps: [String]
    let rating: Double
    let reviewCount: Int
    let yield: String
    
    // Computed properties for URL safety
    var videoURL: URL? { URL(string: videoURLString) }
    var thumbnailURL: URL? { URL(string: thumbnailURLString) }
}
