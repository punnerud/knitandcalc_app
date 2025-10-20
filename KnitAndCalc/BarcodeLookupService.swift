//
//  BarcodeLookupService.swift
//  KnitAndCalc
//
//  GS1 barcode lookup service with caching
//

import Foundation

// GS1 API Response Model
struct GS1BarcodeResponse: Codable {
    let ProductDataAvailable: Bool?
    let data: GS1ProductData?
}

struct GS1ProductData: Codable {
    let gtin: String?
    let companyName: String?
    let brandName: String?
    let productDescription: String?
    let productName: String?
    let licenceKey: String?
    let formattedAddress: String?
}

// Cached barcode info
struct CachedBarcodeInfo {
    let barcode: String
    let companyName: String
    let brandName: String?
    let productName: String?
    let timestamp: Date
}

class BarcodeLookupService {
    static let shared = BarcodeLookupService()

    private var cache: [String: CachedBarcodeInfo] = [:]
    private var cacheOrder: [String] = []
    private let maxCacheSize = 100
    private let apiBaseURL = "https://gs1.org.sa/api/foreignGtin/getGtinProductDetails"

    private init() {}

    // Validate barcode format (EAN-8, EAN-13, UPC, etc.)
    func isValidBarcode(_ barcode: String) -> Bool {
        // Remove any whitespace
        let cleaned = barcode.trimmingCharacters(in: .whitespaces)

        // Check if it's numeric and has valid length
        guard cleaned.allSatisfy({ $0.isNumber }) else { return false }

        // Common barcode lengths: EAN-8 (8), EAN-13 (13), UPC-A (12), UPC-E (8)
        let validLengths = [8, 12, 13, 14]
        return validLengths.contains(cleaned.count)
    }

    // Get cached info or lookup
    func lookupBarcode(_ barcode: String, completion: @escaping (CachedBarcodeInfo?) -> Void) {
        // Check validation
        guard isValidBarcode(barcode) else {
            completion(nil)
            return
        }

        // Check cache first
        if let cached = cache[barcode] {
            // Check if cache is still fresh (less than 30 days old)
            if Date().timeIntervalSince(cached.timestamp) < 30 * 24 * 60 * 60 {
                completion(cached)
                return
            }
        }

        // Perform API lookup
        performAPILookup(barcode, completion: completion)
    }

    private func performAPILookup(_ barcode: String, completion: @escaping (CachedBarcodeInfo?) -> Void) {
        guard let url = URL(string: "\(apiBaseURL)?barcode=\(barcode)") else {
            completion(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else {
                completion(nil)
                return
            }

            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(GS1BarcodeResponse.self, from: data)

                // Extract company name (always available according to user)
                if let productData = result.data,
                   let companyName = productData.companyName,
                   !companyName.isEmpty {

                    let cachedInfo = CachedBarcodeInfo(
                        barcode: barcode,
                        companyName: companyName,
                        brandName: productData.brandName,
                        productName: productData.productName ?? productData.productDescription,
                        timestamp: Date()
                    )

                    // Store in cache
                    DispatchQueue.main.async {
                        self.addToCache(cachedInfo)
                        completion(cachedInfo)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            } catch {
                print("Barcode lookup error: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }

        task.resume()
    }

    private func addToCache(_ info: CachedBarcodeInfo) {
        // Add to cache
        cache[info.barcode] = info

        // Update order
        if let existingIndex = cacheOrder.firstIndex(of: info.barcode) {
            cacheOrder.remove(at: existingIndex)
        }
        cacheOrder.append(info.barcode)

        // Trim cache if needed
        while cacheOrder.count > maxCacheSize {
            let oldestBarcode = cacheOrder.removeFirst()
            cache.removeValue(forKey: oldestBarcode)
        }
    }

    // Get cached info synchronously (doesn't trigger lookup)
    func getCachedInfo(_ barcode: String) -> CachedBarcodeInfo? {
        return cache[barcode]
    }

    // Clear cache
    func clearCache() {
        cache.removeAll()
        cacheOrder.removeAll()
    }
}
