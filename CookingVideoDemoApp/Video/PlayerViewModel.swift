//
//  PlayerViewModel.swift
//  CookingVideoDemoApp
//
//  Created by Kuan-Ting Lin on 2025/12/3.
//

import AVFoundation
import SwiftUI
import Observation

/// ViewModel managing a single AVPlayer instance with explicit lifecycle control.
///
/// Key Responsibilities:
/// - Create and configure AVPlayer for a given video URL
/// - Track playback state (playing, paused, loading, error)
/// - Manage mute state and audio session
/// - Handle thumbnail-to-video transition
/// - Explicit cleanup to prevent memory leaks
///
/// Memory Management:
/// - Each instance owns exactly ONE AVPlayer
/// - Player is created lazily when needed
/// - Explicit cleanup() method must be called before deallocation
/// - No retain cycles via weak self in closures where needed
@MainActor
@Observable
final class PlayerViewModel {
    
    // MARK: - Public State
    
    /// Current playback state
    var isPlaying = false
    
    /// Mute state persisted in UserDefaults. Default is sound ON (not muted).
    var isMuted: Bool = UserDefaults.standard.object(forKey: "player_isMuted") as? Bool ?? false {
        didSet {
            // Persist to UserDefaults so the choice carries over to next videos
            UserDefaults.standard.set(isMuted, forKey: "player_isMuted")
            
            // Apply to the underlying player immediately
            player?.isMuted = isMuted
            
            // Update audio session based on new state
            updateAudioSession()
        }
    }
    
    /// Loading state for showing progress indicator
    var isLoading = true
    
    /// Error message if video fails to load
    var errorMessage: String?
    
    /// Whether video is ready to display (replaces thumbnail)
    var isVideoReady = false
    
    // MARK: - Private Properties
    
    /// The underlying AVPlayer instance (created lazily)
    private(set) var player: AVPlayer?
    
    /// Video URL to play
    private let videoURL: URL
    
    /// Player item for observing status
    private var playerItem: AVPlayerItem?
    
    /// Timer for checking if we're actually playing
    private var playbackMonitorTimer: Timer?
    
    /// Observation token for cleaning up KVO
    private var statusObservation: NSKeyValueObservation?
    
    /// Track if we've been explicitly cleaned up
    private var isCleanedUp = false
    
    // MARK: - Initialization
    
    /// Initialize with a video URL
    /// - Parameter videoURL: The remote video URL to play
    init(videoURL: URL) {
        self.videoURL = videoURL
        print("🎬 PlayerViewModel init for: \(videoURL.lastPathComponent)")
        
        // Ensure isMuted reflects persisted preference (default = sound on)
        self.isMuted = UserDefaults.standard.object(forKey: "player_isMuted") as? Bool ?? false
    }
    
    nonisolated deinit {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            print("🎬 PlayerViewModel deinit for: \(self.videoURL.lastPathComponent)")
            // Safety check - cleanup should have been called explicitly
            if !self.isCleanedUp {
                print("⚠️ Warning: PlayerViewModel deallocated without cleanup()")
                self.cleanup()
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Setup the player (call this when view appears)
    func setupPlayer() {
        guard player == nil else { return }
        
        print("🎬 Setting up player for: \(videoURL.lastPathComponent)")
        
        isLoading = true
        errorMessage = nil
        isVideoReady = false
        
        // Create player item
        let item = AVPlayerItem(url: videoURL)
        self.playerItem = item
        
        // Create player
        let newPlayer = AVPlayer(playerItem: item)
        newPlayer.isMuted = isMuted
        newPlayer.actionAtItemEnd = .none // Don't auto-repeat
        self.player = newPlayer
        
        // Observe player item status
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                self?.handlePlayerItemStatusChange(item.status)
            }
        }
        
        // Observe when video finishes
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleVideoEnd()
            }
        }
    }
    
    /// Start playing (with debounce support)
    /// - Parameter debounce: Delay before starting (for page transition)
    func play(afterDelay debounce: TimeInterval = 0) {
        guard let player = player, !isCleanedUp else { return }
        
        if debounce > 0 {
            Task {
                try? await Task.sleep(nanoseconds: UInt64(debounce * 1_000_000_000))
                guard !isCleanedUp, !isPlaying else { return }
                play(afterDelay: 0)
            }
        } else {
            // Update audio session when starting playback
            updateAudioSession()
            
            player.play()
            isPlaying = true
            startMonitoringPlayback()
            
            print("▶️ Playing: \(videoURL.lastPathComponent)")
        }
    }
    
    /// Pause playback
    func pause() {
        guard let player = player else { return }
        
        player.pause()
        isPlaying = false
        stopMonitoringPlayback()
        
        // Deactivate audio session if we're muted (save resources)
        if isMuted {
            deactivateAudioSession()
        }
        
        print("⏸️ Paused: \(videoURL.lastPathComponent)")
    }
    
    /// Toggle play/pause
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    /// Toggle mute state
    func toggleMute() {
        isMuted.toggle()
        print("🔊 Mute toggled to: \(isMuted)")
    }
    
    /// Seek to beginning (for replay)
    func seekToBeginning() {
        guard let player = player else { return }
        player.seek(to: .zero)
        print("⏮️ Seeked to beginning")
    }
    
    /// Explicit cleanup - MUST be called when page disappears
    /// This is critical for preventing memory leaks
    func cleanup() {
        print("🧹 Cleaning up player for: \(videoURL.lastPathComponent)")
        
        // Mark as cleaned up
        isCleanedUp = true
        
        // Stop playback
        pause()
        
        // Remove observers
        statusObservation?.invalidate()
        statusObservation = nil
        
        NotificationCenter.default.removeObserver(self)
        
        // Release player and item
        player?.replaceCurrentItem(with: nil)
        player = nil
        playerItem = nil
        
        // Reset state
        isPlaying = false
        isLoading = false
        isVideoReady = false
    }
    
    // MARK: - Private Methods
    
    /// Handle player item status changes
    private func handlePlayerItemStatusChange(_ status: AVPlayerItem.Status) {
        switch status {
        case .unknown:
            isLoading = true
            isVideoReady = false
            print("⏳ Player status: unknown")
            
        case .readyToPlay:
            isLoading = false
            isVideoReady = true
            errorMessage = nil
            print("✅ Player ready to play: \(videoURL.lastPathComponent)")
            
        case .failed:
            isLoading = false
            isVideoReady = false
            if let error = playerItem?.error {
                errorMessage = "Failed to load video: \(error.localizedDescription)"
                print("❌ Player failed: \(error.localizedDescription)")
            } else {
                errorMessage = "Failed to load video"
                print("❌ Player failed with unknown error")
            }
            
        @unknown default:
            break
        }
    }
    
    /// Handle video reaching the end
    private func handleVideoEnd() {
        print("🏁 Video ended: \(videoURL.lastPathComponent)")
        isPlaying = false
        stopMonitoringPlayback()
        
        // Optional: Auto-replay or show replay button
        // For now, just stop
    }
    
    /// Monitor playback to detect stalls
    private func startMonitoringPlayback() {
        stopMonitoringPlayback()
        
        playbackMonitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkPlaybackHealth()
            }
        }
    }
    
    /// Stop monitoring playback
    private func stopMonitoringPlayback() {
        playbackMonitorTimer?.invalidate()
        playbackMonitorTimer = nil
    }
    
    /// Check if playback is actually progressing
    private func checkPlaybackHealth() {
        guard let player = player, isPlaying else { return }
        
        // If rate is 0 but we think we're playing, we might be stalled
        if player.rate == 0 && player.error == nil {
            print("⚠️ Playback stalled, attempting recovery...")
            player.play()
        }
    }
    
    // MARK: - Audio Session Management
    
    /// Update audio session based on current state
    private func updateAudioSession() {
        guard !isMuted, isPlaying else { return }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Configure for video playback
            try audioSession.setCategory(.playback, mode: .moviePlayback)
            
            // Activate the session
            try audioSession.setActive(true)
            
            print("🔊 Audio session activated")
        } catch {
            print("❌ Failed to configure audio session: \(error.localizedDescription)")
        }
    }
    
    /// Deactivate audio session when not needed
    private func deactivateAudioSession() {
        do {
            // Only deactivate if we're not playing anything
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            print("🔇 Audio session deactivated")
        } catch {
            // This is not critical, just log it
            print("⚠️ Could not deactivate audio session: \(error.localizedDescription)")
        }
    }
}

