//
//  AppDelegate.swift
//  SmartScrapper
//
//  Created by Raeva Desai on 8/2/24.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()
        
        requestNotificationPermission()
        
        return true
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                self.scheduleDailyNotification()
            } else {
                print("Notification permission denied.")
            }
        }
    }

    private func scheduleDailyNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Time to Capture!"
        content.body = "Take a photo of your waste today and maintain your streak!"
        content.sound = UNNotificationSound.default

        let randomHour = Int.random(in: 9...21)
        let randomMinute = Int.random(in: 0...59)
        var dateComponents = DateComponents()
        dateComponents.hour = randomHour
        dateComponents.minute = randomMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyNotification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}
