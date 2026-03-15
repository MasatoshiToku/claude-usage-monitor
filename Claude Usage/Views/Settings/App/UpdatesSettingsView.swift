//
//  UpdatesSettingsView.swift
//  Claude Usage
//
//  Simple version display (Sparkle removed)
//

import SwiftUI

struct UpdatesSettingsView: View {
    private let updateManager = UpdateManager()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                // Page Header
                SettingsPageHeader(
                    title: "settings.updates.title".localized,
                    subtitle: "settings.updates.description".localized
                )

                // Version Info Section
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                    Text("updates.version_info".localized)
                        .font(DesignTokens.Typography.sectionTitle)

                    VStack(spacing: DesignTokens.Spacing.small) {
                        // Current Version
                        HStack {
                            HStack(spacing: DesignTokens.Spacing.iconText) {
                                Image(systemName: "app.badge")
                                    .font(.system(size: DesignTokens.Icons.standard))
                                    .foregroundColor(.accentColor)
                                    .frame(width: DesignTokens.Spacing.iconFrame)
                                Text("settings.updates.current_version".localized)
                                    .font(DesignTokens.Typography.body)
                            }
                            Spacer()
                            Text("v\(updateManager.appVersion) (\(updateManager.buildNumber))")
                                .font(DesignTokens.Typography.monospaced)
                                .foregroundColor(.secondary)
                        }
                        .padding(DesignTokens.Spacing.medium)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.small)
                                .fill(DesignTokens.Colors.cardBackground)
                        )
                    }
                }

                Spacer()
            }
            .padding(28)
        }
    }
}

#Preview {
    UpdatesSettingsView()
        .frame(width: 520, height: 600)
}
