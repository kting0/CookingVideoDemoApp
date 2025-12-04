//
//  RecipeDetailView.swift
//  CookingVideoDemoApp
//
//  Created by Kuan-Ting Lin on 2025/12/4.
//

import SwiftUI

/// Full-screen recipe detail view with hero image, metadata, ingredients, and cooking steps.
///
/// Features:
/// - Hero image with gradient overlay
/// - Complete recipe metadata (author, rating, cook time, yield)
/// - Bookmark button synced with feed
/// - Ingredients section with formatted list
/// - Steps section with numbered instructions
/// - Smooth animations and transitions
/// - Production-ready layout and spacing
///
/// Navigation:
/// - Accessible from VideoPageView "Go to recipe" button
/// - Back button returns to feed
/// - Bookmark state persists across navigation
struct RecipeDetailView: View {
    
    // MARK: - Properties
    
    let recipe: Recipe
    @Binding var isSaved: Bool
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero image with gradient
                heroImageSection
                
                // Main content
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    ingredientsSection
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    stepsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                bookmarkButton
            }
        }
    }
    
    // MARK: - Hero Image Section
    
    private var heroImageSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Hero image
            AsyncImage(url: recipe.thumbnailURL) { phase in
                switch phase {
                case .empty:
                    Color.gray
                        .overlay {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                        }
                case .success(let image):
                    GeometryReader { proxy in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()
                    }
                case .failure:
                    Color.gray
                        .overlay {
                            VStack(spacing: 12) {
                                Image(systemName: "photo")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.white.opacity(0.6))
                                Text("Image unavailable")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                @unknown default:
                    Color.gray
                }
            }
            .frame(height: 320)
            .clipped()
            
            // Gradient overlay for better text readability
            LinearGradient(
                colors: [
                    .clear,
                    .clear,
                    .black.opacity(0.4),
                    .black.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Recipe title overlay
            Text(recipe.name)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
        }
        .frame(height: 320)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Author
            HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
                
                Text(recipe.authorName)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            // Metadata row
            HStack(spacing: 20) {
                // Rating
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.subheadline)
                        .foregroundStyle(.yellow)
                    
                    Text(String(format: "%.1f", recipe.rating))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("(\(formatReviewCount(recipe.reviewCount)))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Cook time
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                    
                    Text("\(recipe.cookTimeMinutes) min")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Ingredients Section
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text("Ingredients")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            // Yield
            Text(recipe.yield)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Ingredients list
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                    HStack(alignment: .top, spacing: 12) {
                        // Bullet point
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                            .padding(.top, 8)
                        
                        // Ingredient text
                        Text(ingredient)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Steps Section
    
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("Steps")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            // Steps list
            VStack(alignment: .leading, spacing: 20) {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 16) {
                        // Step number
                        Text("\(index + 1)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.blue)
                            )
                        
                        // Step text
                        Text(step)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Bookmark Button
    
    private var bookmarkButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isSaved.toggle()
            }
        } label: {
            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                .font(.title3)
                .foregroundStyle(isSaved ? .blue : .primary)
                .contentTransition(.symbolEffect(.replace))
        }
    }
    
    // MARK: - Helper Methods
    
    /// Format review count for display (e.g., 1900 -> "1.9k")
    private func formatReviewCount(_ count: Int) -> String {
        if count >= 1000 {
            let thousands = Double(count) / 1000.0
            return String(format: "%.1fk", thousands)
        }
        return "\(count)"
    }
}

// MARK: - Preview

#Preview("Classic Old Fashioned") {
    NavigationStack {
        RecipeDetailView(
            recipe: Recipe(
                id: UUID(),
                name: "Classic Old Fashioned",
                authorName: "Robert Simonson",
                cookTimeMinutes: 5,
                videoURLString: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
                thumbnailURLString: "https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b",
                ingredients: [
                    "1 Sugar Cube",
                    "2 dashes Angostura Bitters",
                    "2 oz Rye Whiskey",
                    "Orange Twist"
                ],
                steps: [
                    "Muddle sugar and bitters.",
                    "Add whiskey and ice.",
                    "Stir until chilled.",
                    "Garnish with orange twist."
                ],
                rating: 4.8,
                reviewCount: 1965,
                yield: "1 Drink"
            ),
            isSaved: .constant(false)
        )
    }
}

#Preview("Spicy Margarita - Saved") {
    NavigationStack {
        RecipeDetailView(
            recipe: Recipe(
                id: UUID(),
                name: "Spicy Margarita",
                authorName: "Sam Sifton",
                cookTimeMinutes: 3,
                videoURLString: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
                thumbnailURLString: "https://images.unsplash.com/photo-1572635148818-ef6fd45eb394",
                ingredients: [
                    "2 oz Tequila",
                    "1 oz Lime Juice",
                    "0.5 oz Agave Syrup",
                    "Jalapeño slices"
                ],
                steps: [
                    "Shake all ingredients with ice.",
                    "Strain into a rocks glass.",
                    "Garnish with Jalapeño."
                ],
                rating: 4.5,
                reviewCount: 85,
                yield: "1 Drink"
            ),
            isSaved: .constant(true)
        )
    }
}

