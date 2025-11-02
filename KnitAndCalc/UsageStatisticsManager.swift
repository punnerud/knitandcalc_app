//
//  UsageStatisticsManager.swift
//  KnitAndCalc
//
//  Tracks usage statistics for app features
//

import Foundation

class UsageStatisticsManager {
    static let shared = UsageStatisticsManager()

    // UserDefaults keys for tracking feature usage
    private let projectsCountKey = "UsageStats_ProjectsCount"
    private let recipesCountKey = "UsageStats_RecipesCount"

    private let projectsOpenCountKey = "UsageStats_ProjectsOpenCount"
    private let yarnStashOpenCountKey = "UsageStats_YarnStashOpenCount"
    private let recipesOpenCountKey = "UsageStats_RecipesOpenCount"
    private let yarnCalculatorOpenCountKey = "UsageStats_YarnCalculatorOpenCount"
    private let stitchCalculatorOpenCountKey = "UsageStats_StitchCalculatorOpenCount"
    private let rulerOpenCountKey = "UsageStats_RulerOpenCount"
    private let yarnStockCounterOpenCountKey = "UsageStats_YarnStockCounterOpenCount"
    private let settingsOpenCountKey = "UsageStats_SettingsOpenCount"

    private init() {}

    // MARK: - Count Tracking

    /// Updates the count of projects
    func updateProjectsCount(_ count: Int) {
        UserDefaults.standard.set(count, forKey: projectsCountKey)
    }

    /// Updates the count of recipes
    func updateRecipesCount(_ count: Int) {
        UserDefaults.standard.set(count, forKey: recipesCountKey)
    }

    // MARK: - Feature Open Tracking

    /// Records that Projects view was opened
    func recordProjectsOpen() {
        incrementCount(for: projectsOpenCountKey)
    }

    /// Records that Yarn Stash view was opened
    func recordYarnStashOpen() {
        incrementCount(for: yarnStashOpenCountKey)
    }

    /// Records that Recipes view was opened
    func recordRecipesOpen() {
        incrementCount(for: recipesOpenCountKey)
    }

    /// Records that Yarn Calculator view was opened
    func recordYarnCalculatorOpen() {
        incrementCount(for: yarnCalculatorOpenCountKey)
    }

    /// Records that Stitch Calculator view was opened
    func recordStitchCalculatorOpen() {
        incrementCount(for: stitchCalculatorOpenCountKey)
    }

    /// Records that Ruler view was opened
    func recordRulerOpen() {
        incrementCount(for: rulerOpenCountKey)
    }

    /// Records that Yarn Stock Counter view was opened
    func recordYarnStockCounterOpen() {
        incrementCount(for: yarnStockCounterOpenCountKey)
    }

    /// Records that Settings view was opened
    func recordSettingsOpen() {
        incrementCount(for: settingsOpenCountKey)
    }

    // MARK: - Data Retrieval

    /// Gets all usage statistics as a dictionary
    func getStatistics() -> [String: Any] {
        return [
            "projectsCount": UserDefaults.standard.integer(forKey: projectsCountKey),
            "recipesCount": UserDefaults.standard.integer(forKey: recipesCountKey),
            "projectsOpenCount": UserDefaults.standard.integer(forKey: projectsOpenCountKey),
            "yarnStashOpenCount": UserDefaults.standard.integer(forKey: yarnStashOpenCountKey),
            "recipesOpenCount": UserDefaults.standard.integer(forKey: recipesOpenCountKey),
            "yarnCalculatorOpenCount": UserDefaults.standard.integer(forKey: yarnCalculatorOpenCountKey),
            "stitchCalculatorOpenCount": UserDefaults.standard.integer(forKey: stitchCalculatorOpenCountKey),
            "rulerOpenCount": UserDefaults.standard.integer(forKey: rulerOpenCountKey),
            "yarnStockCounterOpenCount": UserDefaults.standard.integer(forKey: yarnStockCounterOpenCountKey),
            "settingsOpenCount": UserDefaults.standard.integer(forKey: settingsOpenCountKey)
        ]
    }

    // MARK: - Private Helpers

    private func incrementCount(for key: String) {
        let currentCount = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(currentCount + 1, forKey: key)
    }

    // MARK: - Debug Methods

    /// Resets all usage statistics (for debugging)
    func resetStatistics() {
        UserDefaults.standard.removeObject(forKey: projectsCountKey)
        UserDefaults.standard.removeObject(forKey: recipesCountKey)
        UserDefaults.standard.removeObject(forKey: projectsOpenCountKey)
        UserDefaults.standard.removeObject(forKey: yarnStashOpenCountKey)
        UserDefaults.standard.removeObject(forKey: recipesOpenCountKey)
        UserDefaults.standard.removeObject(forKey: yarnCalculatorOpenCountKey)
        UserDefaults.standard.removeObject(forKey: stitchCalculatorOpenCountKey)
        UserDefaults.standard.removeObject(forKey: rulerOpenCountKey)
        UserDefaults.standard.removeObject(forKey: yarnStockCounterOpenCountKey)
        UserDefaults.standard.removeObject(forKey: settingsOpenCountKey)
        print("UsageStatistics: All statistics reset")
    }

    /// Prints current statistics (for debugging)
    func printStatistics() {
        let stats = getStatistics()
        print("UsageStatistics:")
        print("  Projects Count: \(stats["projectsCount"] ?? 0)")
        print("  Recipes Count: \(stats["recipesCount"] ?? 0)")
        print("  Projects Opens: \(stats["projectsOpenCount"] ?? 0)")
        print("  Yarn Stash Opens: \(stats["yarnStashOpenCount"] ?? 0)")
        print("  Recipes Opens: \(stats["recipesOpenCount"] ?? 0)")
        print("  Yarn Calculator Opens: \(stats["yarnCalculatorOpenCount"] ?? 0)")
        print("  Stitch Calculator Opens: \(stats["stitchCalculatorOpenCount"] ?? 0)")
        print("  Ruler Opens: \(stats["rulerOpenCount"] ?? 0)")
        print("  Yarn Stock Counter Opens: \(stats["yarnStockCounterOpenCount"] ?? 0)")
        print("  Settings Opens: \(stats["settingsOpenCount"] ?? 0)")
    }
}
