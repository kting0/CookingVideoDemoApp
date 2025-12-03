//
//  PlayerView.swift
//  CookingVideoDemoApp
//
//  Created by Kuan-Ting Lin on 2025/12/3.
//

import SwiftUI
import AVFoundation

/// SwiftUI wrapper for AVPlayerLayer that displays video content.
///
/// This view bridges UIKit's AVPlayerLayer with SwiftUI, handling:
/// - Layer creation and configuration
/// - Player attachment
/// - Gravity/aspect fill settings
/// - Lifecycle events
///
/// The view uses `@Bindable` to observe the PlayerViewModel and react to player changes.
struct PlayerView: UIViewRepresentable {
    
    // MARK: - Properties
    
    /// The view model managing the player
    @Bindable var viewModel: PlayerViewModel
    
    /// Video gravity (how video fills the frame)
    let gravity: AVLayerVideoGravity
    
    // MARK: - Initialization
    
    init(
        viewModel: PlayerViewModel,
        gravity: AVLayerVideoGravity = .resizeAspectFill
    ) {
        self.viewModel = viewModel
        self.gravity = gravity
    }
    
    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.gravity = gravity
        return view
    }
    
    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        // Update the player reference
        uiView.player = viewModel.player
    }
    
    static func dismantleUIView(_ uiView: PlayerUIView, coordinator: ()) {
        // Clean up when view is removed
        uiView.player = nil
    }
}

// MARK: - PlayerUIView

/// Custom UIView subclass that hosts an AVPlayerLayer.
///
/// This view automatically manages the player layer's frame and provides
/// a clean interface for setting the player and video gravity.
final class PlayerUIView: UIView {
    
    // MARK: - Properties
    
    /// The player layer that renders video content
    private let playerLayer = AVPlayerLayer()
    
    /// The player to display
    var player: AVPlayer? {
        get { playerLayer.player }
        set {
            playerLayer.player = newValue
            if newValue != nil {
                print("🎬 PlayerUIView: Player attached")
            } else {
                print("🎬 PlayerUIView: Player detached")
            }
        }
    }
    
    /// How the video should fill the layer
    var gravity: AVLayerVideoGravity {
        get { playerLayer.videoGravity }
        set { playerLayer.videoGravity = newValue }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPlayerLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPlayerLayer()
    }
    
    // MARK: - Setup
    
    private func setupPlayerLayer() {
        // Configure layer
        playerLayer.videoGravity = .resizeAspectFill
        
        // Black background while loading
        playerLayer.backgroundColor = UIColor.black.cgColor
        
        // Add to view hierarchy
        layer.addSublayer(playerLayer)
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Keep player layer in sync with view bounds
        playerLayer.frame = bounds
    }
    
    // MARK: - Cleanup
    
    deinit {
        print("🎬 PlayerUIView deinit")
    }
}
