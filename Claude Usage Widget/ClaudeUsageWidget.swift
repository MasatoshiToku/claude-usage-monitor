import WidgetKit
import SwiftUI

// MARK: - Data Model

struct AccountData {
    let name: String
    let sessionPercent: Double
    let weeklyPercent: Double
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
        // Read from JSON file in widget's own Documents directory
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return sampleAccounts()
        }

        let fileURL = docsURL.appendingPathComponent("widget-data.json")

        guard let data = try? Data(contentsOf: fileURL),
              let accounts = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return sampleAccounts()
        }

        return accounts.enumerated().map { index, dict in
            AccountData(
                name: dict["name"] as? String ?? "Account \(index + 1)",
                sessionPercent: dict["sessionPercent"] as? Double ?? 0,
                weeklyPercent: dict["weeklyPercent"] as? Double ?? 0,
                isConfigured: dict["isConfigured"] as? Bool ?? false
            )
        }
    }

    private func sampleAccounts() -> [AccountData] {
        [
            AccountData(name: "Team", sessionPercent: 0.45, weeklyPercent: 0.62, isConfigured: true),
            AccountData(name: "Pro", sessionPercent: 0.78, weeklyPercent: 0.34, isConfigured: true),
            AccountData(name: "Personal", sessionPercent: 0.0, weeklyPercent: 0.0, isConfigured: false),
        ]
    }
}

// MARK: - Color Helper

func colorForPercent(_ percent: Double) -> Color {
    if percent < 0.50 {
        return .green
    } else if percent < 0.80 {
        return .orange
    } else {
        return .red
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let accounts: [AccountData]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Claude Usage")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            ForEach(Array(accounts.enumerated()), id: \.offset) { _, account in
                if account.isConfigured {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(account.name)
                                .font(.caption2)
                                .lineLimit(1)
                            Spacer()
                            Text("\(Int(account.sessionPercent * 100))%")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(colorForPercent(account.sessionPercent))
                        }
                        ProgressView(value: account.sessionPercent)
                            .tint(colorForPercent(account.sessionPercent))
                    }
                } else {
                    HStack {
                        Text(account.name)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Spacer()
                        Text("--")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
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
                        Text(account.name)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .lineLimit(1)

                        ZStack {
                            // Session ring (outer)
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                            Circle()
                                .trim(from: 0, to: account.sessionPercent)
                                .stroke(colorForPercent(account.sessionPercent), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .rotationEffect(.degrees(-90))

                            // Weekly ring (inner)
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                                .padding(6)
                            Circle()
                                .trim(from: 0, to: account.weeklyPercent)
                                .stroke(colorForPercent(account.weeklyPercent), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .padding(6)

                            VStack(spacing: 0) {
                                Text("\(Int(account.sessionPercent * 100))%")
                                    .font(.system(size: 11, weight: .bold))
                                Text("ses")
                                    .font(.system(size: 7))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 50, height: 50)

                        Text("W: \(Int(account.weeklyPercent * 100))%")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 4) {
                        Text(account.name)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

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
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
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
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct ClaudeUsageWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: ClaudeUsageProvider.Entry

    var body: some View {
        switch family {
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
        AccountData(name: "Team", sessionPercent: 0.45, weeklyPercent: 0.62, isConfigured: true),
        AccountData(name: "Pro", sessionPercent: 0.78, weeklyPercent: 0.34, isConfigured: true),
        AccountData(name: "Personal", sessionPercent: 0.0, weeklyPercent: 0.0, isConfigured: false),
    ])
}

#Preview("Medium", as: .systemMedium) {
    ClaudeUsageWidget()
} timeline: {
    AccountUsageEntry(date: Date(), accounts: [
        AccountData(name: "Team", sessionPercent: 0.45, weeklyPercent: 0.62, isConfigured: true),
        AccountData(name: "Pro", sessionPercent: 0.85, weeklyPercent: 0.91, isConfigured: true),
        AccountData(name: "Personal", sessionPercent: 0.22, weeklyPercent: 0.15, isConfigured: true),
    ])
}
