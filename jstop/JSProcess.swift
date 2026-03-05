import Foundation
import SwiftUI

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
    let framework: String // detected framework (e.g. "Next.js", "Vite") or runtime name

    /// Brand color for the detected framework, used for the framework badge.
    var frameworkColor: Color {
        switch framework {
        case "Next.js":     return Color(.sRGB, red: 0.95, green: 0.95, blue: 0.95, opacity: 1) // white-ish
        case "Vite":        return Color(.sRGB, red: 0.55, green: 0.36, blue: 1.0, opacity: 1)  // purple
        case "Nuxt":        return Color(.sRGB, red: 0.0, green: 0.85, blue: 0.52, opacity: 1)  // green
        case "Remix":       return Color(.sRGB, red: 0.35, green: 0.55, blue: 1.0, opacity: 1)  // blue
        case "Astro":       return Color(.sRGB, red: 1.0, green: 0.36, blue: 0.24, opacity: 1)  // orange-red
        case "SvelteKit":   return Color(.sRGB, red: 1.0, green: 0.24, blue: 0.0, opacity: 1)   // svelte orange
        case "Angular":     return Color(.sRGB, red: 0.87, green: 0.16, blue: 0.24, opacity: 1) // red
        case "Gatsby":      return Color(.sRGB, red: 0.4, green: 0.2, blue: 0.8, opacity: 1)    // purple
        case "Expo":        return Color(.sRGB, red: 0.33, green: 0.33, blue: 0.33, opacity: 1) // dark gray
        case "Express":     return Color(.sRGB, red: 0.93, green: 0.82, blue: 0.0, opacity: 1)  // yellow
        case "Fastify":     return Color(.sRGB, red: 0.95, green: 0.95, blue: 0.95, opacity: 1) // white
        case "NestJS":      return Color(.sRGB, red: 0.88, green: 0.15, blue: 0.27, opacity: 1) // red
        case "Storybook":   return Color(.sRGB, red: 1.0, green: 0.28, blue: 0.52, opacity: 1)  // pink
        case "Electron":    return Color(.sRGB, red: 0.18, green: 0.8, blue: 0.82, opacity: 1)  // teal
        case "Wrangler":    return Color(.sRGB, red: 0.97, green: 0.65, blue: 0.14, opacity: 1) // cloudflare orange
        case "Vitest":      return Color(.sRGB, red: 0.45, green: 0.82, blue: 0.09, opacity: 1) // green
        case "Jest":        return Color(.sRGB, red: 0.6, green: 0.2, blue: 0.15, opacity: 1)   // brown-red
        case "Webpack":     return Color(.sRGB, red: 0.55, green: 0.78, blue: 0.93, opacity: 1) // light blue
        case "Turborepo":   return Color(.sRGB, red: 0.94, green: 0.28, blue: 0.52, opacity: 1) // pink
        default:            return Color(.sRGB, red: 0.45, green: 0.65, blue: 1.0, opacity: 1)  // default blue
        }
    }

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
    init(id: Int, pid: Int, name: String, args: String, descendantArgs: [String] = [], ports: [UInt16], uptime: TimeInterval) {
        self.id = id
        self.pid = pid
        self.name = name
        self.args = args
        self.ports = ports
        self.uptime = uptime
        self.shortPath = Self.extractShortPath(from: args)
        // Try detecting framework from own args first, then from descendant args.
        // This handles cases like `bun dev` spawning `node .../next dev` —
        // "bun dev" alone doesn't mention Next.js, but the child's args do.
        let allArgs = [args] + descendantArgs
        self.framework = Self.detectFramework(from: allArgs, runtime: name)
    }

    /// Detects the framework/tool from the command line args (own + descendants).
    /// Returns a human-friendly name like "Next.js" or "Vite", falling back
    /// to the runtime name ("node", "bun", "deno") if nothing is recognized.
    static func detectFramework(from argsArray: [String], runtime: String) -> String {
        // We match against args strings (own first, then children's).
        // Order matters — more specific patterns first (e.g. "next" before "webpack").
        // Patterns check for both direct invocation ("next dev") and
        // node_modules paths (".bin/next", "node_modules/next/...").
        let patterns: [(check: (String) -> Bool, label: String)] = [
            ({ $0.contains("/next ") || $0.contains(".bin/next") || $0.contains("next dev") || $0.contains("next start") || $0.contains("next-server") },  "Next.js"),
            ({ $0.contains("/vite ") || $0.contains(".bin/vite") || $0.contains("vite dev") || $0.contains("vite build") || $0.contains("vite preview") }, "Vite"),
            ({ $0.contains("/nuxt ") || $0.contains(".bin/nuxt") || $0.contains("nuxt dev") || $0.contains("nuxt start") },                                "Nuxt"),
            ({ $0.contains("/remix ") || $0.contains(".bin/remix") || $0.contains("remix dev") },                                                           "Remix"),
            ({ $0.contains("/astro ") || $0.contains(".bin/astro") || $0.contains("astro dev") },                                                           "Astro"),
            ({ $0.contains("/gatsby ") || $0.contains(".bin/gatsby") },                                                                                      "Gatsby"),
            ({ $0.contains("/svelte-kit") || $0.contains(".bin/svelte-kit") },                                                                               "SvelteKit"),
            ({ $0.contains("/angular") || $0.contains(".bin/ng ") || $0.contains("ng serve") },                                                             "Angular"),
            ({ $0.contains("/expo ") || $0.contains(".bin/expo") || $0.contains("expo start") },                                                            "Expo"),
            ({ $0.contains("/react-scripts") || $0.contains(".bin/react-scripts") },                                                                         "CRA"),
            ({ $0.contains("/webpack ") || $0.contains(".bin/webpack") || $0.contains("webpack-dev-server") },                                               "Webpack"),
            ({ $0.contains("/turbo ") || $0.contains(".bin/turbo") },                                                                                        "Turborepo"),
            ({ $0.contains("/esbuild ") || $0.contains(".bin/esbuild") },                                                                                   "esbuild"),
            ({ $0.contains("/tsx ") || $0.contains(".bin/tsx") },                                                                                            "tsx"),
            ({ $0.contains("/ts-node") || $0.contains(".bin/ts-node") },                                                                                    "ts-node"),
            ({ $0.contains("/nodemon") || $0.contains(".bin/nodemon") },                                                                                    "nodemon"),
            ({ $0.contains("/express") },                                                                                                                    "Express"),
            ({ $0.contains("/fastify") },                                                                                                                    "Fastify"),
            ({ $0.contains("/nest ") || $0.contains(".bin/nest") || $0.contains("@nestjs") },                                                               "NestJS"),
            ({ $0.contains("/playwright") },                                                                                                                 "Playwright"),
            ({ $0.contains("/jest ") || $0.contains(".bin/jest") },                                                                                          "Jest"),
            ({ $0.contains("/vitest") || $0.contains(".bin/vitest") },                                                                                       "Vitest"),
            ({ $0.contains("/storybook") || $0.contains(".bin/storybook") || $0.contains("start-storybook") },                                              "Storybook"),
            ({ $0.contains("/electron") || $0.contains(".bin/electron") },                                                                                   "Electron"),
            ({ $0.contains("/wrangler") || $0.contains(".bin/wrangler") },                                                                                   "Wrangler"),
        ]

        // Check own args first, then descendant args — own args take priority.
        for args in argsArray {
            for (check, label) in patterns {
                if check(args) { return label }
            }
        }

        return runtime
    }

    /// Extracts a short, human-readable project path from the full command line args.
    ///
    /// Examples:
    ///   "/Users/me/work/my-app/node_modules/.bin/vite dev" → "me/work/my-app"
    ///   "node /Users/me/.npm/_npx/.../playwright-mcp"      → ".npm/_npx/playwright-mcp"
    static func extractShortPath(from args: String) -> String {
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
