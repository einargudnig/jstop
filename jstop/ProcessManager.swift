import Foundation
import Combine

/// Manages discovering and monitoring running JS processes (node, bun, deno).
///
/// @MainActor means all properties and methods run on the main thread by default.
/// This is required because SwiftUI views observe @Published properties, and UI
/// updates must happen on the main thread.
///
/// ObservableObject lets SwiftUI views subscribe to changes via @ObservedObject.
/// When a @Published property changes, any view observing this object re-renders.
@MainActor
class ProcessManager: ObservableObject {
    /// Singleton instance. `static let` means there's exactly one ProcessManager
    /// for the whole app. The first time anyone accesses `.shared`, Swift creates it.
    static let shared = ProcessManager()

    /// The current list of detected JS processes. @Published means SwiftUI views
    /// automatically update when this array changes.
    @Published var processes: [JSProcess] = []

    /// A repeating timer that triggers process scanning.
    private var timer: Timer?

    /// The set of runtime names we're looking for in the process list.
    private let targets = Set(["node", "bun", "deno"])

    /// How often we scan when the popover is open (user is looking).
    private static let activePollInterval: TimeInterval = 2.0
    /// How often we scan when the popover is closed (just updating the menu bar count).
    private static let idlePollInterval: TimeInterval = 10.0

    /// Whether the popover is currently visible. Controls the polling speed.
    /// Call `setActive(true)` when the popover opens, `setActive(false)` when it closes.
    var isActive: Bool = false {
        didSet {
            guard isActive != oldValue else { return }
            // When becoming active, do an immediate refresh so the data is fresh,
            // then switch the timer to the faster interval.
            if isActive { fetchProcesses() }
            restartTimer()
        }
    }

    init() {
        // Do an initial scan immediately on startup.
        fetchProcesses()
        // Start with idle polling — popover isn't open yet.
        restartTimer()
    }

    /// Called when the object is destroyed — stops the timer to avoid leaking resources.
    deinit {
        timer?.invalidate()
    }

    /// Replaces the current timer with one using the appropriate interval.
    private func restartTimer() {
        timer?.invalidate()
        let interval = isActive ? Self.activePollInterval : Self.idlePollInterval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.fetchProcesses()
            }
        }
    }

    /// Kicks off an async process scan. Updates `self.processes` when done.
    func fetchProcesses() {
        // Task { } launches concurrent work. `await` suspends until the result is ready
        // without blocking the main thread, so the UI stays responsive.
        Task {
            let found = await Self.runPS(targets: targets)
            self.processes = found
        }
    }

    /// Runs the `ps` command to find JS runtime processes, then runs `lsof` to find
    /// which ports they're listening on. Returns the combined results.
    ///
    /// This runs on a background thread to avoid blocking the UI.
    private static func runPS(targets: Set<String>) async -> [JSProcess] {
        // withCheckedContinuation bridges callback-based code to async/await.
        // We call continuation.resume() exactly once when we have the result.
        await withCheckedContinuation { continuation in
            // DispatchQueue.global runs this closure on a background thread.
            // .utility QoS = low priority, won't compete with UI work.
            DispatchQueue.global(qos: .utility).async {

                // --- Step 1: Run `ps` to list all processes ---

                // Process() is Swift's API for running shell commands.
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/bin/ps")
                // -a: all users, -x: include processes without a terminal,
                // -o: custom output format. The "=" suffix removes the column header.
                // We get: PID, PPID (parent), ETIME (elapsed time), COMM (executable path, truncated),
                // ARGS (full command line).
                // PPID is needed to propagate listening ports from child processes
                // (e.g. `bun dev` spawns `node` which spawns `next-server` that owns the port).
                task.arguments = ["-axo", "pid=,ppid=,etime=,comm=,args="]

                // Pipe captures the command's stdout so we can read it.
                let outPipe = Pipe()
                task.standardOutput = outPipe
                // Discard stderr — we don't need error output from ps.
                task.standardError = FileHandle.nullDevice

                do {
                    try task.run()
                } catch {
                    continuation.resume(returning: [])
                    return
                }

                // IMPORTANT: Read the pipe BEFORE calling waitUntilExit().
                // If we wait first, and ps output exceeds the ~64KB pipe buffer,
                // ps blocks trying to write, and waitUntilExit() never returns.
                // This is a classic Unix pipe deadlock.
                let data = outPipe.fileHandleForReading.readDataToEndOfFile()
                task.waitUntilExit()

                guard let output = String(data: data, encoding: .utf8) else {
                    continuation.resume(returning: [])
                    return
                }

                // --- Step 2: Parse ps output ---
                //
                // We need two things from the full process list:
                // 1. Target processes (node/bun/deno) — what we show to the user
                // 2. A parent→children map for ALL processes — so we can propagate
                //    listening ports from child processes up to their detected parents
                //
                // Example: `bun dev` spawns `node .../next dev` which spawns
                // `next-server` that owns port 3000. Without propagation, bun shows
                // as "Background" because it doesn't directly own any ports.

                // Each line looks like: "  12345  12000    5:03 /usr/bin/node  node /path/to/server.js"
                // Fields: PID, PPID, ETIME (elapsed time), COMM, ARGS...
                var entries: [(pid: Int, ppid: Int, name: String, args: String, uptime: TimeInterval)] = []
                var childrenOf: [Int: [Int]] = [:]  // ppid → [child pids] for ALL processes
                var ppidOf: [Int: Int] = [:]         // pid → ppid for ALL processes
                var argsOf: [Int: String] = [:]      // pid → args for ALL processes (for framework detection in subtrees)

                for line in output.components(separatedBy: "\n") {
                    let parts = line
                        .trimmingCharacters(in: .whitespaces)
                        .components(separatedBy: .whitespaces)
                        .filter { !$0.isEmpty }

                    // parts[0] = PID, parts[1] = PPID, parts[2] = ETIME, parts[3] = COMM, parts[4..] = ARGS
                    guard parts.count >= 4,
                          let pid = Int(parts[0]),
                          let ppid = Int(parts[1]) else { continue }

                    // Build parent↔child maps for every process on the system.
                    childrenOf[ppid, default: []].append(pid)
                    ppidOf[pid] = ppid
                    argsOf[pid] = parts.dropFirst(4).joined(separator: " ")

                    // Parse elapsed time from ps. Format is [[DD-]HH:]MM:SS.
                    let uptime = parseEtime(parts[2])

                    // macOS truncates the COMM field to ~15 chars, so a node binary
                    // managed by fnm at "/Users/me/.local/state/fnm_multishells/.../bin/node"
                    // shows up as "/Users/me/.loca" in COMM — useless for matching.
                    //
                    // Instead we also check argv[0] from the ARGS field (parts[4]),
                    // which has the full untruncated path. We extract the filename
                    // (basename) from both and see if either matches our targets.
                    //
                    // Uses simple string slicing instead of creating URL objects —
                    // this runs for every process on the system, so it matters.
                    let execBasename = basename(parts.count >= 5 ? parts[4] : parts[3])
                    let commBasename = basename(parts[3])
                    guard let name = [execBasename, commBasename].first(where: { targets.contains($0) }) else { continue }

                    // Everything after PID, PPID, ETIME, and COMM is the full command line.
                    let args = parts.dropFirst(4).joined(separator: " ")
                    entries.append((pid: pid, ppid: ppid, name: name, args: args, uptime: uptime))
                }

                // --- Step 3: Get listening ports for the discovered processes ---
                //
                // We pass ALL PIDs (not just targets) so we can find ports owned
                // by non-target child processes (like next-server spawned by bun).
                // fetchListeningPorts already scans all TCP listeners, so this
                // just means we don't filter the results down too early.

                let portMap = fetchListeningPorts()

                // --- Step 3b: Propagate child ports up to target ancestors ---
                //
                // Walk each target's descendant tree and collect any ports owned
                // by descendants. This handles chains like:
                //   bun dev → node next dev → next-server (owns :3000)
                // The bun process inherits port 3000 from its grandchild.

                let targetPids = Set(entries.map(\.pid))
                var effectivePorts: [Int: Set<UInt16>] = [:]

                // Initialize with directly owned ports.
                for entry in entries {
                    if let ports = portMap[entry.pid] {
                        effectivePorts[entry.pid] = Set(ports)
                    }
                }

                // Collect all ports and args from the entire descendant subtree of a PID.
                // Args are collected so we can detect frameworks in child processes
                // (e.g. `bun dev` spawns `node .../next dev` — "next" is in the child's args).
                func descendantInfo(of pid: Int) -> (ports: Set<UInt16>, args: [String]) {
                    var ports = Set<UInt16>()
                    var args: [String] = []
                    guard let children = childrenOf[pid] else { return (ports, args) }
                    for child in children {
                        if let childPorts = portMap[child] {
                            ports.formUnion(childPorts)
                        }
                        if let childArgs = argsOf[child], !childArgs.isEmpty {
                            args.append(childArgs)
                        }
                        let sub = descendantInfo(of: child)
                        ports.formUnion(sub.ports)
                        args.append(contentsOf: sub.args)
                    }
                    return (ports, args)
                }

                var descendantArgsByPid: [Int: [String]] = [:]
                for entry in entries {
                    let info = descendantInfo(of: entry.pid)
                    if !info.ports.isEmpty {
                        effectivePorts[entry.pid, default: []].formUnion(info.ports)
                    }
                    if !info.args.isEmpty {
                        descendantArgsByPid[entry.pid] = info.args
                    }
                }

                // --- Step 3c: Remove child target processes whose parent is also a target ---
                //
                // When `bun dev` spawns `node .../next dev`, we don't want to show both.
                // Keep the topmost target ancestor and remove the child.
                // The parent already inherited the child's ports in step 3b.
                //
                // We need to walk up the full process tree (not just target entries)
                // because the chain can go through non-target intermediaries:
                //   bun(target) → sh(not target) → node(target)

                let childTargetPids = Set(entries.compactMap { entry -> Int? in
                    // Walk up the parent chain — if any ancestor is also a target, this
                    // entry is a child that should be hidden (its parent shows its ports).
                    var current = entry.ppid
                    while current > 1 {
                        if targetPids.contains(current) { return entry.pid }
                        current = ppidOf[current] ?? 0
                    }
                    return nil
                })

                let filteredEntries = entries.filter { !childTargetPids.contains($0.pid) }

                // --- Step 4: Combine everything into JSProcess objects ---

                let found = filteredEntries.map { entry in
                    JSProcess(
                        id: entry.pid, pid: entry.pid, name: entry.name,
                        args: entry.args,
                        descendantArgs: descendantArgsByPid[entry.pid] ?? [],
                        ports: effectivePorts[entry.pid].map { $0.sorted() } ?? [],
                        uptime: entry.uptime
                    )
                }

                // Return the result to the async caller.
                continuation.resume(returning: found)
            }
        }
    }

    /// Extracts the last path component from a path string using simple string ops.
    /// e.g. "/usr/local/bin/node" → "node", "node" → "node"
    /// Avoids creating URL objects for every line of ps output.
    private static func basename(_ path: String) -> String {
        if let lastSlash = path.lastIndex(of: "/") {
            return String(path[path.index(after: lastSlash)...])
        }
        return path
    }

    /// Parses the `etime` field from `ps` into seconds.
    /// Format is [[DD-]HH:]MM:SS — e.g. "05:03", "1:23:45", "2-10:30:00".
    private static func parseEtime(_ etime: String) -> TimeInterval {
        // Split on "-" first to separate days: "2-10:30:00" → days=2, rest="10:30:00"
        let dayParts = etime.split(separator: "-", maxSplits: 1)
        let days: Int
        let timePart: String
        if dayParts.count == 2 {
            days = Int(dayParts[0]) ?? 0
            timePart = String(dayParts[1])
        } else {
            days = 0
            timePart = etime
        }

        // Split time on ":" → could be [MM, SS] or [HH, MM, SS]
        let parts = timePart.split(separator: ":").compactMap { Int($0) }
        let hours: Int, minutes: Int, seconds: Int
        switch parts.count {
        case 3: (hours, minutes, seconds) = (parts[0], parts[1], parts[2])
        case 2: (hours, minutes, seconds) = (0, parts[0], parts[1])
        default: return 0
        }

        return TimeInterval(days * 86400 + hours * 3600 + minutes * 60 + seconds)
    }

    /// Runs `lsof` to find all TCP ports currently in LISTEN state, then returns
    /// a dictionary mapping each PID to its sorted list of listening ports.
    ///
    /// Returns ports for ALL listening processes (not filtered to specific PIDs)
    /// so that child process ports can be propagated up to their target parents.
    private static func fetchListeningPorts() -> [Int: [UInt16]] {

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        // -iTCP: only show TCP sockets
        // -sTCP:LISTEN: only sockets in LISTEN state (not established connections)
        // -nP: don't resolve hostnames or port names (faster, gives raw numbers)
        // -Fn: output in machine-readable format (one field per line, prefixed by type)
        task.arguments = ["-iTCP", "-sTCP:LISTEN", "-nP", "-Fn"]

        let outPipe = Pipe()
        task.standardOutput = outPipe
        task.standardError = FileHandle.nullDevice

        do { try task.run() } catch { return [:] }

        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()

        guard let output = String(data: data, encoding: .utf8) else { return [:] }

        // lsof -Fn outputs one field per line with a single-char prefix:
        //   "p" = PID,  "n" = network name (host:port)
        //
        // Example output:
        //   p12345           ← process 12345
        //   n127.0.0.1:3000  ← listening on localhost:3000
        //   n[::1]:3000      ← same port on IPv6
        //   p67890           ← next process
        //   n*:8080          ← listening on all interfaces, port 8080
        var result: [Int: Set<UInt16>] = [:]  // Set to deduplicate (IPv4 + IPv6 same port)
        var currentPid: Int?

        for line in output.components(separatedBy: "\n") {
            if line.hasPrefix("p"), let pid = Int(line.dropFirst()) {
                currentPid = pid
            } else if line.hasPrefix("n"), let pid = currentPid {
                // Network name line — extract the port number after the last ":".
                if let colonIdx = line.lastIndex(of: ":"),
                   let port = UInt16(line[line.index(after: colonIdx)...]) {
                    // `result[pid, default: []]` creates an empty Set if the key
                    // doesn't exist yet, then inserts the port into it.
                    result[pid, default: []].insert(port)
                }
            }
        }

        // Convert Sets to sorted Arrays for consistent display order.
        return result.mapValues { $0.sorted() }
    }

    /// Sends SIGTERM to a process to gracefully shut it down.
    /// SIGTERM (not SIGKILL/9) lets the process run cleanup handlers
    /// (e.g. closing database connections, removing temp files).
    func kill(pid: Int) {
        Darwin.kill(pid_t(pid), SIGTERM)

        // Wait 0.5s then rescan — gives the process time to actually terminate
        // before we refresh the list.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.fetchProcesses()
        }
    }
}
