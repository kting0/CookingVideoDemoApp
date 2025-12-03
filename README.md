# CookingVideoDemoApp

A SwiftUI app that presents a full-screen, paginated vertical video feed of cooking recipes, inspired by TikTok and the NYT Cooking “Inspiration” tab. Users can watch remote videos with custom controls, view ingredients in a floating sheet without pausing playback, save recipes, and view full recipe details. Built for a take-home assignment emphasizing production-level quality, architectural clarity, and smooth video playback.

## Features

### Full-Screen Vertical Video Feed
- One recipe video per page (TikTok-style)
- Vertical swipe to navigate between videos (paging)
- Auto-play when page becomes active (debounced)
- Auto-pause and player deallocation when page becomes inactive
- Mute/unmute button
- Thumbnail-first loading for fast perceived performance
- Custom error UI and retry button
- Offline banner with reconnect handling

### Video Overlay UI
- Title, author, rating, cook time
- Thumbnail preview
- Persistent bookmark button
- Buttons:
  - See ingredients
  - Go to recipe →

### Floating Ingredients Sheet
- Custom ZStack overlay (not `.sheet`)
- Blurred/gradient panel
- Scrollable list of ingredients
- Video continues playing underneath
- Buttons to hide sheet or open recipe detail

### Recipe Detail Screen
- Hero image and full metadata
- Ingredients section
- Steps section
- Bookmark state synced with feed

### Persistence
- Bookmark state stored in UserDefaults
- State shared across both screens

### Architecture
- MVVM with Repository pattern
- Strong separation of concerns
- Lightweight domain layer
- `SavedRecipesStore` for persistence
- Custom AVPlayer wrapper with explicit lifecycle control

## Technical Approach

### Video Lifecycle
- Maximum of two AVPlayers alive:
  - Active page
  - Optional next page (lightweight preloading)
- Players created on page `onAppear`
- Fully deallocated on `onDisappear`
- Autoplay debounced (~0.2s) to avoid rapid-swiping stutter
- Explicit handling of app lifecycle:
  - When app enters background → pause current video
  - On return → remain paused until user explicitly taps play

### Audio Session
- Uses `AVAudioSession`:
  - Category: `.playback`
  - Mode: `.moviePlayback`
- Audio plays when user unmutes even with hardware mute switch on
- Session deactivates when no players are active

### Loading Behavior
- The recipe thumbnail appears immediately
- Video fades in when ready
- Skeleton loader shown only if thumbnail is not yet available

### Offline & Error Handling
- Offline banner + reconnect message
- Video load failure shows retry button
- Thumbnail persists as fallback

## Architecture Overview

```
CookingVideoDemoApp
├── Models
│   └── Recipe.swift
├── Repositories
│   ├── RecipeRepository.swift
│   └── LocalRecipeRepository.swift
├── Stores
│   └── SavedRecipesStore.swift
├── ViewModels
│   ├── RecipeFeedViewModel.swift
│   └── RecipeDetailViewModel.swift
├── Views
│   ├── VideoFeedView.swift
│   ├── VideoPageView.swift
│   ├── IngredientsSheetView.swift
│   └── RecipeDetailView.swift
└── Video
    ├── PlayerView.swift
    └── PlayerViewModel.swift
```

## Data Model

```swift
struct Recipe: Identifiable, Codable {
    let id: UUID
    let name: String
    let authorName: String
    let cookTimeMinutes: Int
    let videoURL: URL
    let thumbnailURL: URL
    let ingredients: [String]
    let yield: String
    let steps: [String]
    let rating: Double
    let reviewCount: Int
}
```

Source:
- Bundled `recipes.json`
- Remote URLs for video and images

## Implementation Priority (For 5-Day Assignment)

1. Full-screen video feed with paging
2. AVPlayer integration (autoplay, mute, lifecycle, thumbnail-first loading)
3. Video overlay UI
4. Bookmark persistence
5. Floating ingredients sheet
6. Recipe detail screen
7. Error/offline states
8. Optional polish: haptics, fade transitions, next-video preloading

## Requirements

- Xcode 16 or later
- iOS 17 or later
- Internet connection for remote video playback

## Running the App

1. Clone this repository
2. Open `CookingVideoDemoApp.xcodeproj` in Xcode
3. Build and run on iOS 17+ device or simulator
4. Ensure network connectivity for videos

## Testing

### Unit Tests
- JSON decoding
- Bookmark persistence store
- Feed ViewModel page logic and player lifecycle

### Optional UI Tests
- Paging interaction
- Bookmark synchronization
- Error & offline UI behavior

## Future Improvements

- Full video caching and advanced prefetching
- Search/filtering
- SwiftData persistence
- Analytics and usage instrumentation
- User-generated content
- Gesture-driven interactive sheet
