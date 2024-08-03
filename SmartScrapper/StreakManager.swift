//
//  StreakManager.swift
//  SmartScrapper
//
//  Created by Raeva Desai on 8/2/24.
//

import Foundation
import UserNotifications

struct StreakManager {
    static let lastActiveDateKey = "LastActiveDate"
    static let currentStreakKey = "CurrentStreak"
    static let userDefaults = UserDefaults.standard

    // Updates the streak count based on user activity
    static func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastActiveDate = userDefaults.object(forKey: lastActiveDateKey) as? Date ?? Date.distantPast
        let currentStreak = userDefaults.integer(forKey: currentStreakKey)

        print("Today: \(today)")
        print("Last Active Date: \(lastActiveDate)")
        print("Current Streak: \(currentStreak)")

        if Calendar.current.isDateInToday(lastActiveDate) {
            // User already logged today
            print("User already logged today.")
            return
        } else if Calendar.current.isDate(today, inSameDayAs: lastActiveDate.addingTimeInterval(60 * 60 * 24)) {
            // Continue streak
            userDefaults.set(currentStreak + 1, forKey: currentStreakKey)
            print("Streak continued. New Streak: \(currentStreak + 1)")
        } else {
            // Streak reset
            userDefaults.set(1, forKey: currentStreakKey)
            print("Streak reset. New Streak: 1")
        }

        userDefaults.set(today, forKey: lastActiveDateKey)
    }

    // Retrieves the current streak count
    static func getCurrentStreak() -> Int {
        return userDefaults.integer(forKey: currentStreakKey)
    }

    // Resets the streak count to 0
    static func resetStreak() {
        userDefaults.set(0, forKey: currentStreakKey)
    }

    // Schedules a local notification for the user's streak
    static func scheduleNotification(forDate date: Date, withMessage message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Streak Update"
        content.body = message
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }

    // Call this method to request notification permissions
    static func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error.localizedDescription)")
            }
            if granted {
                print("Notification permissions granted.")
            } else {
                print("Notification permissions denied.")
            }
        }
    }
}
