//
//  NotificationManager.swift
//  KnitAndCalc
//
//  Notification manager for app engagement reminders
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private let lastOpenKey = "lastAppOpenDate"
    private let notificationIdentifier = "appEngagementReminder"

    private init() {}

    // Request notification permission
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    // Update last open date when app is opened
    func updateLastOpenDate() {
        UserDefaults.standard.set(Date(), forKey: lastOpenKey)
        // Cancel any pending notifications since the app is now opened
        cancelScheduledNotifications()
    }

    // Check notification authorization status
    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }

    // Schedule notification if needed (check if more than 3 days since last open)
    func scheduleNotificationIfNeeded() {
        // Only for Norwegian users
        guard AppSettings.shared.currentLanguage == .norwegian else {
            return
        }

        // Check if notifications are enabled
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else {
            return
        }

        // Check permission status before scheduling
        checkAuthorizationStatus { authorized in
            guard authorized else { return }

            // Schedule notification for 3 days from now
            self.scheduleNotification()
        }
    }

    private func scheduleNotification() {
        // Cancel any existing notifications
        cancelScheduledNotifications()

        // Load data for personalized messages
        let projects = loadProjects()
        let yarnStash = loadYarnStash()

        let activeProjectsCount = projects.filter { $0.status == .active || $0.status == .planned }.count
        let totalGrams = yarnStash.reduce(0.0) { sum, yarn in
            sum + (Double(yarn.numberOfSkeins) * yarn.weightPerSkein)
        }

        // Get random notification text
        let notificationText = getRandomNotificationText(activeProjects: activeProjectsCount, totalGrams: Int(totalGrams))

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "KnitAndCalc"
        content.body = notificationText
        content.sound = .default

        // Trigger after 3 days (259200 seconds)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 259200, repeats: false)

        // Create request
        let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)

        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    private func cancelScheduledNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
    }

    // Load projects
    private func loadProjects() -> [Project] {
        return DataPersistenceManager.shared.load([Project].self, forKey: .projects) ?? []
    }

    // Load yarn stash
    private func loadYarnStash() -> [YarnStashEntry] {
        return DataPersistenceManager.shared.load([YarnStashEntry].self, forKey: .yarnStash) ?? []
    }

    // Get random notification text from 10 variations
    private func getRandomNotificationText(activeProjects: Int, totalGrams: Int) -> String {
        let notifications = [
            "Du har \(activeProjects) \(activeProjects == 1 ? "prosjekt" : "prosjekter") som venter på deg! 🧶",
            "Det er \(totalGrams)g garn i lageret ditt som vil bli strikket! ✨",
            "Husk å oppdatere prosjektene dine i KnitAndCalc! 📝",
            "Strikkingen venter! Du har \(activeProjects) aktive \(activeProjects == 1 ? "prosjekt" : "prosjekter") 🎨",
            "Tid for litt strikking? Sjekk ut garnlageret ditt! 🧵",
            "Har du gjort fremgang på prosjektene dine? Oppdater nå! 💫",
            "Ditt garnlager har \(totalGrams)g med muligheter! 🌟",
            "Ikke glem strikkingen! Åpne KnitAndCalc og se hva du har på gang 🎁",
            "Klart for neste rad? Du har \(activeProjects) \(activeProjects == 1 ? "prosjekt" : "prosjekter") å velge mellom! 🪡",
            "Strikkegleden venter! Sjekk inn og se fremgangen din 🎉"
        ]

        return notifications.randomElement() ?? notifications[0]
    }
}
