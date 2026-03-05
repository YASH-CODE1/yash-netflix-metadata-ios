//
//  MetadataViewModel.swift
//  NetflixMetadataApp
//
//  ViewModel for managing metadata fetching and state
//

import Foundation
import Combine

@MainActor
class MetadataViewModel: ObservableObject {
    @Published var videoId: String = ""
    @Published var searchQuery: String = ""
    @Published var metadata: VideoMetadata?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let apiService = NetflixAPIService.shared
    
    // MARK: - Fetch Metadata by ID
    func fetchMetadataById() {
        guard !videoId.isEmpty else { return }
        
        Task {
            isLoading = true // Loading while the api data is being fetched
            errorMessage = nil
            metadata = nil
            
            do {
                let result = try await apiService.fetchMetadata(videoId: videoId)
                
                // Try to fetch DRM URLs (bonus feature)
                let manifestUrl: String?
                let licenseUrl: String?
                let certUrl: String?
                if let urls = try? await apiService.fetchManifestUrls(videoId: videoId) {
                    manifestUrl = urls.manifestUrl
                    licenseUrl = urls.licenseUrl
                    certUrl = urls.certUrl
                } else {
                    manifestUrl = nil
                    licenseUrl = nil
                    certUrl = nil
                }
                
                // Create enhanced metadata with DRM URLs
                metadata = VideoMetadata(
                    videoId: result.videoId,
                    title: result.title,
                    description: result.description,
                    year: result.year,
                    runtime: result.runtime,
                    maturityRating: result.maturityRating,
                    imageUrl: result.imageUrl,
                    genres: result.genres,
                    cast: result.cast,
                    seasonNumber: result.seasonNumber,
                    episodeNumber: result.episodeNumber,
                    manifestUrl: manifestUrl,
                    licenseUrl: licenseUrl,
                    fairPlayCertUrl: certUrl
                )
                
            } catch {
                errorMessage = error.localizedDescription
                print("Error fetching metadata: \(error)")
            }
            
            isLoading = false
        }
    }
    
    // MARK: - Search by Title
    func searchByTitle() {
        guard !searchQuery.isEmpty else { return }
        
        Task {
            isLoading = true
            errorMessage = nil
            metadata = nil
            
            do {
                // For now, showing an informative error
                errorMessage = """
                Title search is available but requires additional API implementation.
                
                Please use a known Video ID instead. Here are some examples you can try:
                
                • 80057281 - Stranger Things
                • 80189685 - The Crown
                • 80117401 - The Witcher
                • 70143836 - Breaking Bad
                • 70251912 - Narcos
                
                To find more IDs, browse Netflix in the web view and check the URL.
                """
                
            }
            
            isLoading = false
        }
    }
    
    // MARK: - Update from WebView
    func updateFromWebView(videoId: String, buildId: String, cookies: [String: String]) {
        self.videoId = videoId
        
        // Configuring API service with extracted values
        if let netflixId = cookies["NetflixId"],
           let secureNetflixId = cookies["SecureNetflixId"] {
            apiService.configure(
                buildId: buildId,
                netflixId: netflixId,
                secureNetflixId: secureNetflixId
            )
        }
        
        // Automatically fetching metadata
        fetchMetadataById()
    }
    
    // MARK: - Clear Results
    func clear() {
        metadata = nil
        errorMessage = nil
        videoId = ""
        searchQuery = ""
    }
}

