import Foundation
import WidgetKit

/// Writes profile usage data directly to the widget extension's sandbox container.
/// The main app is non-sandboxed, so it can write to any path including the widget's container.
/// The widget reads via UserDefaults.standard, which maps to its own container's Preferences plist.
final class WidgetDataService {
    static let shared = WidgetDataService()
    private let widgetBundleID = "com.tokumasatoshi.claude-usage-monitor.widget"

    private init() {
        ensureWidgetPrefsDirectoryExists()
    }

    private var widgetPrefsDirectory: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/Containers/\(widgetBundleID)/Data/Library/Preferences")
    }

    private var widgetPrefsURL: URL {
        widgetPrefsDirectory.appendingPathComponent("\(widgetBundleID).plist")
    }

    private func ensureWidgetPrefsDirectoryExists() {
        try? FileManager.default.createDirectory(at: widgetPrefsDirectory, withIntermediateDirectories: true)
    }

    /// Call after usage data is refreshed for any profile
    func updateWidgetData(profiles: [Profile]) {
        ensureWidgetPrefsDirectoryExists()

        var dict: [String: Any] = [:]

        for (index, profile) in profiles.prefix(3).enumerated() {
            let prefix = "widget.account.\(index)"
            dict["\(prefix).name"] = profile.name

            if let usage = profile.claudeUsage {
                // ClaudeUsage percentages are 0-100 scale; widget expects 0-1 scale
                dict["\(prefix).sessionPercent"] = usage.effectiveSessionPercentage / 100.0
                dict["\(prefix).weeklyPercent"] = usage.weeklyPercentage / 100.0
                dict["\(prefix).isConfigured"] = true
            } else {
                dict["\(prefix).sessionPercent"] = 0.0
                dict["\(prefix).weeklyPercent"] = 0.0
                dict["\(prefix).isConfigured"] = profile.hasUsageCredentials
            }
        }

        // Write directly to the widget's sandbox Preferences plist
        (dict as NSDictionary).write(to: widgetPrefsURL, atomically: true)

        // Trigger widget reload
        WidgetCenter.shared.reloadAllTimelines()
    }
}
