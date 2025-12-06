//
//  VideoPageView.swift
//  CookingVideoDemoApp
//
//  Created by Kuan-Ting Lin on 2025/12/3.
//

import SwiftUI
import AVFoundation

/// Full-screen video page with playback controls and metadata overlay.
///
/// Features:
/// - Thumbnail-first loading (shows thumbnail, then fades to video)
/// - Auto-play when page becomes active (debounced)
/// - Auto-pause and cleanup when page becomes inactive
/// - Tap to play/pause
/// - Mute/unmute button
/// - Play icon overlay when paused
/// - Bottom metadata card with ingredients toggle
/// - Error handling with retry
///
/// Lifecycle:
/// - onAppear: Setup player, start auto-play (debounced)
/// - onDisappear: Pause and cleanup player
/// - App background: Pause playback
/// - App foreground: Remain paused until user interaction
struct VideoPageView: View {
    
    // MARK: - Properties
    
    let recipe: Recipe
    let isSaved: Bool
    let onToggleBookmark: () -> Void
    let onGoToRecipe: () -> Void
    @Binding var presentedRecipe: Recipe?
    
    /// Player view model (created once per page)
    @State private var playerViewModel: PlayerViewModel?
    
    /// Track if this page is currently active
    @State private var isActive = false

    /// Track whether the player was playing before going to background
    @State private var wasPlayingBeforeBackground = false
    
    /// Track if ingredients are showing (replaces metadata card)
    @State private var showingIngredients = false
    
    /// Transient HUD for play/pause feedback
    @State private var showPlaybackHUD = false
    @State private var playbackHUDIcon: String = "pause.fill"
    @State private var hudHideWorkItem: DispatchWorkItem?
    private let playbackHUDDuration: TimeInterval = 0.9
    
    /// Scene phase for app lifecycle handling
    @Environment(\.scenePhase) private var scenePhase
    
    /// Debounce time for auto-play
    private let autoplayDebounce: TimeInterval = 0.2
    
    /// Track if recipe sheet is currently visible for this page
    @State private var isRecipeSheetVisible = false
    
    /// Track playback state before opening recipe sheet
    @State private var wasPlayingBeforeRecipeSheet = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            // Video or thumbnail layer
            videoLayer
                .ignoresSafeArea()
            
            // Gradient overlay for better text readability
            gradientOverlay
                .ignoresSafeArea()
            
            // Controls overlay
            if let viewModel = playerViewModel {
                controlsOverlay(viewModel: viewModel)
            }
            
            // Bottom card (metadata or ingredients)
            VStack {
                Spacer()
                
                if showingIngredients {
                    ingredientsCard
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                } else {
                    metadataCard
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                }
            }
        }
        .onAppear {
            handleAppear()
        }
        .onDisappear {
            handleDisappear()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
        .onChange(of: presentedRecipe?.id) { _, _ in
            handleRecipeSheetChange()
        }
    }
    
    // MARK: - Video Layer
    
    @ViewBuilder
    private var videoLayer: some View {
        ZStack {
            // Thumbnail (always shown first, fades out when video ready)
            if let thumbnailURL = recipe.thumbnailURL {
                AsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                    case .empty:
                        Color.gray
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                .opacity(playerViewModel?.isVideoReady == true ? 0 : 1)
                .animation(.easeIn(duration: 0.3), value: playerViewModel?.isVideoReady)
            }
            
            // Video player
            if let viewModel = playerViewModel {
                PlayerView(viewModel: viewModel)
                    .opacity(viewModel.isVideoReady ? 1 : 0)
                    .animation(.easeIn(duration: 0.3), value: viewModel.isVideoReady)
            }
            
            // Loading indicator
            if playerViewModel?.isLoading == true && playerViewModel?.errorMessage == nil {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
            
            // Error state
            if let errorMessage = playerViewModel?.errorMessage {
                errorOverlay(message: errorMessage)
            }
        }
    }
    
    // MARK: - Gradient Overlay
    
    private var gradientOverlay: some View {
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
        .allowsHitTesting(false)
    }
    
    // MARK: - Controls Overlay
    
    @ViewBuilder
    private func controlsOverlay(viewModel: PlayerViewModel) -> some View {
        ZStack {
            // Tap to play/pause
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    // Toggle playback
                    viewModel.togglePlayPause()

                    // Update HUD icon to reflect the resulting state
                    playbackHUDIcon = viewModel.isPlaying ? "play.fill" : "pause.fill"

                    // Show HUD with animation
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                        showPlaybackHUD = true
                    }

                    // Debounced hide
                    hudHideWorkItem?.cancel()
                    let work = DispatchWorkItem {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showPlaybackHUD = false
                        }
                    }
                    hudHideWorkItem = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + playbackHUDDuration, execute: work)
                }
            
            // Top-right controls
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        // Mute/unmute button
                        Button {
                            viewModel.toggleMute()
                        } label: {
                            Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        
                        // Share button (stub)
                        Button {
                            // TODO: Implement share
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 60)
                }
                
                Spacer()
            }
            
            // Transient playback HUD
            if showPlaybackHUD && viewModel.isVideoReady {
                Image(systemName: playbackHUDIcon)
                    .font(.system(size: 80, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(radius: 10)
                    .padding(24)
                    .background(
                        Circle().fill(Color.black.opacity(0.35))
                    )
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .containerRelativeFrame(.horizontal)
    }
    
    // MARK: - Metadata Card
    
    private var metadataCard: some View {
        VStack(spacing: 0) {
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
                        Text("(\(formatReviewCount(recipe.reviewCount)))")
                        Text("•")
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
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Action buttons
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        showingIngredients = true
                    }
                } label: {
                    Text("See ingredients")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
                
                Button {
                    onGoToRecipe()
                } label: {
                    HStack(spacing: 4) {
                        Text("Go to recipe")
                        Image(systemName: "arrow.right")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        )
        .containerRelativeFrame(.horizontal)
    }
    
    // MARK: - Ingredients Card
    
    private var ingredientsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text("Ingredients")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            // Ingredients list (simple, no bullets like NYT)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(recipe.ingredients, id: \.self) { ingredient in
                    Text(ingredient)
                        .font(.body)
                        .foregroundStyle(.white)
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        showingIngredients = false
                    }
                } label: {
                    Text("Hide ingredients")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
                
                Button {
                    onGoToRecipe()
                } label: {
                    HStack(spacing: 4) {
                        Text("Go to recipe")
                        Image(systemName: "arrow.right")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .padding(.bottom, 8)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        )
        .containerRelativeFrame(.horizontal)
    }
    
    // MARK: - Error Overlay
    
    private func errorOverlay(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.red)
            
            Text("Video Error")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text(message)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                retryVideoLoad()
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.7))
    }
    
    // MARK: - Helper Methods
    
    /// Format review count (e.g., 1900 -> "1.9k")
    private func formatReviewCount(_ count: Int) -> String {
        if count >= 1000 {
            let thousands = Double(count) / 1000.0
            return String(format: "%.1fk", thousands)
        }
        return "\(count)"
    }
    
    // MARK: - Lifecycle Methods
    
    private func handleAppear() {
        print("🎬 VideoPageView appeared: \(recipe.name)")
        isActive = true
        
        // Create player view model if needed
        if playerViewModel == nil, let videoURL = recipe.videoURL {
            playerViewModel = PlayerViewModel(videoURL: videoURL)
        }
        
        // Setup player
        playerViewModel?.setupPlayer()
        
        // Auto-play with debounce
        playerViewModel?.play(afterDelay: autoplayDebounce)
        // Sync sheet state when appearing
        handleRecipeSheetChange()
    }
    
    private func handleDisappear() {
        print("🎬 VideoPageView disappeared: \(recipe.name)")
        isActive = false
        
        // Reset sheet tracking
        isRecipeSheetVisible = false
        wasPlayingBeforeRecipeSheet = false

        // Reset ingredients view
        showingIngredients = false
        
        // Cleanup player immediately
        playerViewModel?.cleanup()
        playerViewModel = nil
    }
    
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        guard isActive else { return }
        
        switch newPhase {
        case .background:
            // Pause when app goes to background, but remember prior playing state
            wasPlayingBeforeBackground = playerViewModel?.isPlaying ?? false
            print("📱 App backgrounded - pausing video (wasPlaying=\(wasPlayingBeforeBackground))")
            playerViewModel?.pause()
            
        case .inactive:
            // Pause during transitions (optional)
            if oldPhase == .active { wasPlayingBeforeBackground = playerViewModel?.isPlaying ?? wasPlayingBeforeBackground }
            playerViewModel?.pause()
            
        case .active:
            // On returning to foreground, resume only if it was playing before background
            if wasPlayingBeforeBackground {
                print("📱 App foregrounded - resuming video")
                playerViewModel?.play(afterDelay: autoplayDebounce)
            } else {
                print("📱 App foregrounded - staying paused")
                playerViewModel?.pause()
            }
            
        @unknown default:
            break
        }
    }
    
    private func handleRecipeSheetChange() {
        guard isActive else { return }
        
        let shouldShowSheet = presentedRecipe?.id == recipe.id
        
        if shouldShowSheet && !isRecipeSheetVisible {
            wasPlayingBeforeRecipeSheet = playerViewModel?.isPlaying ?? false
            playerViewModel?.pause()
        } else if !shouldShowSheet && isRecipeSheetVisible {
            if wasPlayingBeforeRecipeSheet {
                playerViewModel?.play(afterDelay: autoplayDebounce)
            }
            wasPlayingBeforeRecipeSheet = false
        }
        
        isRecipeSheetVisible = shouldShowSheet
    }
    
    private func retryVideoLoad() {
        print("🔄 Retrying video load for: \(recipe.name)")
        
        // Cleanup old player
        playerViewModel?.cleanup()
        
        // Create new player
        if let videoURL = recipe.videoURL {
            playerViewModel = PlayerViewModel(videoURL: videoURL)
            playerViewModel?.setupPlayer()
            playerViewModel?.play(afterDelay: autoplayDebounce)
        }
    }
}

// MARK: - Preview

#Preview {
    VideoPageView(
        recipe: Recipe(
            id: UUID(),
            name: "Classic Old Fashioned",
            authorName: "Robert Simonson",
            cookTimeMinutes: 5,
            videoURLString: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            thumbnailURLString: "https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b",
            ingredients: ["1 Sugar Cube", "2 dashes Angostura Bitters", "2 oz Rye Whiskey", "Orange Twist"],
            steps: ["Mix", "Stir", "Serve"],
            rating: 4.8,
            reviewCount: 1965,
            yield: "1 Drink"
        ),
        isSaved: false,
        onToggleBookmark: {},
        onGoToRecipe: {},
        presentedRecipe: .constant(nil)
    )
}
