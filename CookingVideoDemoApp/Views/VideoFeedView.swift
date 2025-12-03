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
            
            // Overlay card at bottom
            overlayCard
                .containerRelativeFrame(.horizontal)
        }
    }
    
    // MARK: - Overlay Card
    
    private var overlayCard: some View {
        HStack(alignment: .top, spacing: 16) {
            // Thumbnail
            AsyncImage(url: recipe.thumbnailURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(recipe.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text(recipe.authorName)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                
                HStack(spacing: 12) {
                    Label("\(recipe.rating, specifier: "%.1f")", systemImage: "star.fill")
                    Label("\(recipe.cookTimeMinutes) min", systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.9))
            }
            
            Spacer()
            
            // Bookmark button
            Button {
                onToggleBookmark()
            } label: {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(16)
        .padding(.bottom)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        )
    }
}

// MARK: - Preview

#Preview {
    VideoFeedView()
}
