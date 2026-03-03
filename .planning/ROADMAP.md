# Roadmap: Node Processes

## Overview

Build a macOS native menu bar app in Swift/SwiftUI that gives instant visibility into all running JavaScript runtime processes (node, bun, deno). Starting from a bare Xcode project, we scaffold the menu bar shell, add process discovery and actions (kill, open in browser), then refine the UX with manual port overrides and polish.

## Domain Expertise

None

## Phases

- [x] **Phase 1: Foundation** - SwiftUI MenuBarExtra skeleton with app lifecycle and basic popover
- [ ] **Phase 2: Core Features** - Process discovery, kill action, port detection, open in browser
- [ ] **Phase 3: Polish** - Manual port override, refresh controls, UX refinements

## Phase Details

### Phase 1: Foundation
**Goal**: A running macOS menu bar app — icon in the menu bar, click opens a popover, app runs as an agent (no Dock icon)
**Depends on**: Nothing (first phase)
**Research**: Likely (SwiftUI MenuBarExtra API, agent app lifecycle, macOS 13+ patterns)
**Research topics**: `MenuBarExtra` vs `NSStatusItem` tradeoffs, app activation policy for menu bar agents, SwiftUI popover vs menu style
**Plans**: 2 plans

Plans:
- [ ] 01-01: Xcode project setup — new SwiftUI app, configure as menu bar agent (no Dock icon, `LSUIElement`)
- [ ] 01-02: MenuBarExtra skeleton — icon + popover with placeholder process list UI

### Phase 2: Core Features
**Goal**: The full core loop — see all JS processes, kill any of them, detect listening ports, open dev servers in browser
**Depends on**: Phase 1
**Research**: Likely (process enumeration from Swift, lsof port detection, sandbox entitlements)
**Research topics**: Enumerating processes by name via `ps`/`proc_info` from Swift, `lsof -iTCP -n -P` filtered by PID, entitlements needed for process inspection outside sandbox, POSIX `kill()` vs spawning `kill` subprocess, `NSWorkspace.shared.open()` for browser launch
**Plans**: 3 plans

Plans:
- [ ] 02-01: Process discovery — enumerate node/bun/deno processes, poll every 2s, display in popover list with PID and command args
- [ ] 02-02: Kill action — kill selected process (SIGTERM then SIGKILL), refresh list after
- [ ] 02-03: Port detection + browser open — detect listening ports per PID via lsof, show "Open in browser" button for processes with open ports

### Phase 3: Polish
**Goal**: Manual port override, configurable refresh, and overall UX tightening
**Depends on**: Phase 2
**Research**: Unlikely (internal patterns established in Phase 2)
**Plans**: 2 plans

Plans:
- [ ] 03-01: Manual port override — allow user to set/clear a custom port per process, persist per process name
- [ ] 03-02: UX polish — configurable refresh interval, empty state, error states, app icon

## Progress

**Execution Order:** 1 → 2 → 3

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 2/2 | Complete | 2026-03-03 |
| 2. Core Features | 0/3 | Not started | - |
| 3. Polish | 0/2 | Not started | - |
