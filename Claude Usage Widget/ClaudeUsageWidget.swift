import WidgetKit
import SwiftUI
import os

// MARK: - Data Model

struct AccountData {
    let name: String
    let sessionPercent: Double
    let weeklyPercent: Double
    let sessionResetAt: Date?
    let weeklyResetAt: Date?
    let isConfigured: Bool
}

// MARK: - Timeline Entry

struct AccountUsageEntry: TimelineEntry {
    let date: Date
    let accounts: [AccountData]
}

// MARK: - Timeline Provider

struct ClaudeUsageProvider: TimelineProvider {
    private let maxAccounts = 3
    private let logger = Logger(subsystem: "com.tokumasatoshi.claude-usage-monitor.widget", category: "data")

    func placeholder(in context: Context) -> AccountUsageEntry {
        AccountUsageEntry(date: Date(), accounts: sampleAccounts())
    }

    func getSnapshot(in context: Context, completion: @escaping (AccountUsageEntry) -> Void) {
        let entry = AccountUsageEntry(date: Date(), accounts: loadAccounts())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AccountUsageEntry>) -> Void) {
        let entry = AccountUsageEntry(date: Date(), accounts: loadAccounts())
        let nextUpdate = Date().addingTimeInterval(15 * 60)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadAccounts() -> [AccountData] {
        logger.info("=== Widget loadAccounts() START ===")

        // Attempt 1: Standard documentDirectory
        if let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            logger.info("Widget documentDirectory: \(docsURL.path)")
            let fileURL = docsURL.appendingPathComponent("widget-data.json")
            let exists = FileManager.default.fileExists(atPath: fileURL.path)
            logger.info("Widget file exists at documentDirectory: \(exists)")

            if exists {
                if let result = parseWidgetData(from: fileURL) {
                    logger.info("Widget loaded \(result.count) accounts from documentDirectory")
                    return result
                }
            }
        } else {
            logger.error("Widget documentDirectory: UNAVAILABLE")
        }

        // Attempt 2: Hardcoded fallback path
        let fallbackURL = URL(fileURLWithPath: "/Users/tokumasatoshi/Library/Containers/com.tokumasatoshi.claude-usage-monitor.widget/Data/Documents/widget-data.json")
        let fallbackExists = FileManager.default.fileExists(atPath: fallbackURL.path)
        logger.info("Widget fallback path: \(fallbackURL.path)")
        logger.info("Widget fallback file exists: \(fallbackExists)")

        if fallbackExists {
            if let result = parseWidgetData(from: fallbackURL) {
                logger.info("Widget loaded \(result.count) accounts from fallback path")
                return result
            }
        }

        logger.warning("Widget: no data found, returning sample accounts")
        return sampleAccounts()
    }

    private func parseWidgetData(from fileURL: URL) -> [AccountData]? {
        do {
            let data = try Data(contentsOf: fileURL)
            logger.info("Widget file read OK, \(data.count) bytes")

            guard let accounts = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                logger.error("Widget JSON parse failed: not an array of dictionaries")
                return nil
            }

            logger.info("Widget parsed \(accounts.count) accounts from JSON")

            return accounts.enumerated().map { index, dict in
                let resetAt: Date? = {
                    guard let ts = dict["sessionResetAt"] as? Double, ts > 0 else { return nil }
                    return Date(timeIntervalSince1970: ts)
                }()
                let weeklyReset: Date? = {
                    guard let ts = dict["weeklyResetAt"] as? Double, ts > 0 else { return nil }
                    return Date(timeIntervalSince1970: ts)
                }()
                return AccountData(
                    name: dict["name"] as? String ?? "Account \(index + 1)",
                    sessionPercent: dict["sessionPercent"] as? Double ?? 0,
                    weeklyPercent: dict["weeklyPercent"] as? Double ?? 0,
                    sessionResetAt: resetAt,
                    weeklyResetAt: weeklyReset,
                    isConfigured: dict["isConfigured"] as? Bool ?? false
                )
            }
        } catch {
            logger.error("Widget file read/parse error: \(error.localizedDescription)")
            return nil
        }
    }

    private func sampleAccounts() -> [AccountData] {
        [
            AccountData(name: "Team", sessionPercent: 0.45, weeklyPercent: 0.62, sessionResetAt: Date().addingTimeInterval(2700), weeklyResetAt: Date().addingTimeInterval(259200), isConfigured: true),
            AccountData(name: "Pro", sessionPercent: 0.78, weeklyPercent: 0.34, sessionResetAt: Date().addingTimeInterval(7200), weeklyResetAt: Date().addingTimeInterval(172800), isConfigured: true),
            AccountData(name: "Personal", sessionPercent: 0.0, weeklyPercent: 0.0, sessionResetAt: nil, weeklyResetAt: nil, isConfigured: false),
        ]
    }
}

// MARK: - Color Helpers

/// Claude brand orange color (#FF6B35)
let claudeOrange = Color(red: 1.0, green: 0.42, blue: 0.21)

/// Returns green/orange/red based on usage percentage
func colorForPercent(_ percent: Double) -> Color {
    if percent < 0.50 {
        return .green
    } else if percent < 0.80 {
        return .orange
    } else {
        return .red
    }
}

/// Subtle background tint for account sections based on usage level
func backgroundTintForPercent(_ percent: Double) -> Color {
    colorForPercent(percent).opacity(0.07)
}

/// Unified reset time formatter for both session and weekly resets.
/// - Within 1 hour: "XXm"
/// - Within 24 hours: "XXh"
/// - Beyond 24 hours: "M/dd HH:mm"
func formatResetTime(_ resetDate: Date?) -> String? {
    guard let resetDate = resetDate else { return nil }
    let now = Date()
    if resetDate <= now { return nil }
    let remaining = resetDate.timeIntervalSince(now)
    if remaining < 3600 {
        let minutes = Int(remaining / 60)
        return "\(minutes)m"
    } else if remaining < 86400 {
        let hours = Int(remaining / 3600)
        return "\(hours)h"
    } else {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/dd HH:mm"
        return formatter.string(from: resetDate)
    }
}

/// Status dot indicator for account name
struct StatusDot: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 6, height: 6)
    }
}

/// Consistent reset time display with clock icon
struct ResetTimeLabel: View {
    let prefix: String
    let resetDate: Date?
    let fontSize: CGFloat
    let iconSize: CGFloat

    var body: some View {
        if let text = formatResetTime(resetDate) {
            HStack(spacing: 2) {
                Image(systemName: "clock")
                    .font(.system(size: iconSize))
                    .foregroundStyle(.secondary)
                Text("\(prefix)\(text)")
                    .font(.system(size: fontSize))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let accounts: [AccountData]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Title with Claude orange color
            HStack(spacing: 3) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(claudeOrange)
                Text("Claude Usage")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(claudeOrange)
            }

            ForEach(Array(accounts.enumerated()), id: \.offset) { _, account in
                if account.isConfigured {
                    VStack(alignment: .leading, spacing: 2) {
                        // Account name with status dot and percentages
                        HStack(spacing: 4) {
                            StatusDot(color: colorForPercent(max(account.sessionPercent, account.weeklyPercent)))
                            Text(account.name)
                                .font(.caption2)
                                .lineLimit(1)
                            Spacer()
                            Text("S:")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                            Text("\(Int(account.sessionPercent * 100))%")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(colorForPercent(account.sessionPercent))
                            Text("W:")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                            Text("\(Int(account.weeklyPercent * 100))%")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(colorForPercent(account.weeklyPercent))
                        }
                        // Session progress bar
                        ProgressView(value: account.sessionPercent)
                            .tint(colorForPercent(account.sessionPercent))
                            .scaleEffect(y: 0.8)
                        // Weekly progress bar
                        ProgressView(value: account.weeklyPercent)
                            .tint(colorForPercent(account.weeklyPercent))
                            .scaleEffect(y: 0.8)
                        // Reset times with consistent format
                        HStack(spacing: 6) {
                            ResetTimeLabel(prefix: "S:", resetDate: account.sessionResetAt, fontSize: 8, iconSize: 6)
                            ResetTimeLabel(prefix: "W:", resetDate: account.weeklyResetAt, fontSize: 8, iconSize: 6)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(backgroundTintForPercent(max(account.sessionPercent, account.weeklyPercent)))
                    )
                } else {
                    // Unconfigured accounts shown in gray
                    HStack(spacing: 4) {
                        StatusDot(color: .gray.opacity(0.4))
                        Text(account.name)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Spacer()
                        Text("--")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.05))
                    )
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let accounts: [AccountData]

    var body: some View {
        HStack(spacing: 16) {
            ForEach(Array(accounts.enumerated()), id: \.offset) { _, account in
                if account.isConfigured {
                    VStack(spacing: 4) {
                        // Account name with status dot (color based on max usage)
                        HStack(spacing: 3) {
                            StatusDot(color: colorForPercent(max(account.sessionPercent, account.weeklyPercent)))
                            Text(account.name)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                        }

                        ZStack {
                            // Session ring (outer) - colored by usage level
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                            Circle()
                                .trim(from: 0, to: account.sessionPercent)
                                .stroke(colorForPercent(account.sessionPercent), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .rotationEffect(.degrees(-90))

                            // Weekly ring (inner) - colored by usage level
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                                .padding(6)
                            Circle()
                                .trim(from: 0, to: account.weeklyPercent)
                                .stroke(colorForPercent(account.weeklyPercent), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .padding(6)

                            // Center percentage text
                            VStack(spacing: 0) {
                                Text("\(Int(account.sessionPercent * 100))%")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(colorForPercent(account.sessionPercent))
                                Text("S:")
                                    .font(.system(size: 7))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 50, height: 50)

                        // Weekly percentage with compact label
                        Text("W: \(Int(account.weeklyPercent * 100))%")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(colorForPercent(account.weeklyPercent))
                        // Session reset time
                        ResetTimeLabel(prefix: "S:", resetDate: account.sessionResetAt, fontSize: 8, iconSize: 7)
                        // Weekly reset time
                        ResetTimeLabel(prefix: "W:", resetDate: account.weeklyResetAt, fontSize: 8, iconSize: 7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(backgroundTintForPercent(max(account.sessionPercent, account.weeklyPercent)))
                    )
                } else {
                    // Unconfigured accounts shown in gray
                    VStack(spacing: 4) {
                        HStack(spacing: 3) {
                            StatusDot(color: .gray.opacity(0.4))
                            Text(account.name)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.15), lineWidth: 4)
                            Text("--")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(width: 50, height: 50)

                        Text("Not set")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.05))
                    )
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let accounts: [AccountData]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 5) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(claudeOrange)
                Text("Claude Usage Monitor")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(claudeOrange)
                Spacer()
                // Legend
                HStack(spacing: 8) {
                    LegendItem(label: "Session", symbol: "circle.fill")
                    LegendItem(label: "Weekly", symbol: "square.fill")
                }
            }
            .padding(.bottom, 8)

            // Account cards
            ForEach(Array(accounts.enumerated()), id: \.offset) { index, account in
                if index > 0 {
                    Divider()
                        .padding(.vertical, 4)
                }

                if account.isConfigured {
                    LargeAccountCard(account: account)
                } else {
                    LargeUnconfiguredCard(account: account)
                }
            }

            Spacer(minLength: 0)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

/// Legend item for the Large widget header
struct LegendItem: View {
    let label: String
    let symbol: String

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: symbol)
                .font(.system(size: 5))
                .foregroundStyle(.secondary)
            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
        }
    }
}

/// Configured account card for Large widget
struct LargeAccountCard: View {
    let account: AccountData

    var body: some View {
        HStack(spacing: 12) {
            // Session: circular progress ring
            VStack(spacing: 2) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: account.sessionPercent)
                        .stroke(colorForPercent(account.sessionPercent), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(account.sessionPercent * 100))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(colorForPercent(account.sessionPercent))
                }
                .frame(width: 56, height: 56)
                Text("Session")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }

            // Account info and weekly bar
            VStack(alignment: .leading, spacing: 6) {
                // Account name with status dot (color based on max usage)
                HStack(spacing: 5) {
                    StatusDot(color: colorForPercent(max(account.sessionPercent, account.weeklyPercent)))
                    Text(account.name)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }

                // Weekly progress bar
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Weekly")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(account.weeklyPercent * 100))%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(colorForPercent(account.weeklyPercent))
                    }
                    ProgressView(value: account.weeklyPercent)
                        .tint(colorForPercent(account.weeklyPercent))
                }

                // Reset times with consistent format and icons
                ResetTimeLabel(prefix: "Session: ", resetDate: account.sessionResetAt, fontSize: 10, iconSize: 9)
                ResetTimeLabel(prefix: "Weekly: ", resetDate: account.weeklyResetAt, fontSize: 10, iconSize: 9)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundTintForPercent(max(account.sessionPercent, account.weeklyPercent)))
        )
    }
}

/// Unconfigured account card for Large widget
struct LargeUnconfiguredCard: View {
    let account: AccountData

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 5)
                Text("--")
                    .font(.system(size: 14))
                    .foregroundStyle(.tertiary)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    StatusDot(color: .gray.opacity(0.4))
                    Text(account.name)
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                }
                Text("Not configured")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

// MARK: - Widget Configuration

struct ClaudeUsageWidget: Widget {
    let kind: String = "ClaudeUsageWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ClaudeUsageProvider()) { entry in
            switch WidgetFamily.self {
            default:
                ClaudeUsageWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("Claude Usage")
        .description("Monitor your Claude API usage at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct ClaudeUsageWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: ClaudeUsageProvider.Entry

    var body: some View {
        switch family {
        case .systemLarge:
            LargeWidgetView(accounts: entry.accounts)
        case .systemMedium:
            MediumWidgetView(accounts: entry.accounts)
        default:
            SmallWidgetView(accounts: entry.accounts)
        }
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    ClaudeUsageWidget()
} timeline: {
    AccountUsageEntry(date: Date(), accounts: [
        AccountData(name: "Team", sessionPercent: 0.45, weeklyPercent: 0.62, sessionResetAt: Date().addingTimeInterval(2700), weeklyResetAt: Date().addingTimeInterval(172800), isConfigured: true),
        AccountData(name: "Pro", sessionPercent: 0.78, weeklyPercent: 0.34, sessionResetAt: Date().addingTimeInterval(7200), weeklyResetAt: Date().addingTimeInterval(172800), isConfigured: true),
        AccountData(name: "Personal", sessionPercent: 0.0, weeklyPercent: 0.0, sessionResetAt: nil, weeklyResetAt: nil, isConfigured: false),
    ])
}

#Preview("Medium", as: .systemMedium) {
    ClaudeUsageWidget()
} timeline: {
    AccountUsageEntry(date: Date(), accounts: [
        AccountData(name: "Team", sessionPercent: 0.45, weeklyPercent: 0.62, sessionResetAt: Date().addingTimeInterval(2700), weeklyResetAt: Date().addingTimeInterval(172800), isConfigured: true),
        AccountData(name: "Pro", sessionPercent: 0.85, weeklyPercent: 0.91, sessionResetAt: Date().addingTimeInterval(10800), weeklyResetAt: Date().addingTimeInterval(172800), isConfigured: true),
        AccountData(name: "Personal", sessionPercent: 0.22, weeklyPercent: 0.15, sessionResetAt: Date().addingTimeInterval(900), weeklyResetAt: Date().addingTimeInterval(172800), isConfigured: true),
    ])
}

#Preview("Large", as: .systemLarge) {
    ClaudeUsageWidget()
} timeline: {
    AccountUsageEntry(date: Date(), accounts: [
        AccountData(name: "Team", sessionPercent: 0.45, weeklyPercent: 0.62, sessionResetAt: Date().addingTimeInterval(2700), weeklyResetAt: Date().addingTimeInterval(172800), isConfigured: true),
        AccountData(name: "Pro", sessionPercent: 0.85, weeklyPercent: 0.91, sessionResetAt: Date().addingTimeInterval(10800), weeklyResetAt: Date().addingTimeInterval(172800), isConfigured: true),
        AccountData(name: "Personal", sessionPercent: 0.0, weeklyPercent: 0.0, sessionResetAt: nil, weeklyResetAt: nil, isConfigured: false),
    ])
}
