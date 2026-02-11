//
//  AnnotationModels.swift
//  KnitAndCalc
//
//  Data models and persistence for recipe annotations
//

import UIKit
import SwiftUI

// MARK: - Tool enum

enum AnnotationTool: String, Codable {
    case none
    case draw
    case eraser
    case rectangle
    case ruler
}

// MARK: - Drawing path

struct DrawingPath: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var points: [CGPoint] = []
    var colorHex: String = "FF0000"
    var lineWidth: CGFloat = 3.0
    var isEraser: Bool = false
}

// MARK: - Rectangle annotation

struct RectAnnotation: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var origin: CGPoint = .zero
    var size: CGSize = .zero
    var colorHex: String = "0000FF"
    var opacity: CGFloat = 0.25
}

// MARK: - Page annotations

struct PageAnnotations: Codable, Equatable {
    var drawings: [DrawingPath] = []
    var rectangles: [RectAnnotation] = []
    var rulerPositionY: CGFloat? = nil
    var isLocked: Bool = false
}

// MARK: - Rotation transform

extension PageAnnotations {
    /// Returns a copy with all annotation coordinates rotated 90° clockwise
    /// in normalized (0-1) coordinate space.
    func rotatedCW90() -> PageAnnotations {
        var result = PageAnnotations()
        result.isLocked = isLocked
        // Ruler is horizontal-only — remove on rotation since it can't represent a vertical line
        result.rulerPositionY = nil

        result.drawings = drawings.map { path in
            var p = path
            p.points = path.points.map { CGPoint(x: 1 - $0.y, y: $0.x) }
            return p
        }

        result.rectangles = rectangles.map { rect in
            var r = rect
            r.origin = CGPoint(x: 1 - rect.origin.y - rect.size.height, y: rect.origin.x)
            r.size = CGSize(width: rect.size.height, height: rect.size.width)
            return r
        }

        return result
    }
}

// MARK: - Recipe annotations container

struct RecipeAnnotations: Codable, Equatable {
    var pages: [String: PageAnnotations] = [:]
    var savedRotation: Int = 0

    init(pages: [String: PageAnnotations] = [:], savedRotation: Int = 0) {
        self.pages = pages
        self.savedRotation = savedRotation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pages = try container.decode([String: PageAnnotations].self, forKey: .pages)
        savedRotation = try container.decodeIfPresent(Int.self, forKey: .savedRotation) ?? 0
    }
}

// MARK: - Persistence

class AnnotationPersistenceManager {
    static let shared = AnnotationPersistenceManager()
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    private func fileURL(for recipeId: UUID) -> URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("annotations_\(recipeId.uuidString).json")
    }

    func load(for recipeId: UUID) -> RecipeAnnotations {
        let url = fileURL(for: recipeId)
        guard let data = try? Data(contentsOf: url),
              let annotations = try? decoder.decode(RecipeAnnotations.self, from: data) else {
            return RecipeAnnotations()
        }
        return annotations
    }

    func save(_ annotations: RecipeAnnotations, for recipeId: UUID) {
        let url = fileURL(for: recipeId)
        guard let data = try? encoder.encode(annotations) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func delete(for recipeId: UUID) {
        let url = fileURL(for: recipeId)
        try? fileManager.removeItem(at: url)
    }
}

// MARK: - Color hex utilities

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (255, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
    }
}

// Color(hex:) extension is in ThemeColors.swift
