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
                if let recipe = showingDetailForRecipe {
                    RecipeDetailSheet(
                        recipe: recipe,
                        isSaved: Binding(
                            get: { savedRecipesStore.isSaved(recipe.id) },
                            set: { _ in savedRecipesStore.toggleSaved(recipe.id) }
                        ),
                        onDismiss: dismissRecipeSheet
                    )
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
                }
            }
            .ignoresSafeArea()
            .task {
                await viewModel.loadRecipes()
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.9), value: showingDetailForRecipe)
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
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                showingDetailForRecipe = recipe
                            }
                        },
                        presentedRecipe: $showingDetailForRecipe
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
    /// Dismiss the recipe sheet with animation and reset drag state
    private func dismissRecipeSheet() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            showingDetailForRecipe = nil
        }
    }
}

// MARK: - Recipe Detail Sheet

private struct RecipeDetailSheet: View {
    
    let recipe: Recipe
    @Binding var isSaved: Bool
    let onDismiss: () -> Void
    
    @GestureState private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .leading) {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            NavigationStack {
                RecipeDetailView(recipe: recipe, isSaved: $isSaved)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: onDismiss) {
                                Label("Back", systemImage: "chevron.left")
                                    .labelStyle(.titleAndIcon)
                            }
                        }
                    }
            }
            .background(Color(.systemBackground))
            .offset(x: max(0, dragOffset))
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = max(0, value.translation.width)
                    }
                    .onEnded { value in
                        if value.translation.width > 120 {
                            onDismiss()
                        }
                    }
            )
            .transition(.move(edge: .trailing))
            .shadow(color: .black.opacity(0.25), radius: 12, x: -4, y: 0)
        }
    }
}

// MARK: - Preview

#Preview {
    VideoFeedView()
}
