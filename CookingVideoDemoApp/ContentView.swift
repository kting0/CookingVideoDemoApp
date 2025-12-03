//
//  ContentView.swift
//  CookingVideoDemoApp
//
//  Created by Kuan-Ting Lin on 2025/12/3.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = RecipeFeedViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Architecture Test")
                .font(.largeTitle)
                .bold()
            
            if viewModel.isLoading {
                ProgressView("Loading JSON...")
                    .scaleEffect(1.5)
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            } else {
                List(viewModel.recipes) { recipe in
                    HStack {
                        // Simple async image test
                        AsyncImage(url: recipe.thumbnailURL) { image in
                            image.resizable()
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 50, height: 50)
                        .cornerRadius(8)
                        
                        VStack(alignment: .leading) {
                            Text(recipe.name).font(.headline)
                            Text(recipe.authorName).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .task {
            // Triggers the data load when the app opens
            await viewModel.loadRecipes()
        }
    }
}
