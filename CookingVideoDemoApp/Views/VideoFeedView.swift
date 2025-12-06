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
                RecipeDetailView(
                    recipe: recipe,
                    isSaved: Binding(
                        get: { savedRecipesStore.isSaved(recipe.id) },
                        set: { _ in savedRecipesStore.toggleSaved(recipe.id) }
                    )
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
        ShimmerView()
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

// MARK: - Preview

#Preview {
    VideoFeedView()
}
