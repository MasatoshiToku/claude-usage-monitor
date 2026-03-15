## Execution Summary

### Changes Made
- `/Users/tokumasatoshi/Documents/Cursor/claude-usage-monitor/Claude Usage/MenuBar/MenuBarManager.swift` -- Two fixes to prevent 429 rate limit errors from Claude.ai

### Files Created
- None

### Steps Completed
1. **Fix A: Stagger profile requests** -- Done. Changed the `for profile in selectedProfiles` loop in `refreshAllSelectedProfiles()` to use `enumerated()` and added a 3-second `Task.sleep` between each profile fetch (skipping the first).
2. **Fix B: Deduplicate startup refreshes** -- Done. Added a `lastMultiProfileRefreshTime` property and a guard at the top of `refreshAllSelectedProfiles()` that skips execution if `isRefreshing` is already true or if the last refresh completed less than 10 seconds ago. The property is updated at the end of the refresh completion block.
3. **Build verification** -- Done. `xcodebuild` completed with `BUILD SUCCEEDED`.

### Deviations from Plan
- Used the existing `isRefreshing` published property (already declared at line 12) for the "already refreshing" guard instead of adding a new private `isRefreshing` property. This avoids a naming conflict and leverages the existing state.
- Added a separate `lastMultiProfileRefreshTime` property instead of reusing `lastRefreshTriggerTime`, because `lastRefreshTriggerTime` serves a different purpose (distinguishing user-triggered vs auto-triggered refreshes) and is set at different points in the code.

### Notes
- The 3-second delay between profile requests means that with 3 profiles, the full refresh takes ~6 seconds instead of being near-simultaneous. This prevents Claude.ai from returning 429 errors.
- The 10-second deduplication window prevents the double-refresh at startup: the `setupMultiProfileMode()` call triggers the first refresh, and when "Network became available" fires shortly after, it will be blocked by the guard.
- The existing 2-second guard in the `onNetworkAvailable` callback (line 143) only checked `lastRefreshTriggerTime`, which was not set by `setupMultiProfileMode()`. The new guard inside `refreshAllSelectedProfiles()` itself provides a more reliable deduplication.
