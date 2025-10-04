//
//  DeviceInfo.swift
//  KnitAndCalc
//
//  Device detection and PPI lookup
//

import UIKit

struct DeviceInfo {
    let modelIdentifier: String
    let ppi: Int?

    static func current() -> DeviceInfo {
        let modelIdentifier = getModelIdentifier()
        let ppi = lookupPPI(for: modelIdentifier)

        print("=== Device Info Debug ===")
        print("Model Identifier: \(modelIdentifier)")
        if let ppi = ppi {
            print("PPI Found: \(ppi)")
        } else {
            print("⚠️ PPI NOT FOUND - Using fallback")
        }
        print("========================")

        return DeviceInfo(modelIdentifier: modelIdentifier, ppi: ppi)
    }

    private static func getModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    private static func lookupPPI(for model: String) -> Int? {
        // Device PPI database
        let ppiDatabase: [String: Int] = [
            // iPads - 264 PPI
            "iPad6,11": 264, "iPad6,12": 264, // iPad (6th gen)
            "iPad8,1": 264, "iPad8,2": 264, "iPad8,3": 264, "iPad8,4": 264, // iPad Pro 11" (1st gen)
            "iPad8,5": 264, "iPad8,6": 264, "iPad8,7": 264, "iPad8,8": 264, // iPad Pro 12.9" (3rd gen)
            "iPad7,11": 264, "iPad7,12": 264, // iPad (7th gen)
            "iPad11,3": 264, "iPad11,4": 264, // iPad Air (3rd gen)
            "iPad11,6": 326, "iPad11,7": 326, // iPad mini (5th gen)
            "iPad11,1": 264, "iPad11,2": 264, // iPad (8th gen)
            "iPad13,1": 264, "iPad13,2": 264, // iPad Air (4th gen)
            "iPad8,9": 264, "iPad8,10": 264, // iPad Pro 11" (2nd gen)
            "iPad8,11": 264, "iPad8,12": 264, // iPad Pro 12.9" (4th gen)
            "iPad12,1": 264, "iPad12,2": 264, // iPad (9th gen)
            "iPad13,4": 264, "iPad13,5": 264, "iPad13,6": 264, "iPad13,7": 264, // iPad Pro 11" (3rd gen)
            "iPad13,8": 264, "iPad13,9": 264, "iPad13,10": 264, "iPad13,11": 264, // iPad Pro 12.9" (5th gen)
            "iPad14,1": 326, "iPad14,2": 326, // iPad mini (6th gen)
            "iPad13,16": 264, "iPad13,17": 264, // iPad (10th gen)
            "iPad13,18": 264, "iPad13,19": 264, // iPad Air (5th gen)
            "iPad14,3": 264, "iPad14,4": 264, // iPad Pro 11" (4th gen)
            "iPad14,5": 264, "iPad14,6": 264, // iPad Pro 12.9" (6th gen)
            "iPad14,8": 264, "iPad14,9": 264, // iPad Air 11" (6th gen)
            "iPad14,10": 264, "iPad14,11": 264, // iPad Air 13" (6th gen)
            "iPad16,3": 264, "iPad16,4": 264, // iPad Pro 11" (7th gen)
            "iPad16,5": 264, "iPad16,6": 264, // iPad Pro 13" (7th gen)
            "iPad16,1": 326, "iPad16,2": 326, // iPad mini (7th gen)

            // iPhones - 326 PPI
            "iPhone10,1": 326, "iPhone10,4": 326, // iPhone 8
            "iPhone10,2": 401, "iPhone10,5": 401, // iPhone 8 Plus
            "iPhone10,3": 458, "iPhone10,6": 458, // iPhone X
            "iPhone11,8": 326, // iPhone XR
            "iPhone11,2": 458, // iPhone XS
            "iPhone11,4": 458, "iPhone11,6": 458, // iPhone XS Max
            "iPhone12,1": 326, // iPhone 11
            "iPhone12,3": 458, // iPhone 11 Pro
            "iPhone12,5": 458, // iPhone 11 Pro Max
            "iPhone13,2": 460, // iPhone 12
            "iPhone13,3": 460, // iPhone 12 Pro
            "iPhone13,4": 458, // iPhone 12 Pro Max
            "iPhone13,1": 476, // iPhone 12 mini
            "iPhone12,8": 326, // iPhone SE (2nd gen)
            "iPhone14,5": 460, // iPhone 13
            "iPhone14,2": 460, // iPhone 13 Pro
            "iPhone14,3": 458, // iPhone 13 Pro Max
            "iPhone14,4": 476, // iPhone 13 mini
            "iPhone14,7": 460, // iPhone 14
            "iPhone14,8": 458, // iPhone 14 Plus
            "iPhone15,2": 460, // iPhone 14 Pro
            "iPhone15,3": 460, // iPhone 14 Pro Max
            "iPhone14,6": 326, // iPhone SE (3rd gen)
            "iPhone15,4": 460, // iPhone 15
            "iPhone15,5": 460, // iPhone 15 Plus
            "iPhone16,1": 460, // iPhone 15 Pro
            "iPhone16,2": 460, // iPhone 15 Pro Max
            "iPhone17,3": 460, // iPhone 16
            "iPhone17,4": 460, // iPhone 16 Plus
            "iPhone17,1": 460, // iPhone 16 Pro
            "iPhone17,2": 460, // iPhone 16 Pro Max
        ]

        return ppiDatabase[model]
    }
}