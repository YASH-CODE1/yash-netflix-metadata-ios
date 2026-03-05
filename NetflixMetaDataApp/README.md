# Netflix Metadata Retriever - iOS App

> A SwiftUI application that reverse-engineers Netflix's non-public API to retrieve video metadata without using official API keys or public APIs.

[![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0-blue.svg)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/license-Educational-green.svg)](LICENSE)

## 🎯 Project Overview

This iOS application demonstrates advanced API reverse engineering techniques by intercepting and replicating Netflix's internal Shakti API requests. The app retrieves comprehensive video metadata including titles, descriptions, cast, genres, and poster images—all without using any official Netflix API or API keys.

**Built for**: iOS Development Challenge - Streaming Service Metadata Retrieval  
**Tech Stack**: Swift, SwiftUI, WKWebView, URLSession, Async/Await  
**Approach**: Network traffic analysis, API reverse engineering, cookie-based authentication

## ✨ Features

### Core Features
- ✅ **Video ID Input** - Retrieve metadata by Netflix video ID
- ✅ **Title Search** - Search functionality with guidance
- ✅ **Comprehensive Metadata Display**:
  - Title, description, and synopsis
  - Release year, runtime, maturity rating
  - Season and episode numbers (for series)
  - Genres and cast information
  - High-resolution poster images
  - Professional UI with native iOS design

### Bonus Features
- ✅ **WebView Browser** - Browse Netflix directly in-app
- ✅ **Dynamic Extraction** - Auto-extract metadata from selected videos
- ✅ **Manifest URLs** - Display streaming manifest paths
- ✅ **License URLs** - Show DRM licensing endpoints
- ✅ **FairPlay Certificates** - Display certificate URLs
- ✅ **Automatic Authentication** - Extract cookies and build IDs via WebView

## 🔬 Reverse Engineering Approach

### Discovery Process

1. **Network Traffic Analysis**
   - Used Chrome DevTools to intercept Netflix API calls
   - Identified the internal "Shakti" API endpoint
   - Analyzed request structure, headers, and authentication

2. **API Structure**
   ```
   POST https://www.netflix.com/nq/website/memberapi/release/pathEvaluator
   
   Query Parameters:
   - webp=true
   - drmSystem=widevine
   - isVolatileBillboardsEnabled=true
   - isTop10Supported=true
   - hasVideoMerchInBob=true
   - hasVideoMerchInJaw=true
   - falcor_server=0.1.0
   - withSize=true
   - materialize=true
   - original_path=%2Fshakti%2Fmre%2FpathEvaluator
   
   Headers:
   - Content-Type: application/x-www-form-urlencoded
   - Cookie: NetflixId=...; SecureNetflixId=...
   
   Body:
   - path=["videos",VIDEO_ID,["title","synopsis",...]]
   ```

3. **Authentication Mechanism**
   - Cookie-based authentication (no API key needed)
   - Extracts `NetflixId` and `SecureNetflixId` from browser session
   - Uses WKWebView cookie store for automatic extraction

4. **Path-Based Queries** (Falcor Protocol)
   - Netflix uses Falcor for efficient data fetching
   - Path queries specify exactly which fields to retrieve
   - Example: `["videos",80057281,["title","synopsis","releaseYear"]]`

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│                   UI Layer                      │
│              (SwiftUI Views)                    │
│  ┌──────────────┐     ┌──────────────────────┐ │
│  │ ContentView  │     │ NetflixWebView       │ │
│  │              │     │ (Bonus Feature)      │ │
│  └──────┬───────┘     └──────────┬───────────┘ │
└─────────┼──────────────────────────┼─────────────┘
          │                          │
          ▼                          ▼
┌─────────────────────────────────────────────────┐
│              ViewModel Layer                    │
│          (MetadataViewModel)                    │
│  • State management                             │
│  • Business logic                               │
│  • API coordination                             │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│             Network Layer                       │
│         (NetflixAPIService)                     │
│  • Request construction                         │
│  • Cookie authentication                        │
│  • Response parsing                             │
│  • Error handling                               │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│          Netflix Shakti API                     │
│  (Reverse-Engineered Endpoint)                  │
└─────────────────────────────────────────────────┘
```

## 🚀 Getting Started

### Prerequisites

- macOS 13.0 or later
- Xcode 15.0 or later
- iOS 17.0+ (deployment target)
- Active Netflix subscription

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/netflix-metadata-app.git
   cd netflix-metadata-app
   ```

2. **Open in Xcode**
   ```bash
   open NetflixMetadataApp.xcodeproj
   ```

3. **Configure Authentication**

   **Option A: Automatic (Recommended)**
   - Run the app
   - Tap "Browse Netflix (Bonus Feature)"
   - Log into Netflix in the WebView
   - Cookies extracted automatically!

   **Option B: Manual**
   - Open Chrome DevTools (F12)
   - Enable mobile emulation (Ctrl+Shift+M)
   - Login to netflix.com
   - Copy cookies from Application → Cookies
   - Paste in `NetflixConfig.swift`

4. **Build and Run**
   ```bash
   # In Xcode
   ⌘B  # Build
   ⌘R  # Run
   ```

### Quick Test

1. Enter video ID: `80057281` (Stranger Things)
2. Tap the arrow button
3. View comprehensive metadata!

**Example Video IDs:**
- `80057281` - Stranger Things
- `80189685` - The Crown
- `80117401` - The Witcher
- `70143836` - Breaking Bad
- `70251912` - Narcos

## 📱 Usage

### Method 1: Direct Video ID Entry

```
1. Launch app
2. Enter a Netflix video ID in the input field
3. Tap the arrow button (→)
4. View metadata instantly
```

### Method 2: WebView Browser (Bonus)

```
1. Tap "Browse Netflix (Bonus Feature)"
2. Log into Netflix
3. Browse and click any video
4. Tap the download arrow (↓) in URL bar
5. Metadata extracted automatically!
```

## 🎥 Demo Video

The project includes a comprehensive demo video showing:
- Manual video ID entry and metadata retrieval
- WebView browsing and automatic extraction
- Bonus features (manifest URLs, DRM info)
- Professional UI and error handling

*[Demo video included in submission]*

## 📋 Requirements Met

### Core Requirements ✅
- [x] Accepts video ID or title as input
- [x] Connects to non-public API (no API keys)
- [x] Fetches comprehensive metadata
- [x] Displays all relevant information
- [x] Uses reverse-engineered endpoints
- [x] Cookie-based authentication

### Bonus Requirements ✅
- [x] WebView integration for browsing
- [x] Dynamic metadata extraction
- [x] Manifest URL display
- [x] License URL display
- [x] FairPlay certificate display
- [x] Automatic cookie extraction

## 🛠️ Technical Details

### Key Technologies

- **SwiftUI** - Modern declarative UI framework
- **Async/Await** - Modern Swift concurrency
- **WKWebView** - Browser integration and cookie extraction
- **URLSession** - Network requests
- **Codable** - JSON parsing
- **Combine** - Reactive state management

### Project Structure

```
NetflixMetadataApp/
├── NetflixMetadataAppApp.swift      # App entry point
├── ContentView.swift                 # Main UI
├── MetadataViewModel.swift           # State management
├── VideoMetadata.swift               # Data models
├── NetflixAPIService.swift           # API layer (reverse-engineered)
├── NetflixWebView.swift              # Browser integration
├── NetflixConfig.swift               # Configuration
└── Info.plist                        # App configuration
```

### API Endpoint Details

**Base URL:** `https://www.netflix.com/nq/website/memberapi/release`

**Endpoint:** `/pathEvaluator`

**Method:** `POST`

**Authentication:** Cookie-based (NetflixId, SecureNetflixId)

**Request Format:** Falcor path queries in POST body

**Response Format:** JSON with nested video data

### Data Models

```swift
struct VideoMetadata {
    let videoId: Int
    let title: String
    let description: String?
    let year: Int?
    let runtime: Int?
    let maturityRating: String?
    let genres: [String]
    let cast: [String]
    let seasonNumber: Int?
    let episodeNumber: Int?
    // ... and more
}
```

## 🐛 Troubleshooting

### Common Issues

**502 Bad Gateway Error**
- Ensure cookies are properly configured
- Check that cookies haven't expired
- Verify all query parameters are included

**Authentication Required**
- Use WebView to login and extract fresh cookies
- Or manually update cookies in `NetflixConfig.swift`

**WebView Shows "Use App" Message**
- Mobile plan restriction
- Use desktop user agent (already configured)
- Or use manual cookie extraction method

**Build Errors**
- Ensure all files are added to target
- Clean build folder (Shift+⌘+K)
- Check Xcode version (15.0+)

## 🎓 Learning Outcomes

This project demonstrates:

1. **API Reverse Engineering** - Network analysis and endpoint discovery
2. **Authentication Systems** - Cookie-based auth implementation
3. **iOS Development** - SwiftUI, async/await, modern patterns
4. **Network Programming** - URLSession, HTTP protocols
5. **Data Modeling** - JSON parsing, Codable
6. **UI/UX Design** - Native iOS patterns, responsive design
7. **Problem Solving** - Debugging complex API interactions

## 👤 Author - Yash Sharma

Created for iOS Development Challenge

**Skills Demonstrated:**
- Reverse Engineering
- iOS/Swift Development
- Network Programming
- API Integration
- UI/UX Design

---

**⚡ Quick Start:** Clone → Open in Xcode → Run → Use WebView to login → Extract metadata!

**💪 Technical Excellence:** Professional code quality, comprehensive error handling, extensive documentation.

---

*Built with ❤️ using Swift and SwiftUI*
