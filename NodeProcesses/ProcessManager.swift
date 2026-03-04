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
                // We get: PID, ETIME (elapsed time), COMM (executable path, truncated),
                // ARGS (full command line).
                task.arguments = ["-axo", "pid=,etime=,comm=,args="]

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

                // --- Step 2: Parse ps output to find node/bun/deno processes ---

                // Each line looks like: "  12345    5:03 /usr/bin/node  node /path/to/server.js"
                // Fields: PID, ETIME (elapsed time), COMM, ARGS...
                var entries: [(pid: Int, name: String, args: String, uptime: TimeInterval)] = []
                for line in output.components(separatedBy: "\n") {
                    let parts = line
                        .trimmingCharacters(in: .whitespaces)
                        .components(separatedBy: .whitespaces)
                        .filter { !$0.isEmpty }

                    // parts[0] = PID, parts[1] = ETIME, parts[2] = COMM, parts[3..] = ARGS
                    guard parts.count >= 3,
                          let pid = Int(parts[0]) else { continue }

                    // Parse elapsed time from ps. Format is [[DD-]HH:]MM:SS.
                    let uptime = parseEtime(parts[1])

                    // macOS truncates the COMM field to ~15 chars, so a node binary
                    // managed by fnm at "/Users/me/.local/state/fnm_multishells/.../bin/node"
                    // shows up as "/Users/me/.loca" in COMM — useless for matching.
                    //
                    // Instead we also check argv[0] from the ARGS field (parts[3]),
                    // which has the full untruncated path. We extract the filename
                    // (basename) from both and see if either matches our targets.
                    //
                    // Uses simple string slicing instead of creating URL objects —
                    // this runs for every process on the system, so it matters.
                    let execBasename = basename(parts.count >= 4 ? parts[3] : parts[2])
                    let commBasename = basename(parts[2])
                    guard let name = [execBasename, commBasename].first(where: { targets.contains($0) }) else { continue }

                    // Everything after PID, ETIME, and COMM is the full command line.
                    let args = parts.dropFirst(3).joined(separator: " ")
                    entries.append((pid: pid, name: name, args: args, uptime: uptime))
                }

                // --- Step 3: Get listening ports for the discovered processes ---

                let portMap = fetchListeningPorts(pids: entries.map(\.pid))

                // --- Step 4: Combine everything into JSProcess objects ---

                let found = entries.map { entry in
                    JSProcess(
                        id: entry.pid, pid: entry.pid, name: entry.name,
                        args: entry.args, ports: portMap[entry.pid] ?? [],
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
    /// We run lsof once for ALL processes (not per-PID) to keep it fast.
    private static func fetchListeningPorts(pids: [Int]) -> [Int: [UInt16]] {
        guard !pids.isEmpty else { return [:] }

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
        let pidSet = Set(pids)
        var result: [Int: Set<UInt16>] = [:]  // Set to deduplicate (IPv4 + IPv6 same port)
        var currentPid: Int?

        for line in output.components(separatedBy: "\n") {
            if line.hasPrefix("p"), let pid = Int(line.dropFirst()) {
                // New process section — only track it if it's one of ours.
                currentPid = pidSet.contains(pid) ? pid : nil
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
