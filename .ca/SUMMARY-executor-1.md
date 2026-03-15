## Execution Summary

### Changes Made
- `/Users/tokumasatoshi/Documents/Cursor/claude-usage-monitor/Claude Usage/Shared/Services/WidgetDataService.swift` — Replaced UserDefaults(suiteName:) approach with direct file writing to the Group Container plist path (`~/Library/Group Containers/group.claudeusagemonitor/Library/Preferences/group.claudeusagemonitor.plist`). This ensures the non-sandboxed main app writes to the same location that the sandboxed widget reads from.

### Files Created
- None

### Steps Completed
1. Read current WidgetDataService.swift, Profile.swift, ClaudeUsage.swift, and ClaudeUsageWidget.swift to verify property names — Done
2. Modified WidgetDataService.swift to write directly to Group Container plist instead of UserDefaults — Done
3. Build verification (`xcodebuild -scheme "Claude Usage" -configuration Debug build`) — Done (BUILD SUCCEEDED)

### Deviations from Plan
- Used non-optional `URL` (computed properties return `URL` not `URL?`) since the home directory and path components are always valid. This simplifies the code and avoids unnecessary optional unwrapping.

### Notes
- The root cause was a sandbox mismatch: main app (`ENABLE_APP_SANDBOX = NO`) uses `UserDefaults(suiteName:)` which writes to `~/Library/Preferences/`, while the sandboxed widget reads from `~/Library/Group Containers/`. The fix writes directly to the Group Container path using `NSDictionary.write(to:atomically:)`.
- The `ensureGroupContainerExists()` method is called both at init and before each write to guarantee the directory structure exists.
- The widget side (`ClaudeUsageWidget.swift`) was NOT modified — it still reads via `UserDefaults(suiteName:)` which correctly resolves to the Group Container path when running in a sandboxed widget extension.
