import Foundation
import WidgetKit

/// Writes profile usage data to App Groups UserDefaults for the widget extension
final class WidgetDataService {
    static let shared = WidgetDataService()
    private let suiteName = "com.tokumasatoshi.claude-usage-monitor"

    private init() {}

    /// Call after usage data is refreshed for any profile
    func updateWidgetData(profiles: [Profile]) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }

        for (index, profile) in profiles.prefix(3).enumerated() {
            let prefix = "widget.account.\(index)"
            defaults.set(profile.name, forKey: "\(prefix).name")

            if let usage = profile.claudeUsage {
                // ClaudeUsage percentages are 0-100 scale; widget expects 0-1 scale
                defaults.set(usage.effectiveSessionPercentage / 100.0, forKey: "\(prefix).sessionPercent")
                defaults.set(usage.weeklyPercentage / 100.0, forKey: "\(prefix).weeklyPercent")
                defaults.set(true, forKey: "\(prefix).isConfigured")
            } else {
                defaults.set(0.0, forKey: "\(prefix).sessionPercent")
                defaults.set(0.0, forKey: "\(prefix).weeklyPercent")
                defaults.set(profile.hasUsageCredentials, forKey: "\(prefix).isConfigured")
            }
        }

        // Trigger widget reload
        WidgetCenter.shared.reloadAllTimelines()
    }
}
