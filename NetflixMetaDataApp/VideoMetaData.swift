//
//  VideoMetadata.swift
//  NetflixMetadataApp
//
//  Models for Netflix video metadata
//

import Foundation

struct VideoMetadata: Identifiable {
    let id = UUID()
    let videoId: Int
    let title: String
    let description: String?
    let year: Int?
    let runtime: Int? // in minutes
    let maturityRating: String?
    let imageUrl: String?
    let genres: [String]
    let cast: [String]
    
    // Series-specific
    let seasonNumber: Int?
    let episodeNumber: Int?
    
    // DRM & Playback URLs (Bonus)
    let manifestUrl: String?
    let licenseUrl: String?
    let fairPlayCertUrl: String?
    
    init(videoId: Int,
         title: String,
         description: String? = nil,
         year: Int? = nil,
         runtime: Int? = nil,
         maturityRating: String? = nil,
         imageUrl: String? = nil,
         genres: [String] = [],
         cast: [String] = [],
         seasonNumber: Int? = nil,
         episodeNumber: Int? = nil,
         manifestUrl: String? = nil,
         licenseUrl: String? = nil,
         fairPlayCertUrl: String? = nil) {
        self.videoId = videoId
        self.title = title
        self.description = description
        self.year = year
        self.runtime = runtime
        self.maturityRating = maturityRating
        self.imageUrl = imageUrl
        self.genres = genres
        self.cast = cast
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.manifestUrl = manifestUrl
        self.licenseUrl = licenseUrl
        self.fairPlayCertUrl = fairPlayCertUrl
    }
}

// MARK: - Netflix API Response Models
// These match the actual Netflix shakti API responses

struct NetflixVideoResponse: Codable {
    let value: NetflixValue?
    
    struct NetflixValue: Codable {
        let videos: [String: VideoDetail]?
    }
    
    struct VideoDetail: Codable {
        let summary: Summary?
        let title: String?
        let synopsis: String?
        let releaseYear: Int?
        let runtime: Int?
        let maturity: Maturity?
        let genres: [Genre]?
        let creators: [Creator]?
        let directors: [Creator]?
        let cast: [Creator]?
        let boxarts: Boxarts?
        let episodeCount: Int?
        let seasonCount: Int?
        let currentEpisode: Int?
        let currentSeason: Int?
    }
    
    struct Summary: Codable {
        let id: Int?
        let type: String?
        let isOriginal: Bool?
    }
    
    struct Maturity: Codable {
        let rating: Rating?
        
        struct Rating: Codable {
            let value: String?
            let maturityLevel: Int?
        }
    }
    
    struct Genre: Codable {
        let id: Int?
        let name: String?
    }
    
    struct Creator: Codable {
        let id: String?
        let name: String?
    }
    
    struct Boxarts: Codable {
        let _1280x720: ImageDetail?
        let _665x375: ImageDetail?
        
        struct ImageDetail: Codable {
            let url: String?
        }
        
        enum CodingKeys: String, CodingKey {
            case _1280x720 = "_1280x720"
            case _665x375 = "_665x375"
        }
    }
}

// MARK: - Search Response
struct NetflixSearchResponse: Codable {
    let value: SearchValue?
    
    struct SearchValue: Codable {
        let search: SearchResults?
    }
    
    struct SearchResults: Codable {
        let byTerm: [String: TermResults]?
    }
    
    struct TermResults: Codable {
        let titles: [String]?
    }
}

// MARK: - Manifest Response (for DRM URLs)
struct NetflixManifestResponse: Codable {
    let result: ManifestResult?
    
    struct ManifestResult: Codable {
        let viewables: [ViewableContent]?
        let licenses: [License]?
    }
    
    struct ViewableContent: Codable {
        let videoId: Int?
        let downloadables: [Downloadable]?
    }
    
    struct Downloadable: Codable {
        let urls: [ManifestUrl]?
    }
    
    struct ManifestUrl: Codable {
        let url: String?
        let cdn: String?
    }
    
    struct License: Codable {
        let drmHeader: DrmHeader?
        let licenseURL: String?
    }
    
    struct DrmHeader: Codable {
        let licenseType: String?
        let serverCertificateURL: String?
    }
}
