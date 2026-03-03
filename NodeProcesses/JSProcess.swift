import Foundation

struct JSProcess: Identifiable {
    let id: Int          // same as pid, for Identifiable conformance
    let pid: Int
    let name: String     // "node", "bun", or "deno"
    let args: String     // full command line (may be long)
}
