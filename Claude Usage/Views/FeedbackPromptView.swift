//
//  FeedbackPromptView.swift
//  Claude Usage
//
//  Stub — original feedback prompt removed for fork
//

import SwiftUI

struct FeedbackPromptView: View {
    let onSubmit: (_ name: String, _ role: String, _ contact: String, _ message: String) -> Void
    let onRemindLater: () -> Void
    let onDontAskAgain: () -> Void

    var body: some View {
        EmptyView()
    }
}
