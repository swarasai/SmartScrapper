//
//  ViewController.swift
//  SmartScrapper
//
//  Created by Raeva Desai on 8/2/24.
//

import UIKit
import SwiftUI
import UserNotifications
import CoreML

class ViewController: UIViewController {

    private let resultLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont(name: "AvenirNext-Bold", size: 20)
        label.numberOfLines = 0
        label.textColor = .black
        label.text = ""
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Back", for: .normal)
        button.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 18)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    private var splashScreenHostingController: UIHostingController<SplashScreenView>?
    private var photoCaptureHostingController: UIHostingController<PhotoCaptureView>?
    private var loginHostingController: UIHostingController<LoginView>?
    
    private var notificationReceivedDate: Date?
    
    private var streakCount: Int {
        return StreakManager.getCurrentStreak()
    }

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestNotificationPermissions()
        scheduleDailyNotification()
        showSplashScreen()
        view.addSubview(resultLabel)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let labelHeight: CGFloat = 300
        resultLabel.frame = CGRect(
            x: 20,
            y: (view.frame.size.height - labelHeight) / 2 - 20,
            width: view.frame.size.width - 40,
            height: labelHeight
        )

        if !backButton.isHidden {
            let buttonHeight: CGFloat = 44
            backButton.frame = CGRect(
                x: (view.frame.size.width - 100) / 2,
                y: resultLabel.frame.maxY + 20,
                width: 100,
                height: buttonHeight
            )
        }
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notifications permissions: \(error.localizedDescription)")
            }
            if granted {
                print("Notification permissions granted.")
            } else {
                print("Notification permissions denied.")
            }
        }
    }

    private func scheduleDailyNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyReminder"]) // Remove any existing notifications with the same identifier
        
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = "Don't forget to take a photo of your waste today!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 10
        dateComponents.minute = 53
        dateComponents.timeZone = TimeZone(abbreviation: "PST") // Set the timezone if needed
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled for 10:06 AM daily.")
            }
        }
    }

    private func handleNotificationReceived() {
        notificationReceivedDate = Date()
        
        let content = UNMutableNotificationContent()
        content.title = "Congrats!"
        content.body = "You took a photo within 2 minutes of the reminder!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 120, repeats: false)
        let request = UNNotificationRequest(identifier: "congratsNotification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling congratulatory notification: \(error.localizedDescription)")
            }
        }
    }

    private func checkPhotoTakenWithin2Minutes() {
        guard let notificationDate = notificationReceivedDate else { return }
        let now = Date()
        let timeInterval = now.timeIntervalSince(notificationDate)
        
        if timeInterval <= 120 {
            handleNotificationReceived()
        }
    }

    private func showSplashScreen() {
        let splashScreenView = SplashScreenView(onLogin: { [weak self] in
            self?.navigateToLogin()
        }, streakCount: streakCount)
        
        splashScreenHostingController = UIHostingController(rootView: splashScreenView)
        
        if let hostingController = splashScreenHostingController {
            addChild(hostingController)
            hostingController.view.frame = view.bounds
            view.addSubview(hostingController.view)
            hostingController.didMove(toParent: self)
        }
    }

    private func navigateToLogin() {
        let loginView = LoginView(onLogin: { [weak self] in
            self?.navigateToPhotoCapture()
        }, streakCount: streakCount)
        
        splashScreenHostingController?.view.removeFromSuperview()
        splashScreenHostingController?.removeFromParent()
        
        let loginHostingController = UIHostingController(rootView: loginView)
        self.loginHostingController = loginHostingController
        
        addChild(loginHostingController)
        loginHostingController.view.frame = view.bounds
        view.addSubview(loginHostingController.view)
        loginHostingController.didMove(toParent: self)
    }

    private func navigateToPhotoCapture() {
        loginHostingController?.view.removeFromSuperview()
        loginHostingController?.removeFromParent()
        
        let photoCaptureView = PhotoCaptureView(onImageCaptured: { [weak self] image in
            DispatchQueue.global(qos: .userInitiated).async {
                self?.analyzeImage(image: image)
            }
        })
        photoCaptureHostingController = UIHostingController(rootView: photoCaptureView)
        
        if let hostingController = photoCaptureHostingController {
            present(hostingController, animated: true, completion: nil)
        }
    }
    
    private func analyzeImage(image: UIImage?) {
        guard let buffer = image?.resize(size: CGSize(width: 224, height: 224))?.getCVPixelBuffer() else {
            DispatchQueue.main.async {
                self.showResult(resultText: "Failed to process image.")
            }
            return
        }

        do {
            let config = MLModelConfiguration()
            let model = try trash_tracker_1(configuration: config)
            let input = trash_tracker_1Input(image: buffer)

            let output = try model.prediction(input: input)
            let text = output.target
            let message = self.getMessage(for: text)
            DispatchQueue.main.async {
                self.showResult(resultText: message)
            }
        } catch {
            DispatchQueue.main.async {
                self.showResult(resultText: "Error: \(error.localizedDescription)")
            }
        }
    }

    private func getMessage(for prediction: String) -> String {
        switch prediction.lowercased() {
        case "trash":
            return "Your object is trash. Dispose of this object by putting it in the trash can and leaving the trash can at your curb for the local trash services to pick it up."
        case "recycle":
            return "Your object is recycling. Dispose of this object by putting it in the recycling bin and leaving the bin at your curb for the local recycling services to pick it up. Make sure to keep the object clean and dry, separate all materials, and flatten and compress."
        case "compost":
            return "Your object is compost. You can dispose of this object by adding it to your flower and vegetable beds, window boxes, and container gardens, incorporating it into tree beds, mixing it with potting soil for indoor plants, or spreading it on top of the soil in your yard."
        default:
            return "Unknown object type."
        }
    }

    private func showResult(resultText: String) {
        // Update the streak count
        StreakManager.updateStreak()
        let currentStreak = StreakManager.getCurrentStreak()
        
        // Create an attributed string with the result text
        let fullText = "\(resultText)\n\nCurrent Streak: \(currentStreak) day(s)"
        let attributedString = NSMutableAttributedString(string: fullText)
        
        // Set the entire text to black
        attributedString.addAttribute(.foregroundColor, value: UIColor.black, range: NSRange(location: 0, length: attributedString.length))
        
        // Define the keywords and their color
        let keywords = ["trash", "recycling", "compost"]
        let highlightColor = UIColor.green
        
        // Iterate over each keyword and set its color
        for keyword in keywords {
            let range = (fullText as NSString).range(of: keyword)
            if range.location != NSNotFound {
                attributedString.addAttribute(.foregroundColor, value: highlightColor, range: range)
            }
        }
        
        // Set the attributed text to the label
        resultLabel.attributedText = attributedString

        // Add the resultLabel and backButton to the view if they are not already added
        if resultLabel.superview == nil {
            view.addSubview(resultLabel)
        }
        if backButton.superview == nil {
            view.addSubview(backButton)
        }

        // Ensure the backButton is visible
        backButton.isHidden = false

        // Layout the view components
        view.setNeedsLayout()
        view.layoutIfNeeded()

        // Check if the photo was taken within 2 minutes after the notification
        checkPhotoTakenWithin2Minutes()
    }

    @objc private func backButtonTapped() {
        resultLabel.removeFromSuperview()
        backButton.removeFromSuperview()
        navigateToLogin() // Navigate back to login view
    }
}

