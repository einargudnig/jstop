---
phase: 01-foundation
plan: 01
subsystem: project-setup
provides: [xcode-project, build-config, entitlements]
affects: [01-02, 02-01]
key-files: [project.yml, NodeProcesses/Info.plist, NodeProcesses/NodeProcesses.entitlements, NodeProcesses.xcodeproj]
key-decisions: [xcodegen-for-scaffolding, sandbox-disabled, lsuielement-true, deployment-target-macos13]
---

# Phase 1 Plan 01: Xcode Project Setup Summary

**Scaffolded a buildable macOS menu bar app Xcode project with XcodeGen, configured as an agent app (no Dock icon) with App Sandbox disabled for Phase 2 process enumeration.**

## Accomplishments

- Generated `NodeProcesses.xcodeproj` via XcodeGen from `project.yml` — macOS 13 deployment target, Swift 5.9
- Configured `Info.plist` with `LSUIElement=true` and `NodeProcesses.entitlements` with `app-sandbox=false`
- Verified `xcodebuild` reports BUILD SUCCEEDED

## Files Created/Modified

- `project.yml` — XcodeGen project descriptor (macOS 13, Swift 5.9, code signing off)
- `NodeProcesses/Info.plist` — LSUIElement=YES, no Dock icon
- `NodeProcesses/NodeProcesses.entitlements` — App Sandbox disabled
- `NodeProcesses/NodeProcessesApp.swift` — placeholder Swift file (required for valid XcodeGen target)
- `NodeProcesses/Assets.xcassets/` — minimal asset catalog (Contents.json, AccentColor.colorset, AppIcon.appiconset)
- `NodeProcesses.xcodeproj` — Generated Xcode project

## Decisions Made

- Used XcodeGen (not manual xcodeproj) — automatable and human-editable YAML source
- Disabled App Sandbox now — avoids breaking change when Phase 2 needs ps/lsof
- LSUIElement in Info.plist — more reliable than runtime activation policy

## Issues Encountered

- Xcode plugin loading failure on first `xcodebuild` run (IDESimulatorFoundation symbol mismatch). Resolved by running `xcodebuild -runFirstLaunch` to update system content. Subsequent build succeeded. No code changes required — environment-only fix.

## Next Step

Ready for 01-02-PLAN.md
