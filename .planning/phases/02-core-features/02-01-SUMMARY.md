---
phase: 02-core-features
plan: 01
subsystem: process-discovery
provides: [process-manager, js-process-model, live-process-list]
affects: [02-02, 02-03]
key-files: [NodeProcesses/JSProcess.swift, NodeProcesses/ProcessManager.swift, NodeProcesses/ProcessListView.swift]
key-decisions: [processmanager-mainactor-observableobject, ps-axo-pid-comm-args, exact-name-matching-node-bun-deno, 2s-timer-polling, stateobject-in-processlistview]
tech-stack:
  added: [Foundation.Process, Darwin.kill]
  patterns: [ObservableObject-MainActor, StateObject-ownership]
---

# Phase 2 Plan 01: Process Discovery Summary

**Replaced the placeholder ProcessListView with a live-polled list of running JS processes (node, bun, deno) backed by ProcessManager using ps every 2 seconds.**

## Accomplishments

- Created JSProcess Identifiable struct (pid, name, args) as the data model for process rows
- Created ProcessManager @MainActor ObservableObject that runs ps -axo pid=,comm=,args= every 2s, filters by exact comm name match to node/bun/deno, and publishes results via @Published processes
- Updated ProcessListView to use @StateObject ProcessManager, showing empty state or scrollable process rows with name, PID badge, and args preview
- All code compiles with BUILD SUCCEEDED via xcodebuild

## Files Created/Modified

- `NodeProcesses/JSProcess.swift` - Created: Identifiable struct with id (pid), pid, name, args fields
- `NodeProcesses/ProcessManager.swift` - Created: @MainActor ObservableObject polling ps every 2s, exact name filtering, Timer invalidated on deinit
- `NodeProcesses/ProcessListView.swift` - Modified: replaced placeholder with @StateObject ProcessManager, ScrollView/LazyVStack process list, ProcessRowView showing name + PID + args, empty state with checkmark.circle icon

## Decisions Made

- @MainActor on ProcessManager ensures @Published mutations are safe for SwiftUI without additional DispatchQueue.main calls
- ps -axo pid=,comm=,args= suppresses headers and provides PID, short process name, and full args in one call
- Exact Set membership check on comm basename prevents matching nodemon, bunny, bundler, etc.
- Timer.scheduledTimer with Task { @MainActor } bridge handles the Timer callback off-main-thread case safely
- ProcessRowView receives manager as @ObservedObject (not @StateObject) so it shares the parent's instance

## Issues Encountered

None. Build succeeded on first attempt with no errors.

## Next Step

Ready for 02-02-PLAN.md
