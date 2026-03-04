import Foundation

/// Represents a single running JavaScript runtime process (node, bun, or deno).
/// Conforms to `Identifiable` so SwiftUI's `ForEach` can efficiently diff the list.
struct JSProcess: Identifiable {
    let id: Int          // same as pid — Identifiable requires a unique `id` property
    let pid: Int         // Unix process ID
    let name: String     // runtime name: "node", "bun", or "deno"
    let args: String     // full command line arguments from `ps`
    let ports: [UInt16]  // TCP ports this process is listening on (from `lsof`)
    let uptime: TimeInterval  // seconds since process started (from `ps etime`)
    let shortPath: String // short project path, computed once at construction

    /// Formats uptime as a short human-readable string.
    /// e.g. "3s", "5m", "2h 15m", "1d 3h"
    var uptimeString: String {
        let total = Int(uptime)
        let days = total / 86400
        let hours = (total % 86400) / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m" }
        return "\(seconds)s"
    }

    /// Creates a JSProcess, computing the short path from args at construction time
    /// so it doesn't need to be recalculated on every render.
    init(id: Int, pid: Int, name: String, args: String, ports: [UInt16], uptime: TimeInterval) {
        self.id = id
        self.pid = pid
        self.name = name
        self.args = args
        self.ports = ports
        self.uptime = uptime
        self.shortPath = Self.extractShortPath(from: args)
    }

    /// Extracts a short, human-readable project path from the full command line args.
    ///
    /// Examples:
    ///   "/Users/me/work/my-app/node_modules/.bin/vite dev" → "me/work/my-app"
    ///   "node /Users/me/.npm/_npx/.../playwright-mcp"      → ".npm/_npx/playwright-mcp"
    private static func extractShortPath(from args: String) -> String {
        // Split args into space-separated tokens and drop empty ones.
        // e.g. "/usr/bin/node /path/to/server.js --port 3000"
        //   → ["/usr/bin/node", "/path/to/server.js", "--port", "3000"]
        let tokens = args.components(separatedBy: " ").filter { !$0.isEmpty }

        // Look for the first token that contains "/" (i.e. looks like a file path).
        // We skip the first token (argv[0], the runtime binary like /usr/bin/node)
        // and prefer later tokens, falling back to argv[0] if nothing else has a path.
        let pathToken: String? = tokens.dropFirst().first(where: { $0.contains("/") })
            ?? tokens.first(where: { $0.contains("/") })

        guard let path = pathToken else {
            // No path found at all — just show the args without the runtime name.
            return tokens.dropFirst().joined(separator: " ")
        }

        // Split the path into its directory components.
        let components = path.components(separatedBy: "/")

        // If the path contains "node_modules", everything after it is package internals
        // (e.g. ".bin/vite") which isn't useful. We strip it and keep the last 3
        // directories before it — that's usually the project folder.
        if let nmIdx = components.firstIndex(of: "node_modules") {
            let projectComponents = Array(components[..<nmIdx])
            let last3 = projectComponents.suffix(3)
            if !last3.isEmpty { return last3.joined(separator: "/") }
        }

        // No node_modules in the path — just take the last 3 meaningful components.
        // Filter out empty strings (from leading "/") and "." (current directory).
        let meaningful = components.filter { !$0.isEmpty && $0 != "." }
        return meaningful.suffix(3).joined(separator: "/")
    }
}
