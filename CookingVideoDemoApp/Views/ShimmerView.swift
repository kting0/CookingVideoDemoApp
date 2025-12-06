//
//  ShimmerView.swift
//  CookingVideoDemoApp
//
//  Created by Kuan-Ting Lin on 2025/12/6.
//

import SwiftUI

/// A reusable shimmer/skeleton loading view with animated gradient effect.
///
/// Features:
/// - Smooth animated gradient that moves across the view
/// - Customizable base and highlight colors
/// - Adapts to any frame size
/// - Minimal performance impact
///
/// Usage:
/// ```swift
/// ShimmerView()
///     .frame(width: 200, height: 100)
///     .clipShape(RoundedRectangle(cornerRadius: 12))
/// ```
struct ShimmerView: View {
    
    // MARK: - Properties
    
    /// Animation state for the shimmer gradient
    @State private var shimmerOffset: CGFloat = -1.0
    
    /// Base color for the skeleton
    private let baseColor: Color
    
    /// Highlight color for the shimmer effect
    private let highlightColor: Color
    
    /// Animation duration for one complete shimmer cycle
    private let duration: Double
    
    // MARK: - Initialization
    
    /// Initialize shimmer view with custom colors
    /// - Parameters:
    ///   - baseColor: Base skeleton color (default: gray)
    ///   - highlightColor: Shimmer highlight color (default: lighter gray)
    ///   - duration: Animation cycle duration in seconds (default: 1.5)
    init(
        baseColor: Color = Color.gray.opacity(0.3),
        highlightColor: Color = Color.gray.opacity(0.1),
        duration: Double = 1.5
    ) {
        self.baseColor = baseColor
        self.highlightColor = highlightColor
        self.duration = duration
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base color layer
                baseColor
                
                // Shimmer gradient layer
                LinearGradient(
                    colors: [
                        baseColor,
                        highlightColor,
                        baseColor
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: shimmerOffset * geometry.size.width * 2)
                .animation(
                    .linear(duration: duration)
                        .repeatForever(autoreverses: false),
                    value: shimmerOffset
                )
            }
        }
        .onAppear {
            // Start animation when view appears
            shimmerOffset = 1.0
        }
    }
}

// MARK: - Preview

#Preview("Shimmer Rectangle") {
    VStack(spacing: 20) {
        ShimmerView()
            .frame(width: 300, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        
        ShimmerView()
            .frame(width: 200, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        
        ShimmerView()
            .frame(width: 150, height: 30)
            .clipShape(Capsule())
    }
    .padding()
    .background(Color.black)
}

#Preview("Shimmer Full Screen") {
    ShimmerView()
        .ignoresSafeArea()
}
