//
//  ContentView.swift
//  NetflixMetadataApp
//
//  A SwiftUI app that reverse-engineers Netflix's non-public API
//  to retrieve video metadata without using official API keys
//

import SwiftUI
import WebKit

struct ContentView: View {
    //view model for taking data (MVVM Architecture)
    @StateObject private var viewModel = MetadataViewModel()
    @State private var showWebView = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Input Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Netflix Metadata Retriever")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Video ID Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Video ID")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("e.g., 80057281", text: $viewModel.videoId)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                            
                            Button(action: {
                                viewModel.fetchMetadataById()
                            }) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title2)
                            }
                            .disabled(viewModel.videoId.isEmpty || viewModel.isLoading)
                        }
                    }
                    
                    // Video Title Search
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Search by Title")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("e.g., Stranger Things", text: $viewModel.searchQuery)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button(action: {
                                viewModel.searchByTitle()
                            }) {
                                Image(systemName: "magnifyingglass.circle.fill")
                                    .font(.title2)
                            }
                            .disabled(viewModel.searchQuery.isEmpty || viewModel.isLoading)
                        }
                    }
                    
                    // Web Browser Toggle
                    Button(action: {
                        showWebView.toggle()
                    }) {
                        Label("Browse Netflix (Bonus Feature)", systemImage: "safari")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // Results Section
                if viewModel.isLoading { // if loading is going on then show this
                    Spacer()
                    ProgressView("Fetching metadata...")
                        .scaleEffect(1.2)
                    Spacer()
                } else if let error = viewModel.errorMessage { // if error
                    ScrollView {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            
                            Text("Error")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(error)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                        .padding()
                    }
                } else if let metadata = viewModel.metadata { // if succefully fetched
                    MetadataDetailView(metadata: metadata)
                } else {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "film")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Enter a Video ID or search by title")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showWebView) {
                NetflixWebView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Metadata Detail View
struct MetadataDetailView: View {
    let metadata: VideoMetadata
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Image
                if let imageUrl = metadata.imageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(ProgressView())
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
                }
                
                // Title
                Text(metadata.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                // Basic Info
                HStack(spacing: 12) {
                    if let year = metadata.year {
                        Label(String(year), systemImage: "calendar")
                    }
                    if let rating = metadata.maturityRating {
                        Label(rating, systemImage: "star.fill")
                    }
                    if let runtime = metadata.runtime {
                        Label("\(runtime)m", systemImage: "clock")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                // Series Info
                if let season = metadata.seasonNumber, let episode = metadata.episodeNumber {
                    Text("Season \(season), Episode \(episode)")
                        .font(.headline)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Description
                if let description = metadata.description {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Synopsis")
                            .font(.headline)
                        Text(description)
                            .font(.body)
                    }
                }
                
                // Genres
                if !metadata.genres.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Genres")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(metadata.genres, id: \.self) { genre in
                                    Text(genre)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }
                }
                
                // Cast
                if !metadata.cast.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cast")
                            .font(.headline)
                        Text(metadata.cast.joined(separator: ", "))
                            .font(.body)
                    }
                }
                
                // Technical Details (Bonus)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Technical Details")
                        .font(.headline)
                    
                    DetailRow(label: "Video ID", value: String(metadata.videoId))
                    
                    if let manifestUrl = metadata.manifestUrl {
                        DetailRow(label: "Manifest URL", value: manifestUrl, copyable: true)
                    }
                    
                    if let licenseUrl = metadata.licenseUrl {
                        DetailRow(label: "License URL", value: licenseUrl, copyable: true)
                    }
                    
                    if let certificateUrl = metadata.fairPlayCertUrl {
                        DetailRow(label: "FairPlay Certificate", value: certificateUrl, copyable: true)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
    }
}

// MARK: - Detail Row Component
struct DetailRow: View {
    let label: String
    let value: String
    var copyable: Bool = false
    
    @State private var showCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            HStack {
                Text(value)
                    .font(.caption)
                    .lineLimit(copyable ? 2 : 1)
                
                if copyable {
                    Button(action: {
                        UIPasteboard.general.string = value
                        showCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showCopied = false
                        }
                    }) {
                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                            .foregroundColor(showCopied ? .green : .blue)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
