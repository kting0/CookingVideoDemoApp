//
//  VideoFeedView.swift
//  CookingVideoDemoApp
//
//  Created by Kuan-Ting Lin on 2025/12/3.
//

import SwiftUI

/// Main video feed screen with vertical paging and AVPlayer lifecycle management.
///
/// Features:
/// - Vertical paging with iOS 17+ ScrollView
/// - Tracks current page for player lifecycle
/// - Enforces maximum of 2 AVPlayers in memory (handled by VideoPageView lifecycle)
/// - Auto-play active page, cleanup inactive pages
/// - Navigation to recipe detail
struct VideoFeedView: View {
    
    // MARK: - Properties
    
    @State private var viewModel = RecipeFeedViewModel()
    @State private var savedRecipesStore = SavedRecipesStore()
    
    /// Current visible page index (for player lifecycle management)
    @State private var currentPageIndex: Int = 0
    
    /// Track if recipe detail is shown
    @State private var showingDetailForRecipe: Recipe?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    loadingView
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(message: errorMessage)
                } else if viewModel.recipes.isEmpty {
                    emptyStateView
                } else {
                    feedScrollView
                }
            }
            .ignoresSafeArea()
            .task {
                await viewModel.loadRecipes()
            }
            // Recipe detail navigation
            .navigationDestination(item: $showingDetailForRecipe) { recipe in
                RecipeDetailPlaceholderView(
                    recipe: recipe,
                    isSaved: savedRecipesStore.isSaved(recipe.id),
                    onToggleBookmark: {
                        savedRecipesStore.toggleSaved(recipe.id)
                    }
                )
            }
        }
    }
    
    // MARK: - Feed ScrollView
    
    private var feedScrollView: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.recipes.enumerated()), id: \.element.id) { index, recipe in
                    VideoPageView(
                        recipe: recipe,
                        isSaved: savedRecipesStore.isSaved(recipe.id),
                        onToggleBookmark: {
                            savedRecipesStore.toggleSaved(recipe.id)
                        },
                        onGoToRecipe: {
                            showingDetailForRecipe = recipe
                        }
                    )
                    .containerRelativeFrame([.horizontal, .vertical])
                    .onAppear {
                        handlePageAppear(index: index)
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading Recipes...")
                .font(.headline)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)
            
            Text("Error Loading Recipes")
                .font(.title2)
                .bold()
            
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                Task {
                    await viewModel.loadRecipes()
                }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "film.stack")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            
            Text("No Recipes Available")
                .font(.title2)
                .bold()
            
            Text("Check back later for cooking videos")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    // MARK: - Helper Methods
    
    /// Handle page appearance for tracking
    private func handlePageAppear(index: Int) {
        currentPageIndex = index
        print("📄 Current page: \(index)")
    }
}

// MARK: - RecipeDetailPlaceholderView

/// Placeholder for Recipe Detail screen (Phase 4)
/// Basic implementation until full detail screen is built
struct RecipeDetailPlaceholderView: View {
    let recipe: Recipe
    let isSaved: Bool
    let onToggleBookmark: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero image
                AsyncImage(url: recipe.thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(height: 300)
                .clipped()
                
                VStack(alignment: .leading, spacing: 16) {
                    // Title and bookmark
                    HStack {
                        Text(recipe.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button {
                            onToggleBookmark()
                        } label: {
                            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                    }
                    
                    // Metadata
                    HStack(spacing: 20) {
                        Label(recipe.authorName, systemImage: "person.fill")
                        Label("\(recipe.rating, specifier: "%.1f")", systemImage: "star.fill")
                        Label("\(recipe.cookTimeMinutes) min", systemImage: "clock")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    Divider()
                    
                    // Ingredients section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ingredients")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(recipe.yield)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        ForEach(recipe.ingredients, id: \.self) { ingredient in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 6, height: 6)
                                
                                Text(ingredient)
                                    .font(.body)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Steps section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Steps")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                
                                Text(step)
                                    .font(.body)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    VideoFeedView()
}
