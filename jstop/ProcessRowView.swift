import SwiftUI

/// A single row in the process list, showing the runtime name, PID, ports,
/// a short project path, and a kill button.
struct ProcessRowView: View {
    let process: JSProcess
    // @ObservedObject so we can call manager.kill() from the button.
    @ObservedObject var manager: ProcessManager

    var body: some View {
        // Top-level horizontal layout: process info on the left, kill button on the right.
        HStack(alignment: .top, spacing: 8) {
            // Left side: stacked vertically — top row of badges, bottom row path.
            VStack(alignment: .leading, spacing: 2) {
                // Top row: runtime name + PID badge + port badges.
                HStack(spacing: 6) {
                    // Runtime name (e.g. "node") in monospaced bold.
                    Text(process.name)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)

                    // PID shown as a small grey pill/badge.
                    Text("PID \(process.pid)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.12))
                        .cornerRadius(3)

                    // One blue badge per listening port.
                    // Clicking a port badge opens http://localhost:PORT in the browser.
                    // `verbatim:` prevents SwiftUI from applying locale number
                    // formatting (e.g. "5.173" in Icelandic locale → "5173").
                    ForEach(process.ports, id: \.self) { port in
                        Button {
                            if let url = URL(string: "http://localhost:\(port)") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            Text(verbatim: ":\(port)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Color.blue.opacity(0.10))
                                .cornerRadius(3)
                        }
                        .buttonStyle(.plain)
                        .help("Open http://localhost:\(port) in browser")
                    }
                }

                // Second row: short project path + uptime.
                HStack(spacing: 4) {
                    Text(process.shortPath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    // Uptime shown as a subtle clock label (e.g. "2h 15m").
                    Text("· \(process.uptimeString)")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }

            // Push the kill button to the right edge.
            Spacer(minLength: 4)

            // Kill button — sends SIGTERM to gracefully stop the process.
            Button {
                manager.kill(pid: process.pid)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red.opacity(0.75))
            }
            .buttonStyle(.plain) // Remove default button chrome.
            .help("Kill process \(process.pid)") // Tooltip on hover.
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
