import Foundation
import UserNotifications

/// Handles 401 authentication errors by sending macOS notifications
/// with per-profile rate limiting (10 minutes between notifications)
final class ReauthNotificationService {
    static let shared = ReauthNotificationService()

    private var lastNotificationTime: [UUID: Date] = [:]
    private let rateLimitInterval: TimeInterval = 600 // 10 minutes

    private init() {
        requestNotificationPermission()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    /// Notify user about 401 error for a specific profile
    /// Rate-limited to once per 10 minutes per profile
    func notify401(for profileId: UUID, profileName: String) {
        let now = Date()

        // Check rate limit
        if let lastTime = lastNotificationTime[profileId],
           now.timeIntervalSince(lastTime) < rateLimitInterval {
            return // Rate limited
        }

        lastNotificationTime[profileId] = now

        let content = UNMutableNotificationContent()
        content.title = "Claude Usage Monitor"
        content.body = "\(profileName): Session key expired. Please update your session key in Settings."
        content.sound = .default
        content.categoryIdentifier = "REAUTH_REQUIRED"

        let request = UNNotificationRequest(
            identifier: "reauth-\(profileId.uuidString)",
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to deliver notification: \(error)")
            }
        }
    }
}
