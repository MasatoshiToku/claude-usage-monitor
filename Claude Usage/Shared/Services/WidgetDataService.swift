import Foundation
import WidgetKit

/// Writes profile usage data to the Group Container plist for the widget extension.
/// The main app is non-sandboxed, so UserDefaults(suiteName:) writes to ~/Library/Preferences/.
/// The widget is sandboxed, so it reads from ~/Library/Group Containers/.
/// To bridge this gap, we write directly to the Group Container plist path.
final class WidgetDataService {
    static let shared = WidgetDataService()
    private let groupID = "group.claudeusagemonitor"

    private init() {
        ensureGroupContainerExists()
    }

    private var groupContainerURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/Group Containers/\(groupID)")
    }

    private var prefsURL: URL {
        groupContainerURL
            .appendingPathComponent("Library")
            .appendingPathComponent("Preferences")
            .appendingPathComponent("\(groupID).plist")
    }

    private func ensureGroupContainerExists() {
        let prefsDir = groupContainerURL.appendingPathComponent("Library/Preferences")
        try? FileManager.default.createDirectory(at: prefsDir, withIntermediateDirectories: true)
    }

    /// Call after usage data is refreshed for any profile
    func updateWidgetData(profiles: [Profile]) {
        ensureGroupContainerExists()

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

        // Write directly to the Group Container plist so the sandboxed widget can read it
        (dict as NSDictionary).write(to: prefsURL, atomically: true)

        // Trigger widget reload
        WidgetCenter.shared.reloadAllTimelines()
    }
}
