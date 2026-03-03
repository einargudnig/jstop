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
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        // pid= comm= args= suppresses column headers; comm is the short process name
        task.arguments = ["-axo", "pid=,comm=,args="]

        let outPipe = Pipe()
        let errPipe = Pipe()
        task.standardOutput = outPipe
        task.standardError = errPipe  // suppress stderr

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            return  // ps unavailable — leave processes unchanged
        }

        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return }

        let found: [JSProcess] = output
            .components(separatedBy: "\n")
            .compactMap { line in
                let parts = line
                    .trimmingCharacters(in: .whitespaces)
                    .components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty }

                guard parts.count >= 2,
                      let pid = Int(parts[0]) else { return nil }

                // comm may be a full path on some systems — use basename
                let comm = URL(fileURLWithPath: parts[1]).lastPathComponent

                guard targets.contains(comm) else { return nil }

                let args = parts.dropFirst(2).joined(separator: " ")
                return JSProcess(id: pid, pid: pid, name: comm, args: args)
            }

        self.processes = found
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
