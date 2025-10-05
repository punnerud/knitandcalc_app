//
//  RecipeDetailView.swift
//  KnitAndCalc
//
//  Recipe detail view
//

import SwiftUI
import PDFKit
import WebKit

// View extension for conditional modifiers
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct RecipeDetailView: View {
    let recipe: Recipe
    @State private var showEditRecipe = false
    @State private var isFullscreen = false
    @State private var pdfRotation = 0
    @State private var pdfCurrentPage = 0
    @State private var imageRotation = 0
    @State private var webRotation = 0
    @State private var isZoomed = false
    @Binding var recipes: [Recipe]
    @Environment(\.dismiss) var dismiss

    init(recipe: Recipe, recipes: Binding<[Recipe]> = .constant([])) {
        self.recipe = recipe
        self._recipes = recipes
    }

    var body: some View {
        normalView
            .navigationTitle(recipe.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { isFullscreen = true }) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .foregroundColor(.appIconTint)
                        }

                        Button(action: { showEditRecipe = true }) {
                            Image(systemName: "gearshape")
                                .foregroundColor(.appIconTint)
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditRecipe) {
                EditRecipeView(recipes: $recipes, recipe: recipe)
            }
            .fullScreenCover(isPresented: $isFullscreen) {
                fullscreenView
            }
    }

    var normalView: some View {
        recipeContent
    }

    var fullscreenView: some View {
        FullscreenRecipeView(recipe: recipe, isFullscreen: $isFullscreen, pdfRotation: $pdfRotation, pdfCurrentPage: $pdfCurrentPage, imageRotation: $imageRotation, webRotation: $webRotation)
    }

    var recipeContent: some View {
        Group {
            switch recipe.type {
            case .link:
                RotatableWebView(urlString: recipe.content, rotation: $webRotation)

            case .images:
                ImageGalleryView(imagePaths: getImagePaths(), rotation: $imageRotation, isZoomed: $isZoomed, showControls: true)

            case .pdf:
                if let url = resolvePDFURL() {
                    PDFViewerView(url: url, currentPage: $pdfCurrentPage, rotation: $pdfRotation, isZoomed: $isZoomed)
                } else {
                    Text("Kunne ikke laste PDF - ugyldig URL")
                        .foregroundColor(.appSecondaryText)
                }
            }
        }
    }

    func getImagePaths() -> [String] {
        if let data = recipe.content.data(using: .utf8),
           let paths = try? JSONDecoder().decode([String].self, from: data) {
            return paths
        }
        return []
    }

    func resolvePDFURL() -> URL? {
        // Try to resolve from bookmark first
        if let bookmarkData = Data(base64Encoded: recipe.content) {
            var isStale = false
            if let url = try? URL(resolvingBookmarkData: bookmarkData, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale) {
                return url
            }
        }

        // Fallback to direct URL
        return URL(string: recipe.content)
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

// Rotatable Web View
struct RotatableWebView: View {
    let urlString: String
    @Binding var rotation: Int

    var body: some View {
        ZStack {
            WebView(urlString: urlString)
                .rotationEffect(.degrees(Double(rotation)))

            VStack {
                Spacer()
                Button(action: {
                    let newRotation = (rotation + 90) % 360
                    rotation = newRotation
                }) {
                    HStack {
                        Image(systemName: "rotate.right")
                        Text("Roter (\(rotation)°)")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.appButtonText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.appButtonBackgroundSelected)
                    .cornerRadius(8)
                }
                .padding(.bottom)
            }
        }
    }
}

// Image Gallery View
struct ImageGalleryView: View {
    let imagePaths: [String]
    @State private var currentIndex: Int = 0
    @Binding var rotation: Int
    @Binding var isZoomed: Bool
    var showControls: Bool = false
    var isFullscreen: Bool = false

    var body: some View {
        ZStack {
            if imagePaths.isEmpty {
                Text("Ingen bilder funnet")
                    .foregroundColor(.appSecondaryText)
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(0..<imagePaths.count, id: \.self) { index in
                        if let image = loadImage(imagePaths[index]) {
                            RotatableImageView(image: image, rotation: rotation, isZoomed: $isZoomed, isFullscreen: isFullscreen)
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: isFullscreen ? .never : .always))
                .if(isFullscreen) { view in
                    view.edgesIgnoringSafeArea(.all)
                }

                if showControls && !isFullscreen {
                    VStack {
                        Spacer()
                        HStack {
                            Button(action: {
                                let newRotation = (rotation + 90) % 360
                                rotation = newRotation
                            }) {
                                HStack {
                                    Image(systemName: "rotate.right")
                                    Text("Roter (\(rotation)°)")
                                }
                                .font(.system(size: 14))
                                .foregroundColor(.appButtonText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.appButtonBackgroundSelected)
                                .cornerRadius(8)
                            }
                            .padding(.leading, 20)
                            Spacer()
                        }
                        .padding(.bottom)
                    }
                } else if !showControls && !isFullscreen {
                    VStack {
                        Spacer()
                        Text("\(currentIndex + 1) / \(imagePaths.count)")
                            .font(.system(size: 14))
                            .foregroundColor(.appSecondaryText)
                            .padding(.bottom, 8)
                    }
                }
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

// Rotatable Image View with Zoom
struct RotatableImageView: UIViewRepresentable {
    let image: UIImage
    let rotation: Int
    @Binding var isZoomed: Bool
    var isFullscreen: Bool = false

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
            // Apply rotation
            let rotatedImage = image.rotate(degrees: rotation)
            imageView.image = rotatedImage

            // Change background based on fullscreen
            if context.coordinator.isFullscreen {
                scrollView.backgroundColor = .black
            } else {
                scrollView.backgroundColor = .systemBackground
            }
        }
        context.coordinator.isZoomed = $isZoomed
        context.coordinator.isFullscreen = isFullscreen
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isZoomed: $isZoomed, isFullscreen: isFullscreen)
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var isZoomed: Binding<Bool>
        var isFullscreen: Bool

        init(isZoomed: Binding<Bool>, isFullscreen: Bool) {
            self.isZoomed = isZoomed
            self.isFullscreen = isFullscreen
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.viewWithTag(100)
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            isZoomed.wrappedValue = scrollView.zoomScale > 1.0
        }
    }
}

// UIImage extension for rotation
extension UIImage {
    func rotate(degrees: Int) -> UIImage {
        let radians = CGFloat(degrees) * .pi / 180

        var newSize = CGRect(origin: .zero, size: self.size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .size
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!

        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        context.rotate(by: radians)
        self.draw(in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage ?? self
    }
}

// Fullscreen Recipe View
struct FullscreenRecipeView: View {
    let recipe: Recipe
    @Binding var isFullscreen: Bool
    @Binding var pdfRotation: Int
    @Binding var pdfCurrentPage: Int
    @Binding var imageRotation: Int
    @Binding var webRotation: Int
    @State private var isZoomed: Bool = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geometry in
                Group {
                    switch recipe.type {
                    case .link:
                        WebView(urlString: recipe.content)
                            .frame(
                                width: webRotation % 180 == 0 ? geometry.size.width : geometry.size.height,
                                height: webRotation % 180 == 0 ? geometry.size.height : geometry.size.width
                            )
                            .rotationEffect(.degrees(Double(webRotation)))
                            .frame(width: geometry.size.width, height: geometry.size.height)

                    case .images:
                        ImageGalleryView(imagePaths: getImagePaths(), rotation: $imageRotation, isZoomed: $isZoomed, showControls: false, isFullscreen: true)

                    case .pdf:
                        if let url = resolvePDFURL() {
                            PDFViewerView(url: url, isFullscreen: true, currentPage: $pdfCurrentPage, rotation: $pdfRotation, isZoomed: $isZoomed)
                        } else {
                            Text("Kunne ikke laste PDF")
                                .foregroundColor(.white)
                        }
                    }
                }
                .ignoresSafeArea()
            }

            VStack {
                HStack {
                    Spacer()
                    Button(action: { isFullscreen = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 4)
                            .opacity(isZoomed ? 0 : 1)
                    }
                    .allowsHitTesting(!isZoomed)
                    .padding(.top, 50)
                    .padding(.trailing, 20)
                }
                Spacer()
            }
        }
        .edgesIgnoringSafeArea(.all)
        .statusBar(hidden: true)
    }

    func getImagePaths() -> [String] {
        if let data = recipe.content.data(using: .utf8),
           let paths = try? JSONDecoder().decode([String].self, from: data) {
            return paths
        }
        return []
    }

    func resolvePDFURL() -> URL? {
        // Try to resolve from bookmark first
        if let bookmarkData = Data(base64Encoded: recipe.content) {
            var isStale = false
            if let url = try? URL(resolvingBookmarkData: bookmarkData, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale) {
                return url
            }
        }

        // Fallback to direct URL
        return URL(string: recipe.content)
    }
}

// PDF Viewer with navigation and rotation
struct PDFViewerView: View {
    let url: URL
    var isFullscreen: Bool = false
    @State private var document: PDFDocument?
    @Binding var currentPage: Int
    @Binding var rotation: Int
    @Binding var isZoomed: Bool
    @State private var isAccessing = false

    var body: some View {
        VStack(spacing: 0) {
            if let doc = document, doc.pageCount > 0 {
                // PDF Page Display
                GeometryReader { geometry in
                    if let page = doc.page(at: currentPage) {
                        PDFPageView(page: page, rotation: rotation, isZoomed: $isZoomed)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .gesture(
                                DragGesture(minimumDistance: 50)
                                    .onEnded { value in
                                        if !isZoomed {
                                            if value.translation.width < 0 {
                                                // Swipe left - next page
                                                if currentPage < doc.pageCount - 1 {
                                                    currentPage += 1
                                                }
                                            } else if value.translation.width > 0 {
                                                // Swipe right - previous page
                                                if currentPage > 0 {
                                                    currentPage -= 1
                                                }
                                            }
                                        }
                                    }
                            )
                    }
                }

                // Controls - hide in fullscreen
                if !isFullscreen {
                    VStack(spacing: 12) {
                        // Page navigation
                        HStack(spacing: 20) {
                            Button(action: {
                                if currentPage > 0 {
                                    currentPage -= 1
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20))
                                    .foregroundColor(currentPage > 0 ? .appIconTint : .appTertiaryText)
                            }
                            .disabled(currentPage == 0)

                            Text("Side \(currentPage + 1) av \(doc.pageCount)")
                                .font(.system(size: 14))
                                .foregroundColor(.appText)

                            Button(action: {
                                if currentPage < doc.pageCount - 1 {
                                    currentPage += 1
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 20))
                                    .foregroundColor(currentPage < doc.pageCount - 1 ? .appIconTint : .appTertiaryText)
                            }
                            .disabled(currentPage >= doc.pageCount - 1)
                        }

                        // Rotation button
                        Button(action: {
                            let newRotation = (rotation + 90) % 360
                            rotation = newRotation
                        }) {
                            HStack {
                                Image(systemName: "rotate.right")
                                Text("Roter (\(rotation)°)")
                            }
                            .font(.system(size: 14))
                            .foregroundColor(.appButtonText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.appButtonBackgroundSelected)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.appBackground)
                }
            } else {
                Text("Laster PDF...")
                    .foregroundColor(.appSecondaryText)
            }
        }
        .onAppear {
            loadPDF()
        }
        .onDisappear {
            if isAccessing {
                url.stopAccessingSecurityScopedResource()
                isAccessing = false
            }
        }
    }

    private func loadPDF() {
        if url.startAccessingSecurityScopedResource() {
            isAccessing = true
        }

        guard let doc = PDFDocument(url: url) else {
            return
        }

        document = doc
    }
}

// Single PDF Page View
struct PDFPageView: UIViewRepresentable {
    let page: PDFPage
    let rotation: Int
    @Binding var isZoomed: Bool

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 1.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false

        let pdfView = PDFView()
        pdfView.backgroundColor = .systemBackground
        pdfView.autoScales = true
        pdfView.tag = 100

        scrollView.addSubview(pdfView)

        // Set up constraints
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pdfView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            pdfView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            pdfView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            pdfView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
        ])

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        if let pdfView = scrollView.viewWithTag(100) as? PDFView {
            // Create a temporary document with just this page
            let tempDoc = PDFDocument()

            // Clone the page and apply rotation
            if let pageCopy = page.copy() as? PDFPage {
                pageCopy.rotation = rotation
                tempDoc.insert(pageCopy, at: 0)
                pdfView.document = tempDoc
                pdfView.autoScales = true
            }
        }
        context.coordinator.isZoomed = $isZoomed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isZoomed: $isZoomed)
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var isZoomed: Binding<Bool>

        init(isZoomed: Binding<Bool>) {
            self.isZoomed = isZoomed
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.viewWithTag(100)
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            isZoomed.wrappedValue = scrollView.zoomScale > 1.0
        }
    }
}

#Preview {
    RecipeDetailView(recipe: Recipe(
        name: "Test Oppskrift",
        category: .sweaters,
        type: .link,
        content: "https://example.com"
    ))
}