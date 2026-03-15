## Execution Summary

### Changes Made
- `/Users/tokumasatoshi/Documents/Cursor/claude-usage-monitor/Claude Usage/Views/Settings/App/ManageProfilesView.swift` — Restructured ProfileRow to make the rename feature accessible

### Files Created
- None

### Steps Completed
1. Moved the pencil icon from the far-right actions area to inline next to the profile name — Done
2. Made the profile name text directly tappable via `.onTapGesture` to enter edit mode — Done
3. Moved save/cancel buttons (checkmark/xmark) from the far-right actions area to inline next to the TextField in edit mode — Done
4. Kept the activate button (checkmark.circle) in the far-right area since it is a separate action — Done

### Deviations from Plan
- None

### Notes
- **Root cause**: The pencil icon was placed after `Spacer()` in a small `HStack` at the far-right edge of the row, making it nearly invisible at `font(.system(size: 12))` with `.buttonStyle(.plain)`.
- **What changed in ProfileRow**:
  1. The pencil icon is now positioned inline, immediately after the profile name text (before the active badge), always visible in `.secondary` color
  2. The profile name `Text` now has an `.onTapGesture` that triggers edit mode — clicking the name itself starts editing
  3. When in edit mode, the save (checkmark) and cancel (xmark) buttons appear inline next to the TextField, not pushed to the far right
  4. The far-right actions area now only contains the activate button (for non-active profiles)
- The edit/save/cancel flow is preserved: Enter key in TextField saves, checkmark button saves, xmark button cancels
