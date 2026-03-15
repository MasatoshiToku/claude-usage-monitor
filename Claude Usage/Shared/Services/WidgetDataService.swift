import Foundation
import WidgetKit

/// Writes profile usage data as a JSON file to the widget extension's sandbox container.
/// The main app is non-sandboxed, so it can write to any path including the widget's container.
/// The widget reads the JSON file via FileManager from its own Documents directory.
final class WidgetDataService {
    static let shared = WidgetDataService()
    private let widgetBundleID = "com.tokumasatoshi.claude-usage-monitor.widget"
    private let fileName = "widget-data.json"

    private init() {}

    private var widgetDocumentsURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/Containers/\(widgetBundleID)/Data/Documents")
    }

    private var dataFileURL: URL {
        widgetDocumentsURL.appendingPathComponent(fileName)
    }

    /// Call after usage data is refreshed for any profile
    func updateWidgetData(profiles: [Profile]) {
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: widgetDocumentsURL, withIntermediateDirectories: true)

        // Build JSON array from profiles
        var accounts: [[String: Any]] = []
        for profile in profiles.prefix(3) {
            var account: [String: Any] = ["name": profile.name]
            if let usage = profile.claudeUsage {
                // ClaudeUsage percentages are 0-100 scale; widget expects 0-1 scale
                account["sessionPercent"] = usage.effectiveSessionPercentage / 100.0
                account["weeklyPercent"] = usage.weeklyPercentage / 100.0
                account["sessionResetAt"] = usage.sessionResetTime.timeIntervalSince1970
                account["isConfigured"] = true
            } else {
                account["sessionPercent"] = 0.0
                account["weeklyPercent"] = 0.0
                account["isConfigured"] = profile.hasUsageCredentials
            }
            accounts.append(account)
        }

        // Write as JSON file
        if let data = try? JSONSerialization.data(withJSONObject: accounts, options: .prettyPrinted) {
            try? data.write(to: dataFileURL, options: .atomic)
        }

        // Trigger widget reload
        WidgetCenter.shared.reloadAllTimelines()
    }
}
