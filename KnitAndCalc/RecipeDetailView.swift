//
//  RecipeDetailView.swift
//  KnitAndCalc
//
//  Recipe detail view
//

import SwiftUI
import PDFKit
import WebKit

struct RecipeDetailView: View {
    let recipe: Recipe

    var body: some View {
        Group {
            switch recipe.type {
            case .link:
                WebView(urlString: recipe.content)

            case .images:
                ImageGalleryView(imagePaths: getImagePaths())

            case .pdf:
                if let url = URL(string: recipe.content) {
                    PDFViewer(url: url)
                } else {
                    Text("Kunne ikke laste PDF")
                        .foregroundColor(.appSecondaryText)
                }
            }
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    func getImagePaths() -> [String] {
        if let data = recipe.content.data(using: .utf8),
           let paths = try? JSONDecoder().decode([String].self, from: data) {
            return paths
        }
        return []
    }
}

// Web View
struct WebView: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {}
}

// Image Gallery View
struct ImageGalleryView: View {
    let imagePaths: [String]
    @State private var currentIndex: Int = 0

    var body: some View {
        VStack {
            if imagePaths.isEmpty {
                Text("Ingen bilder funnet")
                    .foregroundColor(.appSecondaryText)
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(0..<imagePaths.count, id: \.self) { index in
                        if let image = loadImage(imagePaths[index]) {
                            ZoomableImageView(image: image)
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))

                Text("\(currentIndex + 1) / \(imagePaths.count)")
                    .font(.system(size: 14))
                    .foregroundColor(.appSecondaryText)
                    .padding(.bottom, 8)
            }
        }
    }

    func loadImage(_ filename: String) -> UIImage? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)

        if let data = try? Data(contentsOf: fileURL) {
            return UIImage(data: data)
        }
        return nil
    }
}

// Zoomable Image View
struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 1.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.tag = 100

        scrollView.addSubview(imageView)

        // Set up constraints
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            imageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
        ])

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        if let imageView = scrollView.viewWithTag(100) as? UIImageView {
            imageView.image = image
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.viewWithTag(100)
        }
    }
}

// PDF Viewer
struct PDFViewer: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous

        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {}
}

#Preview {
    NavigationView {
        RecipeDetailView(recipe: Recipe(
            name: "Test Oppskrift",
            category: .sweaters,
            type: .link,
            content: "https://example.com"
        ))
    }
}