import Foundation
import Combine

@MainActor
class ProcessManager: ObservableObject {
    @Published var processes: [JSProcess] = []

    private var timer: Timer?
    private let targets = Set(["node", "bun", "deno"])

    init() {
        fetchProcesses()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.fetchProcesses()
            }
        }
    }

    deinit {
        timer?.invalidate()
    }

    func fetchProcesses() {
        Task {
            let found = await Self.runPS(targets: targets)
            self.processes = found
        }
    }

    private static func runPS(targets: Set<String>) async -> [JSProcess] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/bin/ps")
                task.arguments = ["-axo", "pid=,comm=,args="]

                let outPipe = Pipe()
                let errPipe = Pipe()
                task.standardOutput = outPipe
                task.standardError = errPipe

                do {
                    try task.run()
                    task.waitUntilExit()
                } catch {
                    continuation.resume(returning: [])
                    return
                }

                let data = outPipe.fileHandleForReading.readDataToEndOfFile()
                guard let output = String(data: data, encoding: .utf8) else {
                    continuation.resume(returning: [])
                    return
                }

                let found: [JSProcess] = output
                    .components(separatedBy: "\n")
                    .compactMap { line in
                        let parts = line
                            .trimmingCharacters(in: .whitespaces)
                            .components(separatedBy: .whitespaces)
                            .filter { !$0.isEmpty }

                        guard parts.count >= 2,
                              let pid = Int(parts[0]) else { return nil }

                        let comm = URL(fileURLWithPath: parts[1]).lastPathComponent
                        guard targets.contains(comm) else { return nil }

                        let args = parts.dropFirst(2).joined(separator: " ")
                        return JSProcess(id: pid, pid: pid, name: comm, args: args)
                    }

                continuation.resume(returning: found)
            }
        }
    }

    func kill(pid: Int) {
        // SIGTERM for graceful shutdown — dev servers handle cleanup on SIGTERM
        // Do NOT use SIGKILL (9) as first signal — it prevents cleanup handlers from running
        Darwin.kill(pid_t(pid), SIGTERM)

        // Refresh after 0.5s — gives the process time to terminate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.fetchProcesses()
        }
    }
}
