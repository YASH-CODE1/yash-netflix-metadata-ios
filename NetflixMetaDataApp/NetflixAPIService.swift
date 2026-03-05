//
//  NetflixAPIService.swift
//  NetflixMetadataApp
//
//  Reverse-engineered Netflix API service
//  This uses Netflix's internal "shakti" API endpoints
//

import Foundation

class NetflixAPIService {
    static let shared = NetflixAPIService()
    
    // These values need to be extracted from an authenticated Netflix session
    private var buildIdentifier = "mre" // Example value, update from browser
    private var authURL = "v9c0e26cd"
    
    // Netflix cookies - must be obtained from logged-in session
    var netflixId: String = "v%3D3%26ct%3DBgjHlOvcAxLxAoLMKkP7Lwg-qr7LaNvzxYd6PuqitsGfkmhMrOzSM9H5O7qCbnyxrLGj2BQ4LDbVInVzpSsn1NneGKjnach0RiYSeab-S_ms9rMK5_CduA_HH5y6UeEoQXuqzylXELmItHlIkoMjP0WsxvJq_6KTyOxSORh0SmBasSjFZXXGHjyP658xHgnGUJ-M7NL_8mCQ3QXmijB6QJ31mY8lR2E9r6ySP1qGg1q5O3cCFSzf9mvSJlp8KgVJVaFUYGgl5h7buPz45d4y1zu89LJE110y7NamS5T1mJmykRJ967cncNP2MaEP_dQh5l4ZiuGeUng4fT5B0p4kzqEsVBkA4gJLP5a1BaohT2AY7n4nQHcR7GIlYlzNoVvVuh1zJsyDehcK1nWA06MKRFl9i-brcq-M2wPWE4cmUx-j7nJGfU-jYvtzAUIJEygOrE9cxUuGxIvH3s3LqkTpv7rsZqPl-HRogRj2U0gWz2zKkCKQWF_XFNBVDRgGIg4KDBuBCjhhPld_KZQ3xw..%26pg%3DRSSQTUCYVVDINOFY5YFSP47U5Q%26ch%3DAQEAEAABABSVglGlUMdoFlYmDMdz2jzWCtZkfw0TFYA" // NetflixId cookie
    var secureNetflixId: String = "v%3D3%26mac%3DAQEAEQABABR5bX_vx30o0bKe_wmULKBd-wOdvQPXOP0.%26dt%3D1771078159092" // SecureNetflixId cookie
    
    private init() {}
    
    // MARK: - Configuration
    func configure(buildId: String, netflixId: String, secureNetflixId: String) {
        self.buildIdentifier = buildId
        self.authURL = "https://www.netflix.com/nq/website/memberapi/\(buildId)"
        self.netflixId = netflixId
        self.secureNetflixId = secureNetflixId
    }
    
    // MARK: - Fetch Metadata by Video ID
    func fetchMetadata(videoId: String) async throws -> VideoMetadata {
        // Build the release pathEvaluator URL with query items similar to browser
        var components = URLComponents(string: "https://www.netflix.com/nq/website/memberapi/release/pathEvaluator")!
        components.queryItems = [
            URLQueryItem(name: "withSize", value: "true"),
            URLQueryItem(name: "materialize", value: "true"),
            URLQueryItem(name: "original_path", value: "/shakti/mre/pathEvaluator")
        ]
        guard let url = components.url else { throw APIError.invalidURL }

        // Minimal Falcor path to fetch core metadata for a single ID
        let pathArray = """
        ["videos",\(videoId),"current",["summary","synopsis","releaseYear","runtime","maturity","genres","cast","boxarts"]]
        """

        // NOTE: authURL token is required by Netflix and must be obtained from the logged-in WebView session.
        // For now, trying to reuse the existing `authURL` property if it already contains the token; otherwise this will likely fail.
        // Plumb a fresh token from WebView into this service.
        let authToken = authURL // expected to be a token like c1.XXXXXXXX.... not a URL path.

        func encode(_ s: String) -> String {
            s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? s
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("en-GB,en;q=0.5", forHTTPHeaderField: "Accept-Language")
        request.setValue("https://www.netflix.com", forHTTPHeaderField: "Origin")
        request.setValue("https://www.netflix.com/browse", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")

        // Attach cookies if available
        if !netflixId.isEmpty && !secureNetflixId.isEmpty {
            let cookieString = "NetflixId=\(netflixId); SecureNetflixId=\(secureNetflixId)"
            request.setValue(cookieString, forHTTPHeaderField: "Cookie")
        }

        // Building x-www-form-urlencoded body with path and authURL token
        let bodyString = "path=\(encode(pathArray))&authURL=\(encode(authToken))"
        request.httpBody = bodyString.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.authenticationRequired
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        // At this point, the response is a Falcor jsonGraph, not the legacy value.videos shape.
        // For now, attempt to parse with the existing model; if it fails, throw a decodingError with the raw body for inspection.
        do {
            let decoder = JSONDecoder()
            let netflixResponse = try decoder.decode(NetflixVideoResponse.self, from: data)
            if let videoData = netflixResponse.value?.videos?[videoId] {
                return parseVideoMetadata(videoId: Int(videoId) ?? 0, data: videoData)
            } else {
                // Fallback: dump body for debugging and signal no data
                let raw = String(data: data, encoding: .utf8) ?? "<non-utf8>"
                print("Falcor response (debug):\n\(raw)")
                throw APIError.noDataFound
            }
        } catch {
            let raw = String(data: data, encoding: .utf8) ?? "<non-utf8>"
            print("Decoding failed, raw body:\n\(raw)")
            throw APIError.decodingError(error)
        }
    }
    
    // MARK: - Search by Title
    func searchByTitle(query: String) async throws -> [VideoMetadata] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let path = """
        ["search","byTerm","\(encodedQuery)",{"from":0,"to":20},"titles",{"from":0,"to":10},["summary","title","synopsis","releaseYear","runtime","maturity","genres","cast","boxarts","_665x375"]]
        """
        
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(authURL)/pathEvaluator?withSize=true&materialize=true&model=harris&path=\(encodedPath)"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if !netflixId.isEmpty && !secureNetflixId.isEmpty {
            let cookieString = "NetflixId=\(netflixId); SecureNetflixId=\(secureNetflixId)"
            request.setValue(cookieString, forHTTPHeaderField: "Cookie")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.authenticationRequired
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        // For simplicity, return a mock result
        // In production, parse the complex search response
        throw APIError.notImplemented
    }
    
    // MARK: - Fetch Manifest URLs (Bonus - DRM URLs)
    func fetchManifestUrls(videoId: String) async throws -> (manifestUrl: String?, licenseUrl: String?, certUrl: String?) {
        // Netflix manifest API endpoint
        // This requires more complex authentication and request signing
        // For demonstration purposes, we'll return sample URLs
        
        let manifestUrl = "https://nflxvideo.net/manifest/\(videoId).mpd"
        let licenseUrl = "https://nflxvideo.net/license"
        let certUrl = "https://nflxvideo.net/cert"
        
        return (manifestUrl, licenseUrl, certUrl)
    }
    
    // MARK: - Helper Methods
    private func parseVideoMetadata(videoId: Int, data: NetflixVideoResponse.VideoDetail) -> VideoMetadata {
        let genres = data.genres?.compactMap { $0.name } ?? []
        let cast = data.cast?.compactMap { $0.name } ?? []
        let imageUrl = data.boxarts?._665x375?.url ?? data.boxarts?._1280x720?.url
        
        return VideoMetadata(
            videoId: videoId,
            title: data.title ?? "Unknown Title",
            description: data.synopsis,
            year: data.releaseYear,
            runtime: data.runtime,
            maturityRating: data.maturity?.rating?.value,
            imageUrl: imageUrl,
            genres: genres,
            cast: cast,
            seasonNumber: data.currentSeason,
            episodeNumber: data.currentEpisode,
            manifestUrl: nil,
            licenseUrl: nil,
            fairPlayCertUrl: nil
        )
    }
    
    // MARK: - Extract Build ID from Netflix Page
    static func extractBuildIdentifier(from html: String) -> String? {
        // Netflix embeds the build ID in their HTML
        // Pattern: "BUILD_IDENTIFIER":"v9c0e26cd"
        let pattern = #""BUILD_IDENTIFIER":"([^"]+)""#
        
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            return String(html[range])
        }
        
        return nil
    }
}

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case authenticationRequired
    case noDataFound
    case notImplemented
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .authenticationRequired:
            return "Authentication required. Please log in through the web browser."
        case .noDataFound:
            return "No data found for this video ID"
        case .notImplemented:
            return "This feature requires additional implementation"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

