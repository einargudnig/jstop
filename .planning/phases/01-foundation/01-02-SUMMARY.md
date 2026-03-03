---
phase: 01-foundation
plan: 02
subsystem: app-shell
tags: [SwiftUI, MenuBarExtra, macOS, menu-bar-app]
requires:
  - phase: 01-foundation-plan-01
    provides: [xcode-project, build-config, entitlements]
provides:
  - menu-bar-app-shell
  - swiftui-menubarextra-window-style
  - processlistview-placeholder
  - quit-button-in-popover
affects: [02-01, 02-02, 02-03]
tech-stack:
  added: [SwiftUI, MenuBarExtra, NSApplication]
  patterns: [MenuBarExtra-window-style, LSUIElement-background-agent, fixed-width-popover-320pt]
key-files:
  created: [NodeProcesses/NodeProcessesApp.swift, NodeProcesses/ProcessListView.swift]
  modified: []
key-decisions:
  - "MenuBarExtra(.window) style — chosen over .menu for interactive Phase 2 controls"
  - "terminal SF Symbol for icon — no custom asset needed for v1"
  - "Quit button in popover — required since LSUIElement removes standard quit mechanisms"
  - "Fixed 320pt popover width — standard for menu bar utility apps"
patterns-established:
  - "ProcessListView: VStack with header/content/quit sections, .frame(width: 320)"
  - "App entry: @main struct using MenuBarExtra { } label: { Image(systemName:) }"
issues-created: []
duration: 3min
completed: 2026-03-03
---

# Phase 1 Plan 02: MenuBarExtra Skeleton Summary

**SwiftUI MenuBarExtra(.window) app shell with terminal icon, 320pt popover, placeholder process list, and Quit button — verified running in macOS menu bar with no Dock icon.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-03T14:33:14Z
- **Completed:** 2026-03-03T14:36:10Z
- **Tasks:** 2 (1 auto + 1 checkpoint:human-verify)
- **Files modified:** 2

## Accomplishments

- Replaced placeholder with `@main NodeProcessesApp` using `MenuBarExtra { ProcessListView() } label: { Image(systemName: "terminal") }.menuBarExtraStyle(.window)`
- Created `ProcessListView` with header, empty state (terminal icon + "No processes running"), and Quit button — fixed 320pt width
- Verified: app runs in macOS menu bar, terminal icon visible, popover opens on click, no Dock icon

## Task Commits

1. **Task 1: Write App entry point and ProcessListView** — `89d1885` (feat)

**Plan metadata:** *(this commit)*

## Files Created/Modified

- `NodeProcesses/NodeProcessesApp.swift` — @main App with MenuBarExtra(.window) and SF Symbol terminal icon
- `NodeProcesses/ProcessListView.swift` — placeholder process list, 320pt wide, with Quit button

## Decisions Made

- `.menuBarExtraStyle(.window)` — required for Phase 2 interactive buttons (kill, open in browser); `.menu` style doesn't support SwiftUI interactive controls
- Quit button in popover — with `LSUIElement=YES` there's no standard way to quit the app
- `Image(systemName: "terminal")` — recognizable, no custom asset needed for v1

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## Next Phase Readiness

- Phase 1 complete — app shell is live and working
- Phase 2 can now replace `ProcessListView` placeholder with real process enumeration
- `NodeProcessesApp.swift` pattern established: add features to `ProcessListView` only

---
*Phase: 01-foundation*
*Completed: 2026-03-03*
