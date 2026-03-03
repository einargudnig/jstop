# Node Processes

## What This Is

A macOS native menu bar app built with Swift/SwiftUI that shows all running JavaScript runtime processes (node, bun, deno) at a glance. From the menu bar, you can kill any process or open a detected local dev server directly in the browser — without ever touching Activity Monitor or a terminal.

## Core Value

Instant visibility and one-click control over JS runtime processes, covering the three things that matter equally: see them, kill them, open them.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Menu bar icon that opens a popover/menu listing all active JS processes
- [ ] Detect and display all running node, bun, and deno processes (name, PID, command/args)
- [ ] Kill any process with one click
- [ ] Auto-detect which ports each process is listening on (via lsof or similar)
- [ ] Show "Open in browser" button for processes with detected listening ports
- [ ] Allow manually setting/overriding the port for a process

### Out of Scope

- Auto-restart dead processes — v1 is visibility and control, not lifecycle management
- Process logs (stdout/stderr) — keeps the UI simple and focused
- Electron or web-based wrapper — native Swift/SwiftUI only

## Context

- macOS menu bar app using SwiftUI's `MenuBarExtra` (macOS 13+) or `NSStatusItem`
- Process discovery via `ps`, `/proc`, or macOS `proc_info` APIs
- Port detection via `lsof -i -n -P` filtered by PID
- Browser launch via `NSWorkspace.shared.open(url)`
- Process termination via POSIX `kill()` or `Process`
- Target runtime processes: `node`, `bun`, `deno` — matched by process name

## Constraints

- **Tech stack**: Swift/SwiftUI — no Electron, no web tech, fully native macOS
- **macOS version**: Target macOS 13+ to use `MenuBarExtra` SwiftUI API
- **Permissions**: May need `com.apple.security.get-task-allow` or rely on user-space APIs only; avoid requiring full disk access

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| SwiftUI `MenuBarExtra` over `NSStatusItem` | Modern SwiftUI-native API, cleaner code | — Pending |
| `lsof` for port detection | Available on all macOS, no extra entitlements needed | — Pending |
| Poll-based process refresh (e.g. every 2s) vs. event-driven | Simpler to implement; event-driven requires kernel extensions | — Pending |
| Include bun and deno, not just node | User explicitly wants "any JS runtime" | — Pending |

---
*Last updated: 2026-03-03 after initialization*
