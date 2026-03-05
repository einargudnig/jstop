# jstop

A native macOS menu bar app that shows all running JavaScript runtime processes (Node.js, Bun, Deno) at a glance. Kill any process or open a detected local dev server in the browser — without touching Activity Monitor or a terminal.

## Features

- **Menu bar icon** with a live count of running JS processes
- **Process discovery** — detects all running `node`, `bun`, and `deno` processes with PID, command args, and uptime
- **Port detection** — auto-detects listening TCP ports via `lsof`, including ports owned by child processes (e.g. `bun dev` → `node` → `next-server` on :3000)
- **Framework detection** — recognizes 25+ tools and frameworks (Next.js, Vite, Remix, Astro, etc.) from process args
- **One-click kill** — sends SIGTERM to gracefully stop any process
- **Open in browser** — click a port badge to open `http://localhost:<port>`
- **Smart grouping** — splits processes into "Dev Servers" (with ports) and "Background" (collapsed by default)
- **Adaptive polling** — 2s refresh when the popover is open, 10s when idle
- **Child process deduplication** — when a parent target spawns a child target (e.g. `bun` → `node`), only the parent is shown with inherited ports

## Requirements

- macOS 13+ (uses SwiftUI `MenuBarExtra`)
- Xcode 14+

## Building

Open `jstop.xcodeproj` in Xcode and build/run, or from the command line:

```sh
xcodebuild -project jstop.xcodeproj -scheme jstop build
```

## Showcase Video

A [Remotion](https://www.remotion.dev/)-powered showcase video lives in the `video/` directory.

```sh
cd video && npm install

# Preview in Remotion Studio
npm run studio

# Render to MP4
npm run render
```

Output: `video/out/jstop-showcase.mp4`

## Architecture

```
jstop/
├── jstopApp.swift        # App entry point, MenuBarExtra setup
├── ProcessManager.swift  # Process discovery (ps), port detection (lsof), kill
├── JSProcess.swift       # Process model, framework detection, path extraction
├── ProcessListView.swift # Main popover UI with Dev Servers / Background sections
└── ProcessRowView.swift  # Individual process row with port badges and kill button
```

The app runs as a sandboxing-disabled menu bar app. `ProcessManager` is a singleton that polls `ps` and `lsof` on a background thread, propagates child process ports up to parent targets, and publishes results to SwiftUI views via `@Published`.

## License

MIT
