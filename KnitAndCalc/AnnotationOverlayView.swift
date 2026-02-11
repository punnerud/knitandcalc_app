//
//  AnnotationOverlayView.swift
//  KnitAndCalc
//
//  UIView for rendering and interacting with annotations
//

import UIKit

class AnnotationOverlayView: UIView {

    // MARK: - Data

    var pageAnnotations = PageAnnotations() {
        didSet { setNeedsDisplay() }
    }
    var activeTool: AnnotationTool = .none
    var currentDrawColor: String = "FF0000"
    var currentDrawLineWidth: CGFloat = 3.0
    var onAnnotationsChanged: ((PageAnnotations) -> Void)?

    /// The size of the underlying image/PDF page (before display scaling).
    /// Used to compute the aspect-fit content rect within this view's bounds.
    var imageSize: CGSize = .zero {
        didSet { updateContentRect() }
    }

    /// The rect within bounds where the image content is displayed (aspect fit).
    private var imageContentRect: CGRect?

    private var contentRect: CGRect {
        imageContentRect ?? bounds
    }

    private func updateContentRect() {
        guard bounds.width > 0, bounds.height > 0,
              imageSize.width > 0, imageSize.height > 0 else {
            imageContentRect = nil
            return
        }
        let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let displayW = imageSize.width * scale
        let displayH = imageSize.height * scale
        imageContentRect = CGRect(
            x: (bounds.width - displayW) / 2,
            y: (bounds.height - displayH) / 2,
            width: displayW,
            height: displayH
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateContentRect()
    }

    // MARK: - Coordinate helpers

    private func toPixel(_ norm: CGPoint) -> CGPoint {
        let r = contentRect
        return CGPoint(x: r.origin.x + norm.x * r.width, y: r.origin.y + norm.y * r.height)
    }

    private func toNorm(_ pixel: CGPoint) -> CGPoint {
        let r = contentRect
        guard r.width > 0, r.height > 0 else { return .zero }
        return CGPoint(x: (pixel.x - r.origin.x) / r.width, y: (pixel.y - r.origin.y) / r.height)
    }

    // MARK: - In-progress state

    private var currentPath: [CGPoint] = []
    private var isCurrentPathEraser: Bool = false
    private var dragState: DragState? = nil

    private enum DragState {
        case drawingPath
        case movingRect(id: UUID, startOrigin: CGPoint, touchStart: CGPoint)
        case resizingRect(id: UUID, startRect: CGRect, handle: RectHandle, touchStart: CGPoint)
        case creatingRect(startNorm: CGPoint)
        case movingRuler(startY: CGFloat, touchStartY: CGFloat)
    }

    private enum RectHandle {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        isMultipleTouchEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Hit Testing

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if pageAnnotations.isLocked { return nil }

        // Ruler drag: always allow if touch is near the ruler line
        if let rulerY = pageAnnotations.rulerPositionY {
            let actualY = contentRect.origin.y + rulerY * contentRect.height
            if abs(point.y - actualY) < 22 {
                return self
            }
        }

        if activeTool != .none { return self }
        return nil
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let cr = contentRect
        guard cr.width > 0, cr.height > 0 else { return }

        // Clip annotations to content rect so they don't appear in letterbox areas
        ctx.saveGState()
        ctx.addRect(cr)
        ctx.clip()

        // 1. Draw completed freehand paths + eraser in a transparency layer
        ctx.beginTransparencyLayer(auxiliaryInfo: nil)
        for path in pageAnnotations.drawings {
            guard path.points.count >= 2 else { continue }

            let bezier = UIBezierPath()
            bezier.move(to: toPixel(path.points[0]))
            for i in 1..<path.points.count {
                bezier.addLine(to: toPixel(path.points[i]))
            }
            bezier.lineWidth = path.lineWidth
            bezier.lineCapStyle = .round
            bezier.lineJoinStyle = .round

            if path.isEraser {
                ctx.setBlendMode(.clear)
            } else {
                ctx.setBlendMode(.normal)
                UIColor(hex: path.colorHex).setStroke()
            }
            bezier.stroke()
        }

        // 2. Draw in-progress path
        if !currentPath.isEmpty, currentPath.count >= 2 {
            let bezier = UIBezierPath()
            bezier.move(to: toPixel(currentPath[0]))
            for i in 1..<currentPath.count {
                bezier.addLine(to: toPixel(currentPath[i]))
            }
            bezier.lineWidth = isCurrentPathEraser ? max(currentDrawLineWidth * 3, 12) : currentDrawLineWidth
            bezier.lineCapStyle = .round
            bezier.lineJoinStyle = .round

            if isCurrentPathEraser {
                ctx.setBlendMode(.clear)
            } else {
                ctx.setBlendMode(.normal)
                UIColor(hex: currentDrawColor).setStroke()
            }
            bezier.stroke()
        }
        ctx.setBlendMode(.normal)
        ctx.endTransparencyLayer()

        // 3. Draw rectangles
        for rectAnn in pageAnnotations.rectangles {
            let color = UIColor(hex: rectAnn.colorHex).withAlphaComponent(rectAnn.opacity)
            let r = CGRect(
                x: cr.origin.x + rectAnn.origin.x * cr.width,
                y: cr.origin.y + rectAnn.origin.y * cr.height,
                width: rectAnn.size.width * cr.width,
                height: rectAnn.size.height * cr.height
            )
            color.setFill()
            ctx.fill(r)

            // Border
            UIColor(hex: rectAnn.colorHex).withAlphaComponent(0.8).setStroke()
            ctx.setLineWidth(2)
            ctx.stroke(r)

            // Resize handles when not locked
            if activeTool == .rectangle && !pageAnnotations.isLocked {
                let handleSize: CGFloat = 10
                UIColor(hex: rectAnn.colorHex).setFill()
                for corner in corners(of: r) {
                    let handleRect = CGRect(x: corner.x - handleSize/2, y: corner.y - handleSize/2, width: handleSize, height: handleSize)
                    ctx.fill(handleRect)
                }
            }
        }

        // 4. Draw in-progress rect creation
        if case .creatingRect(let startNorm) = dragState, let endPoint = currentPath.last {
            let startPx = toPixel(startNorm)
            let endPx = toPixel(endPoint)
            let color = UIColor(hex: currentDrawColor).withAlphaComponent(0.25)
            let r = CGRect(
                x: min(startPx.x, endPx.x),
                y: min(startPx.y, endPx.y),
                width: abs(endPx.x - startPx.x),
                height: abs(endPx.y - startPx.y)
            )
            color.setFill()
            ctx.fill(r)
            UIColor(hex: currentDrawColor).withAlphaComponent(0.8).setStroke()
            ctx.setLineWidth(2)
            ctx.stroke(r)
        }

        ctx.restoreGState() // Remove content-rect clip

        // 5. Ruler — spans full view width, positioned using content Y
        if let rulerY = pageAnnotations.rulerPositionY {
            let actualY = cr.origin.y + rulerY * cr.height
            let w = bounds.width

            // Semi-transparent black below
            ctx.setFillColor(UIColor.black.withAlphaComponent(0.3).cgColor)
            ctx.fill(CGRect(x: 0, y: actualY + 2, width: w, height: bounds.height - actualY - 2))

            // Thick ruler line
            let rulerColor = UIColor(red: 0.42, green: 0.32, blue: 0.64, alpha: 0.9)
            ctx.setStrokeColor(rulerColor.cgColor)
            ctx.setLineWidth(4)
            ctx.move(to: CGPoint(x: 0, y: actualY))
            ctx.addLine(to: CGPoint(x: w, y: actualY))
            ctx.strokePath()

            // Small edge indicators
            let indicatorSize: CGFloat = 6
            let leftDot = CGRect(x: 4, y: actualY - indicatorSize / 2, width: indicatorSize, height: indicatorSize)
            let rightDot = CGRect(x: w - indicatorSize - 4, y: actualY - indicatorSize / 2, width: indicatorSize, height: indicatorSize)
            rulerColor.withAlphaComponent(0.7).setFill()
            UIBezierPath(ovalIn: leftDot).fill()
            UIBezierPath(ovalIn: rightDot).fill()
        }
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        let cr = contentRect
        guard cr.width > 0, cr.height > 0 else { return }
        let norm = toNorm(point)

        // Check ruler drag first
        if let rulerY = pageAnnotations.rulerPositionY, !pageAnnotations.isLocked {
            let actualY = cr.origin.y + rulerY * cr.height
            if abs(point.y - actualY) < 22 {
                dragState = .movingRuler(startY: rulerY, touchStartY: point.y)
                return
            }
        }

        switch activeTool {
        case .draw:
            currentPath = [norm]
            isCurrentPathEraser = false
            dragState = .drawingPath

        case .eraser:
            currentPath = [norm]
            isCurrentPathEraser = true
            dragState = .drawingPath

        case .rectangle:
            if let (id, handle) = hitRectHandle(at: point) {
                let rectAnn = pageAnnotations.rectangles.first { $0.id == id }!
                let r = CGRect(
                    x: cr.origin.x + rectAnn.origin.x * cr.width,
                    y: cr.origin.y + rectAnn.origin.y * cr.height,
                    width: rectAnn.size.width * cr.width,
                    height: rectAnn.size.height * cr.height
                )
                dragState = .resizingRect(id: id, startRect: r, handle: handle, touchStart: point)
            } else if let id = hitRectBody(at: point) {
                let rectAnn = pageAnnotations.rectangles.first { $0.id == id }!
                dragState = .movingRect(id: id, startOrigin: rectAnn.origin, touchStart: point)
            } else {
                dragState = .creatingRect(startNorm: norm)
                currentPath = [norm]
            }

        case .ruler:
            if pageAnnotations.rulerPositionY == nil {
                pageAnnotations.rulerPositionY = norm.y
                dragState = .movingRuler(startY: norm.y, touchStartY: point.y)
                setNeedsDisplay()
            }

        case .none:
            break
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        let cr = contentRect
        guard cr.width > 0, cr.height > 0 else { return }
        let norm = toNorm(point)

        switch dragState {
        case .drawingPath:
            currentPath.append(norm)
            setNeedsDisplay()

        case .movingRect(let id, let startOrigin, let touchStart):
            let dx = (point.x - touchStart.x) / cr.width
            let dy = (point.y - touchStart.y) / cr.height
            if let idx = pageAnnotations.rectangles.firstIndex(where: { $0.id == id }) {
                pageAnnotations.rectangles[idx].origin = CGPoint(
                    x: max(0, min(1 - pageAnnotations.rectangles[idx].size.width, startOrigin.x + dx)),
                    y: max(0, min(1 - pageAnnotations.rectangles[idx].size.height, startOrigin.y + dy))
                )
                setNeedsDisplay()
            }

        case .resizingRect(let id, let startRect, let handle, let touchStart):
            let dx = point.x - touchStart.x
            let dy = point.y - touchStart.y
            if let idx = pageAnnotations.rectangles.firstIndex(where: { $0.id == id }) {
                let newRect = resizedRect(startRect, handle: handle, dx: dx, dy: dy)
                pageAnnotations.rectangles[idx].origin = CGPoint(
                    x: (newRect.minX - cr.origin.x) / cr.width,
                    y: (newRect.minY - cr.origin.y) / cr.height
                )
                pageAnnotations.rectangles[idx].size = CGSize(
                    width: newRect.width / cr.width,
                    height: newRect.height / cr.height
                )
                setNeedsDisplay()
            }

        case .creatingRect:
            currentPath = [currentPath.first ?? norm, norm]
            setNeedsDisplay()

        case .movingRuler(let startY, let touchStartY):
            let dy = (point.y - touchStartY) / cr.height
            let newY = max(0, min(1, startY + dy))
            pageAnnotations.rulerPositionY = newY
            setNeedsDisplay()

        case .none:
            break
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        finishTouch(touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        finishTouch(touches)
    }

    private func finishTouch(_ touches: Set<UITouch>) {
        guard let touch = touches.first else {
            dragState = nil
            return
        }
        let point = touch.location(in: self)

        switch dragState {
        case .drawingPath:
            if currentPath.count >= 2 {
                let path = DrawingPath(
                    points: simplifyPath(currentPath),
                    colorHex: currentDrawColor,
                    lineWidth: isCurrentPathEraser ? max(currentDrawLineWidth * 3, 12) : currentDrawLineWidth,
                    isEraser: isCurrentPathEraser
                )
                pageAnnotations.drawings.append(path)
            }
            currentPath = []
            isCurrentPathEraser = false

        case .creatingRect(let startNorm):
            let endNorm = toNorm(point)
            let minSize: CGFloat = 0.02
            let rectWidth = abs(endNorm.x - startNorm.x)
            let rectHeight = abs(endNorm.y - startNorm.y)
            if rectWidth > minSize && rectHeight > minSize {
                let rect = RectAnnotation(
                    origin: CGPoint(x: min(startNorm.x, endNorm.x), y: min(startNorm.y, endNorm.y)),
                    size: CGSize(width: rectWidth, height: rectHeight),
                    colorHex: currentDrawColor,
                    opacity: 0.25
                )
                pageAnnotations.rectangles.append(rect)
            }
            currentPath = []

        case .movingRect, .resizingRect, .movingRuler:
            break

        case .none:
            break
        }

        dragState = nil
        setNeedsDisplay()
        onAnnotationsChanged?(pageAnnotations)
    }

    // MARK: - Rect hit detection

    private func hitRectHandle(at point: CGPoint) -> (UUID, RectHandle)? {
        let cr = contentRect
        let tolerance: CGFloat = 20

        for rectAnn in pageAnnotations.rectangles.reversed() {
            let r = CGRect(
                x: cr.origin.x + rectAnn.origin.x * cr.width,
                y: cr.origin.y + rectAnn.origin.y * cr.height,
                width: rectAnn.size.width * cr.width,
                height: rectAnn.size.height * cr.height
            )
            let handles: [(CGPoint, RectHandle)] = [
                (CGPoint(x: r.minX, y: r.minY), .topLeft),
                (CGPoint(x: r.maxX, y: r.minY), .topRight),
                (CGPoint(x: r.minX, y: r.maxY), .bottomLeft),
                (CGPoint(x: r.maxX, y: r.maxY), .bottomRight),
            ]
            for (corner, handle) in handles {
                if hypot(point.x - corner.x, point.y - corner.y) < tolerance {
                    return (rectAnn.id, handle)
                }
            }
        }
        return nil
    }

    private func hitRectBody(at point: CGPoint) -> UUID? {
        let cr = contentRect

        for rectAnn in pageAnnotations.rectangles.reversed() {
            let r = CGRect(
                x: cr.origin.x + rectAnn.origin.x * cr.width,
                y: cr.origin.y + rectAnn.origin.y * cr.height,
                width: rectAnn.size.width * cr.width,
                height: rectAnn.size.height * cr.height
            )
            if r.contains(point) {
                return rectAnn.id
            }
        }
        return nil
    }

    private func corners(of rect: CGRect) -> [CGPoint] {
        [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY),
        ]
    }

    private func resizedRect(_ startRect: CGRect, handle: RectHandle, dx: CGFloat, dy: CGFloat) -> CGRect {
        var r = startRect
        let minDim: CGFloat = 20
        switch handle {
        case .topLeft:
            r.origin.x += dx
            r.origin.y += dy
            r.size.width -= dx
            r.size.height -= dy
        case .topRight:
            r.size.width += dx
            r.origin.y += dy
            r.size.height -= dy
        case .bottomLeft:
            r.origin.x += dx
            r.size.width -= dx
            r.size.height += dy
        case .bottomRight:
            r.size.width += dx
            r.size.height += dy
        }
        if r.size.width < minDim { r.size.width = minDim }
        if r.size.height < minDim { r.size.height = minDim }
        return r
    }

    // MARK: - Path simplification (Ramer-Douglas-Peucker)

    private func simplifyPath(_ points: [CGPoint], epsilon: CGFloat = 0.002) -> [CGPoint] {
        guard points.count > 2 else { return points }
        return rdpSimplify(points, epsilon: epsilon)
    }

    private func rdpSimplify(_ points: [CGPoint], epsilon: CGFloat) -> [CGPoint] {
        guard points.count > 2 else { return points }

        var maxDist: CGFloat = 0
        var maxIdx = 0
        let first = points.first!
        let last = points.last!

        for i in 1..<(points.count - 1) {
            let d = perpendicularDistance(point: points[i], lineStart: first, lineEnd: last)
            if d > maxDist {
                maxDist = d
                maxIdx = i
            }
        }

        if maxDist > epsilon {
            let left = rdpSimplify(Array(points[0...maxIdx]), epsilon: epsilon)
            let right = rdpSimplify(Array(points[maxIdx...]), epsilon: epsilon)
            return left.dropLast() + right
        } else {
            return [first, last]
        }
    }

    private func perpendicularDistance(point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> CGFloat {
        let dx = lineEnd.x - lineStart.x
        let dy = lineEnd.y - lineStart.y
        let lenSq = dx * dx + dy * dy
        if lenSq == 0 { return hypot(point.x - lineStart.x, point.y - lineStart.y) }
        let num = abs(dy * point.x - dx * point.y + lineEnd.x * lineStart.y - lineEnd.y * lineStart.x)
        return num / sqrt(lenSq)
    }
}
