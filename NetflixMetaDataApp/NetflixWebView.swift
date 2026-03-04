//
//  NetflixWebView.swift
//  NetflixMetadataApp
//
//  WebView for browsing Netflix and extracting metadata (Bonus Feature)
//

import SwiftUI
import WebKit
import Combine

struct NetflixWebView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: MetadataViewModel
    @StateObject private var webViewStore = WebViewStore()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // URL Bar
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text(webViewStore.currentURL)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        extractVideoId()
                    }) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                
                // WebView
                WebViewRepresentable(webView: webViewStore.webView)
                    .edgesIgnoringSafeArea(.bottom)
            }
            .navigationTitle("Browse Netflix")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: {
                            webViewStore.webView.goBack()
                        }) {
                            Image(systemName: "chevron.left")
                        }
                        .disabled(!webViewStore.webView.canGoBack)
                        
                        Button(action: {
                            webViewStore.webView.goForward()
                        }) {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(!webViewStore.webView.canGoForward)
                        
                        Button(action: {
                            webViewStore.webView.reload()
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Extract Video ID from current page
    private func extractVideoId() {
        webViewStore.webView.evaluateJavaScript("window.location.href") { result, error in
            if let url = result as? String {
                // Netflix URLs follow pattern: https://www.netflix.com/watch/80057281
                if let videoId = extractVideoIdFromURL(url) {
                    // Extract build ID from page
                    extractBuildId { buildId in
                        // Extract cookies
                        extractCookies { cookies in
                            DispatchQueue.main.async {
                                viewModel.updateFromWebView(
                                    videoId: videoId,
                                    buildId: buildId,
                                    cookies: cookies
                                )
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func extractVideoIdFromURL(_ url: String) -> String? {
        // Pattern: /watch/VIDEO_ID or /title/VIDEO_ID
        let patterns = [
            #"/watch/(\d+)"#,
            #"/title/(\d+)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)),
               let range = Range(match.range(at: 1), in: url) {
                return String(url[range])
            }
        }
        
        return nil
    }
    
    private func extractBuildId(completion: @escaping (String) -> Void) {
        let script = """
        (function() {
            var scripts = document.getElementsByTagName('script');
            for (var i = 0; i < scripts.length; i++) {
                var content = scripts[i].textContent;
                if (content && content.includes('BUILD_IDENTIFIER')) {
                    var match = content.match(/"BUILD_IDENTIFIER":"([^"]+)"/);
                    if (match) return match[1];
                }
            }
            return 'release'; // fallback to release
        })();
        """
        
        webViewStore.webView.evaluateJavaScript(script) { result, error in
            let buildId = (result as? String) ?? "release"
            completion(buildId)
        }
    }
    
    private func extractCookies(completion: @escaping ([String: String]) -> Void) {
        let cookieStore = webViewStore.webView.configuration.websiteDataStore.httpCookieStore
        
        cookieStore.getAllCookies { cookies in
            var cookieDict: [String: String] = [:]
            
            for cookie in cookies where cookie.domain.contains("netflix.com") {
                cookieDict[cookie.name] = cookie.value
            }
            
            completion(cookieDict)
        }
    }
}

// MARK: - WebView Store
@MainActor
class WebViewStore: NSObject, ObservableObject {
    @Published var currentURL: String = "https://www.netflix.com"
    
    lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        
        // Load Netflix
        if let url = URL(string: "https://www.netflix.com") {
            webView.load(URLRequest(url: url))
        }
        
        return webView
    }()
}

// MARK: - WebView Navigation Delegate
extension WebViewStore: WKNavigationDelegate {
    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            self.currentURL = webView.url?.absoluteString ?? "https://www.netflix.com"
        }
    }
}

// MARK: - WebView Representable
struct WebViewRepresentable: UIViewRepresentable {
    let webView: WKWebView
    
    func makeUIView(context: Context) -> WKWebView {
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed
    }
}
