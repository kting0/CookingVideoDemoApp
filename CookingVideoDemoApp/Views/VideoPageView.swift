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
/// - Bottom metadata card
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
    let onSeeIngredients: () -> Void
    let onGoToRecipe: () -> Void
    
    /// Player view model (created once per page)
    @State private var playerViewModel: PlayerViewModel?
    
    /// Track if this page is currently active
    @State private var isActive = false
    
    /// Scene phase for app lifecycle handling
    @Environment(\.scenePhase) private var scenePhase
    
    /// Debounce time for auto-play
    private let autoplayDebounce: TimeInterval = 0.2
    
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
            
            // Bottom metadata card
            VStack {
                Spacer()
                metadataCard
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
            if let viewModel = playerViewModel{
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
                    viewModel.togglePlayPause()
                }
            
            // Play icon overlay when paused
            if !viewModel.isPlaying && viewModel.isVideoReady {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(radius: 10)
                    .transition(.scale.combined(with: .opacity))
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
        }
        .containerRelativeFrame(.horizontal)
    }
    
    // MARK: - Metadata Card
    
    private var metadataCard: some View {
        VStack {
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
                    
                    // Action buttons
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
            HStack(spacing: 12) {
                Button {
                    onSeeIngredients()
                } label: {
                    Text("See ingredients")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
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
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .padding(.bottom)
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
    }
    
    private func handleDisappear() {
        print("🎬 VideoPageView disappeared: \(recipe.name)")
        isActive = false
        
        // Cleanup player immediately
        playerViewModel?.cleanup()
        playerViewModel = nil
    }
    
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        guard isActive else { return }
        
        switch newPhase {
        case .background:
            // Pause when app goes to background
            print("📱 App backgrounded - pausing video")
            playerViewModel?.pause()
            
        case .inactive:
            // Pause during transitions (optional)
            playerViewModel?.pause()
            
        case .active:
            // When returning to foreground, remain paused
            // User must explicitly tap to resume
            print("📱 App foregrounded - video remains paused")
            
        @unknown default:
            break
        }
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
            ingredients: ["Sugar", "Bitters", "Whiskey"],
            steps: ["Mix", "Stir", "Serve"],
            rating: 4.8,
            reviewCount: 196,
            yield: "1 Drink"
        ),
        isSaved: false,
        onToggleBookmark: {},
        onSeeIngredients: {},
        onGoToRecipe: {}
    )
}
