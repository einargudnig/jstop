# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-03)

**Core value:** Instant visibility and one-click control over JS runtime processes — see them, kill them, open them
**Current focus:** Phase 2 — Core Features

## Current Position

Phase: 2 of 3 (Core Features)
Plan: 02-01 complete
Status: Ready for 02-02
Last activity: 2026-03-03 — 02-01-PLAN.md complete (process discovery)

Progress: ████░░░░░░ 43%

## Performance Metrics

**Velocity:**
- Total plans completed: 3
- Average duration: ~3 min/plan
- Total execution time: ~9 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1. Foundation | 2/2 | ~6 min | ~3 min |
| 2. Core Features | 1/3 | ~3 min | ~3 min |

**Recent Trend:**
- Last 3 plans: ~3 min, ~3 min, ~3 min
- Trend: Stable

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Phase 1 plan 01: Used XcodeGen for project scaffolding (automatable .xcodeproj from project.yml)
- Phase 1 plan 01: App Sandbox disabled — required for ps/lsof in Phase 2
- Phase 1 plan 01: LSUIElement=YES in Info.plist — prevents Dock icon from launch
- Phase 1 plan 02: MenuBarExtra(.window) style — required for interactive buttons in Phase 2
- Phase 1 plan 02: ProcessListView pattern — VStack with header/content/quit sections, .frame(width: 320)
- Phase 2 plan 01: ProcessManager @MainActor ObservableObject with ps -axo pid=,comm=,args= polling every 2s
- Phase 2 plan 01: Exact comm basename matching for node/bun/deno — prevents false positives
- Phase 2 plan 01: @StateObject in ProcessListView owns ProcessManager; ProcessRowView uses @ObservedObject

### Deferred Issues

None yet.

### Blockers/Concerns

None yet.

## Session Continuity

Last session: 2026-03-03
Stopped at: Phase 2 plan 01 complete — live process list showing node/bun/deno processes polled every 2s
Resume file: None
