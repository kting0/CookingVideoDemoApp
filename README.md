# CookingVideoDemoApp

A production-quality SwiftUI app featuring a full-screen, paginated vertical video feed of cooking recipes, inspired by TikTok and the NYT Cooking "Inspiration" tab. Built as a 5-day iOS take-home assignment emphasizing clean architecture, robust video lifecycle management, and comprehensive testing.

## Overview

Users can watch remote cooking videos with custom playback controls, toggle between metadata and ingredients views without pausing playback, save recipes persistently across app launches, and navigate to detailed recipe screens. The app demonstrates professional iOS development practices including MVVM architecture, proper memory management, and extensive unit test coverage.

## Features

### Full-Screen Vertical Video Feed
- **TikTok-style paging**: One recipe video per page with vertical swipe navigation
- **Smart auto-play**: Debounced auto-play when page becomes active (prevents rapid-swipe stutter)
- **Exclusive playback**: Only one video plays at a time across all pages
- **Intelligent lifecycle**: Auto-pause and complete player deallocation when page becomes inactive
- **Auto-loop playback**: Videos seamlessly restart from beginning when they reach the end
- **Thumbnail-first loading**: Instant thumbnail display with smooth fade to video for perceived performance
- **Mute/unmute toggle**: Audio preference persisted across app launches via UserDefaults
- **Custom error UI**: Retry button with thumbnail fallback on video load failure
- **Skeleton loader**: Elegant shimmer effect during initial data load

### Video Overlay UI
- **Top-right floating controls**:
  - Mute/unmute button with persisted preference
  - Share button (generates ingredient list as shareable text)
- **Bottom metadata card**:
  - Recipe thumbnail preview
  - Title, author, rating, and review count
  - Cook time indicator
  - Persistent bookmark button with smooth animations
  - Action buttons: "See ingredients" and "Go to recipe →"

### Inline Ingredients Display
- **Card replacement pattern**: Ingredients smoothly replace metadata card (inspired by actual NYT Cooking app)
- **No modal sheets**: Keeps UI self-contained and video visible
- **Scrollable ingredients list**: Clean typography without bullet points
- **Smooth animations**: Spring-based transitions between metadata and ingredients
- **Toggle controls**: "Hide ingredients" returns to metadata view
- **Video continues playing**: No playback interruption during view transitions

### Recipe Detail Screen
- **Full NavigationStack implementation**: Proper iOS navigation patterns
- **Swipe-to-dismiss gesture**: Natural right-edge swipe to return to feed
- **Hero image section**: Large thumbnail with gradient overlay for text readability
- **Complete metadata display**:
  - Author with person icon
  - Star rating with formatted review count (e.g., "1.9k")
  - Cook time and yield information
- **Ingredients section**: Bulleted list with yield badge
- **Steps section**: Numbered instructions with circular step indicators
- **Synchronized bookmark state**: Bookmark changes reflect immediately in feed
- **Share functionality**: Share recipe with formatted ingredient list
- **Smart playback handling**:
  - Video pauses when detail sheet opens
  - Resumes playback (if it was playing) when sheet dismisses

### Bookmark Persistence
- **UserDefaults integration**: Saved recipe IDs persist across app launches
- **Observable architecture**: Swift 5.9 `@Observable` for automatic UI updates
- **Synchronized state**: Bookmark changes in feed or detail instantly reflect everywhere
- **Set-based storage**: Efficient UUID-based lookup and storage

### App Lifecycle Handling
- **Background behavior**: Video pauses when app enters background
- **Foreground behavior**: Video remains paused on return (respects user expectation)
- **Scene phase tracking**: Comprehensive handling of active/inactive/background states
- **Audio session management**: Proper activation/deactivation based on playback state

## Technical Architecture

### Architecture Pattern: MVVM + Repository

```
CookingVideoDemoApp/
├── Models/
│   └── Recipe.swift                    # Domain model with URL safety
├── Repositories/
│   └── RecipeRepository.swift          # Protocol + LocalRecipeRepository
├── Stores/
│   └── SavedRecipesStore.swift         # UserDefaults persistence layer
├── ViewModels/
│   └── RecipeFeedViewModel.swift       # Feed loading and state management
├── Views/
│   ├── VideoFeedView.swift             # Main feed with ScrollView paging
│   ├── VideoPageView.swift             # Individual video page with controls
│   ├── RecipeDetailView.swift          # Full recipe detail screen
│   └── ShimmerView.swift               # Reusable skeleton loader
├── Video/
│   ├── PlayerView.swift                # UIViewRepresentable for AVPlayerLayer
│   └── PlayerViewModel.swift           # AVPlayer lifecycle management
├── Resources/
│   └── recipes.json                    # Bundled recipe data (14 recipes)
└── ContentView.swift                   # App entry point
```

### Key Architectural Decisions

#### 1. **No RecipeDetailViewModel**
RecipeDetailView is a pure presentation layer that formats data from the Recipe model. All state management (bookmarks) is centralized in SavedRecipesStore, eliminating the need for a separate ViewModel and reducing architectural complexity.

#### 2. **Inline Card Pattern vs. Modal Sheets**
Following the actual NYT Cooking app's design, ingredients replace the metadata card within the same container rather than using `.sheet()` modifiers. This approach:
- Maintains video visibility and playback
- Simplifies state management
- Provides more control over animations
- Eliminates sheet-related edge cases

#### 3. **Consolidated Repository File**
RecipeRepository.swift contains both protocol and implementation in one file. For a demo with 2 core recipes, this improves readability while maintaining proper separation through protocol abstraction. Production apps would separate these into distinct files.

#### 4. **Exclusive Playback via NotificationCenter**
Uses `Notification.Name.playerWillStartExclusivePlayback` to enforce single-player constraint rather than shared state. This maintains loose coupling between VideoPageView instances while preventing resource-intensive multiple simultaneous players.

#### 5. **String-Based URLs in Model**
Recipe stores `videoURLString` and `thumbnailURLString` with computed `var videoURL: URL?` properties. This approach:
- Enables JSON decoding without custom `Codable` implementations
- Provides URL validation at access time
- Prevents crashes from malformed URLs in data source

## Data Model

```swift
struct Recipe: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let authorName: String
    let cookTimeMinutes: Int
    let videoURLString: String          // JSON-friendly string
    let thumbnailURLString: String      // JSON-friendly string
    let ingredients: [String]
    let steps: [String]
    let rating: Double
    let reviewCount: Int
    let yield: String
    
    // Computed properties for safe URL access
    var videoURL: URL? { URL(string: videoURLString) }
    var thumbnailURL: URL? { URL(string: thumbnailURLString) }
}
```

**Data Source**: Bundled `recipes.json` with 14 diverse recipes (cocktails, pasta, salads, desserts, international cuisine)

## Video Playback Architecture

### Player Lifecycle Management

```
Page Appears → PlayerViewModel Created → AVPlayer Initialized → Auto-play (debounced)
                                                ↓
                                        Video Ready → Fade In
                                                ↓
                                          User Scrolls
                                                ↓
Page Disappears → Pause → Cleanup → PlayerViewModel Deallocated → AVPlayer Released
```

**Key Implementation Details:**

- **Maximum 2 AVPlayers**: Active page + optional next page (preloading not yet implemented)
- **Debounced auto-play**: ~0.2s delay prevents rapid-start stutter during quick swipes
- **Explicit cleanup**: `PlayerViewModel.cleanup()` called on page `onDisappear` to prevent leaks
- **Exclusive playback**: `NotificationCenter` broadcasts ensure only one video plays at a time
- **Auto-loop**: Videos restart seamlessly at end via `AVPlayerItemDidPlayToEndTime` observer
- **Thumbnail-first**: AsyncImage displays immediately while video buffers in background

### Audio Session Configuration

```swift
// Category: .playback — plays even with hardware mute switch on
// Mode: .moviePlayback — optimized for video content
AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
```

**Audio Behavior:**
- Unmuted videos play audio even with device mute switch engaged
- Mute preference persisted in UserDefaults: `player_isMuted` key
- Session activates when video plays while unmuted
- Session deactivates when video paused or muted (resource optimization)

### App Lifecycle Handling

```
App Active → Video Playing
     ↓
Background → Auto-Pause (preserve battery) + Remember state
     ↓
Foreground → Remain Paused (user must tap to resume)
```

This respects iOS user expectations and prevents unexpected audio playback.

## Loading & Error States

### Loading States
1. **Initial load**: Full-screen shimmer skeleton
2. **Video buffering**: Thumbnail visible + small spinner overlay
3. **Video ready**: Smooth fade transition from thumbnail to video

### Error Handling
- **Video load failure**: Error overlay with retry button, thumbnail remains as fallback
- **Network offline**: Banner message with connectivity guidance
- **Missing JSON**: Graceful error message in feed view
- **Malformed URLs**: Safe unwrapping via computed properties prevents crashes

## Testing Strategy

### Unit Test Coverage (40+ Tests)

#### **RecipeRepositoryTests.swift**
- ✅ JSON decoding and parsing
- ✅ Recipe count validation
- ✅ Data integrity (non-empty names, positive cook times, valid ratings)
- ✅ URL parsing correctness
- ✅ UUID uniqueness
- ✅ Ingredients and steps validation
- ✅ Performance benchmarks

#### **SavedRecipesStoreTests.swift**
- ✅ Initial state verification
- ✅ Save/unsave operations
- ✅ Toggle functionality
- ✅ Idempotency (duplicate saves/unsaves)
- ✅ Lookup operations (`isSaved(_:)`)
- ✅ UserDefaults persistence (isolated test suite)
- ✅ Multiple recipe handling

#### **RecipeFeedViewModelTests.swift**
- ✅ Initial empty state
- ✅ Loading state transitions
- ✅ Successful recipe population
- ✅ Error handling and messaging
- ✅ Multiple load attempts (idempotency)
- ✅ Mock repository integration
- ✅ Real repository integration test

### Test Isolation
- **@MainActor annotations**: All tests respect SwiftUI's main actor requirements
- **Isolated UserDefaults**: Tests use separate suite names to prevent contamination
- **Mock implementations**: `MockRecipeRepository` with configurable behavior
- **Async/await support**: Proper Task-based async testing

### Running Tests
```bash
# Run all tests
⌘ + U in Xcode

# Run specific test class
⌘ + U with test file selected

# View test coverage
⌘ + 9 → Coverage tab
```

## Requirements

- **Xcode**: 16.0 or later
- **iOS**: 17.0 or later
- **Swift**: 5.9+ (Swift 6 concurrency ready)
- **Internet**: Required for remote video playback

## Running the App

1. **Clone repository**
   ```bash
   git clone <repository-url>
   cd CookingVideoDemoApp
   ```

2. **Open in Xcode**
   ```bash
   open CookingVideoDemoApp.xcodeproj
   ```

3. **Select target**
   - Choose iPhone simulator or connected device
   - iOS 17.0+ required

4. **Build and run**
   ```bash
   ⌘ + R
   ```

5. **Ensure connectivity**
   - Videos are served from remote URLs
   - Internet connection required for playback

## Known Limitations

1. **Second recipe thumbnail issue**: The second recipe in the feed consistently fails to display its thumbnail in the video overlay, regardless of recipe.json order. First, third, fourth, and subsequent recipes display thumbnails correctly. Root cause under investigation - likely related to AsyncImage caching or ScrollView layout timing for the second LazyVStack element.
2. **No video preloading**: Next video loads only when page appears (can cause brief loading state)
3. **No offline support**: Videos require active internet connection
4. **No seek controls**: Users cannot scrub through video timeline
5. **Fixed video quality**: No manual quality selection
6. **Limited to 14 recipes**: Demo dataset, not production scale
7. **No user accounts**: All data stored locally on device

## License

This is a take-home assignment demonstration project. All rights reserved.

## Contact

For questions about this implementation, please contact the assignment reviewer.
