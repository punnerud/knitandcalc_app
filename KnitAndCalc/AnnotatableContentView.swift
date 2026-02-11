//
//  AnnotatableContentView.swift
//  KnitAndCalc
//
//  UIViewRepresentable wrappers for annotatable image and PDF views
//

import SwiftUI
import PDFKit

// MARK: - Annotatable Image View

struct AnnotatableImageView: UIViewRepresentable {
    let image: UIImage
    let rotation: Int
    @Binding var isZoomed: Bool
    var isFullscreen: Bool = false

    @Binding var pageAnnotations: PageAnnotations
    var activeTool: AnnotationTool = .none
    var currentColor: String = "FF0000"
    var currentLineWidth: CGFloat = 3.0
    var onAnnotationsChanged: ((PageAnnotations) -> Void)?

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 1.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false

        // Container for zooming
        let containerView = UIView()
        containerView.tag = 200

        // Image
        let rotatedImage = image.rotate(degrees: rotation)
        let imageView = UIImageView(image: rotatedImage)
        imageView.contentMode = .scaleAspectFit
        imageView.tag = 100

        // Annotation overlay
        let overlay = AnnotationOverlayView()
        overlay.tag = 300
        overlay.imageSize = rotatedImage.size
        overlay.pageAnnotations = pageAnnotations
        overlay.activeTool = activeTool
        overlay.currentDrawColor = currentColor
        overlay.currentDrawLineWidth = currentLineWidth
        let coordinator = context.coordinator
        overlay.onAnnotationsChanged = { newAnnotations in
            DispatchQueue.main.async {
                coordinator.parent?.pageAnnotations = newAnnotations
                coordinator.parent?.onAnnotationsChanged?(newAnnotations)
            }
        }

        containerView.addSubview(imageView)
        containerView.addSubview(overlay)
        scrollView.addSubview(containerView)

        // Auto-layout
        imageView.translatesAutoresizingMaskIntoConstraints = false
        overlay.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            containerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            containerView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),

            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            overlay.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            overlay.topAnchor.constraint(equalTo: containerView.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        context.coordinator.parent = self

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.parent = self

        let rotatedImage = image.rotate(degrees: rotation)

        // Update image
        if let imageView = scrollView.viewWithTag(100) as? UIImageView {
            imageView.image = rotatedImage
        }

        // Update overlay
        if let overlay = scrollView.viewWithTag(300) as? AnnotationOverlayView {
            overlay.imageSize = rotatedImage.size
            overlay.pageAnnotations = pageAnnotations
            overlay.activeTool = activeTool
            overlay.currentDrawColor = currentColor
            overlay.currentDrawLineWidth = currentLineWidth
            overlay.onAnnotationsChanged = { newAnnotations in
                DispatchQueue.main.async {
                    context.coordinator.parent?.pageAnnotations = newAnnotations
                    context.coordinator.parent?.onAnnotationsChanged?(newAnnotations)
                }
            }
            overlay.setNeedsDisplay()
        }

        // Adjust pan gesture for tool mode
        if activeTool != .none && !pageAnnotations.isLocked {
            scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
        } else {
            scrollView.panGestureRecognizer.minimumNumberOfTouches = 1
        }

        // Background
        scrollView.backgroundColor = isFullscreen ? .black : .systemBackground

        context.coordinator.isZoomed = $isZoomed
        context.coordinator.isFullscreen = isFullscreen
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isZoomed: $isZoomed, isFullscreen: isFullscreen)
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var isZoomed: Binding<Bool>
        var isFullscreen: Bool
        var parent: AnnotatableImageView?

        init(isZoomed: Binding<Bool>, isFullscreen: Bool) {
            self.isZoomed = isZoomed
            self.isFullscreen = isFullscreen
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.viewWithTag(200)
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            isZoomed.wrappedValue = scrollView.zoomScale > 1.0
        }
    }
}

// MARK: - Annotatable PDF Page View

struct AnnotatablePDFPageView: UIViewRepresentable {
    let page: PDFPage
    let rotation: Int
    @Binding var isZoomed: Bool

    @Binding var pageAnnotations: PageAnnotations
    var activeTool: AnnotationTool = .none
    var currentColor: String = "FF0000"
    var currentLineWidth: CGFloat = 3.0
    var onAnnotationsChanged: ((PageAnnotations) -> Void)?

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 1.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false

        // Container for zooming
        let containerView = UIView()
        containerView.tag = 200

        // PDF view
        let pdfView = PDFView()
        pdfView.backgroundColor = .systemBackground
        pdfView.autoScales = true
        pdfView.tag = 100

        // Annotation overlay
        var pageSize = page.bounds(for: .mediaBox).size
        if rotation % 180 != 0 {
            pageSize = CGSize(width: pageSize.height, height: pageSize.width)
        }
        let overlay = AnnotationOverlayView()
        overlay.tag = 300
        overlay.imageSize = pageSize
        overlay.pageAnnotations = pageAnnotations
        overlay.activeTool = activeTool
        overlay.currentDrawColor = currentColor
        overlay.currentDrawLineWidth = currentLineWidth
        let coordinator = context.coordinator
        overlay.onAnnotationsChanged = { newAnnotations in
            DispatchQueue.main.async {
                coordinator.parent?.pageAnnotations = newAnnotations
                coordinator.parent?.onAnnotationsChanged?(newAnnotations)
            }
        }

        containerView.addSubview(pdfView)
        containerView.addSubview(overlay)
        scrollView.addSubview(containerView)

        // Auto-layout
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        overlay.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            containerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            containerView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),

            pdfView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            pdfView.topAnchor.constraint(equalTo: containerView.topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            overlay.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            overlay.topAnchor.constraint(equalTo: containerView.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        context.coordinator.parent = self

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.parent = self

        // Update PDF page
        if let pdfView = scrollView.viewWithTag(100) as? PDFView {
            let tempDoc = PDFDocument()
            if let pageCopy = page.copy() as? PDFPage {
                pageCopy.rotation = rotation
                tempDoc.insert(pageCopy, at: 0)
                pdfView.document = tempDoc
                pdfView.autoScales = true
            }
        }

        // Compute effective PDF page size (accounting for rotation)
        var pageSize = page.bounds(for: .mediaBox).size
        if rotation % 180 != 0 {
            pageSize = CGSize(width: pageSize.height, height: pageSize.width)
        }

        // Update overlay
        if let overlay = scrollView.viewWithTag(300) as? AnnotationOverlayView {
            overlay.imageSize = pageSize
            overlay.pageAnnotations = pageAnnotations
            overlay.activeTool = activeTool
            overlay.currentDrawColor = currentColor
            overlay.currentDrawLineWidth = currentLineWidth
            overlay.onAnnotationsChanged = { newAnnotations in
                DispatchQueue.main.async {
                    context.coordinator.parent?.pageAnnotations = newAnnotations
                    context.coordinator.parent?.onAnnotationsChanged?(newAnnotations)
                }
            }
            overlay.setNeedsDisplay()
        }

        // Adjust pan gesture for tool mode
        if activeTool != .none && !pageAnnotations.isLocked {
            scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
        } else {
            scrollView.panGestureRecognizer.minimumNumberOfTouches = 1
        }

        context.coordinator.isZoomed = $isZoomed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isZoomed: $isZoomed)
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var isZoomed: Binding<Bool>
        var parent: AnnotatablePDFPageView?

        init(isZoomed: Binding<Bool>) {
            self.isZoomed = isZoomed
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.viewWithTag(200)
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            isZoomed.wrappedValue = scrollView.zoomScale > 1.0
        }
    }
}
