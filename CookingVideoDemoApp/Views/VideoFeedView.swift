//
//  VideoFeedView.swift
//  CookingVideoDemoApp
//
//  Created by Kuan-Ting Lin on 2025/12/3.
//

import SwiftUI

/// Main video feed screen with vertical paging
/// Uses iOS 17+ ScrollView with .scrollTargetBehavior(.paging)
struct VideoFeedView: View {
    
    // MARK: - Properties
    
    @State private var viewModel = RecipeFeedViewModel()
    @State private var savedRecipesStore = SavedRecipesStore()
    
    // MARK: - Body
    
    var body: some View {
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
    }
    
    // MARK: - Feed ScrollView
    
    private var feedScrollView: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.recipes) { recipe in
                    VideoPagePlaceholderView(
                        recipe: recipe,
                        isSaved: savedRecipesStore.isSaved(recipe.id),
                        onToggleBookmark: {
                            savedRecipesStore.toggleSaved(recipe.id)
                        }
                    )
                    .containerRelativeFrame([.horizontal, .vertical])
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
}

// MARK: - VideoPagePlaceholderView

/// Temporary placeholder for individual video pages
/// This will be replaced with the actual VideoPageView in Phase 3
struct VideoPagePlaceholderView: View {
    let recipe: Recipe
    let isSaved: Bool
    let onToggleBookmark: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background with thumbnail - fills entire frame
            AsyncImage(url: recipe.thumbnailURL) { phase in
                switch phase {
                case .empty:
                    Color.gray
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Color.gray.overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                @unknown default:
                    Color.gray
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            
            // Gradient overlay
            LinearGradient(
                colors: [
                    .clear,
                    .clear,
                    .black.opacity(0.3),
                    .black.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
        }
    }
}

// MARK: - Preview

#Preview {
    VideoFeedView()
}
