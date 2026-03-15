## Execution Summary

### Root Cause

The widget data JSON file was not being updated because `WidgetDataService.updateWidgetData()` was only called inside the success path of `refreshAllSelectedProfiles()` (after fetching data from the API). When CLI OAuth tokens expired (which happened at 2026-03-15 21:42:54), `hasUsageCredentials` returned `false` for all 3 profiles. The `refreshAllSelectedProfiles()` function filtered these out and returned early at the guard clause without ever calling `updateWidgetData()`.

The same issue existed in:
1. `setup()` -- the initial launch only triggered widget update as a side effect of the first refresh, not independently
2. `refreshUsage()` single-profile path -- had the same guard that returned early without widget update
3. `refreshAllSelectedProfiles()` -- the guard at line 817-821 returned early without widget update

### Changes Made
- `/Users/tokumasatoshi/Documents/Cursor/claude-usage-monitor/Claude Usage/MenuBar/MenuBarManager.swift` -- Added `updateWidgetData()` calls in 4 new locations: (1) in `setup()` to update widget data on app launch regardless of credentials, (2) in `refreshAllSelectedProfiles()` early return when no profiles have credentials, (3) right after `saveClaudeUsage()` in the multi-profile per-profile loop, (4) right after `saveClaudeUsage()` in the single-profile path, (5) in `refreshUsage()` single-profile guard when no credentials
- `/Users/tokumasatoshi/Documents/Cursor/claude-usage-monitor/Claude Usage/Shared/Services/WidgetDataService.swift` -- Replaced silent `try?` error swallowing with proper `do/catch` blocks that log errors via `LoggingService` for both directory creation and file writing

### Files Created
- None

### Steps Completed
1. Found all `updateWidgetData()` call sites -- Done (originally 2 sites: multi-profile completion at line 937, single-profile success at line 1119)
2. Traced auto-refresh flow and identified the break point -- Done (CLI OAuth tokens expired, `hasUsageCredentials` returned false, guard clause returned early skipping widget update)
3. Added `updateWidgetData()` calls to all code paths that save or skip usage data -- Done (5 new call sites added)
4. Built, deployed, and verified -- Done (file timestamp updates both on launch and every 60-second auto-refresh cycle)

### Deviations from Plan
- The root cause was different from the plan's hypothesis. The plan suggested `updateWidgetData()` might not be called in the auto-refresh path. In reality, it WAS in the auto-refresh path, but the entire refresh was short-circuited by a guard clause when CLI OAuth tokens expired. The fix ensures widget data is updated even when the guard returns early.
- Added temporary file-based debug logging (to `~/Library/Logs/refresh-debug.log` and `~/Library/Logs/widget-data-debug.log`) to diagnose the issue since `os.log` output was not visible. All debug logging was removed in the final build.

### Notes
- All 3 profiles use CLI OAuth tokens (not `claudeSessionKey`/`organizationId`), and all tokens are currently expired. The widget data file is being updated with cached data (last known usage values stored in UserDefaults), but no fresh API data is being fetched until the tokens are refreshed.
- The `WidgetDataService` now has proper error logging instead of silent `try?` failures, which will help diagnose any future issues with file writing.
