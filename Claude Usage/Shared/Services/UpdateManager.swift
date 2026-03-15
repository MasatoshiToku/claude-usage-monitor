//
//  UpdateManager.swift
//  Claude Usage
//
//  Simple version display (Sparkle removed)
//

import Foundation
import Combine

@MainActor
class UpdateManager: ObservableObject {
    @Published var appVersion: String
    @Published var buildNumber: String

    init() {
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        self.buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}
