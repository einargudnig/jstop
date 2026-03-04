import SwiftUI

/// The main content view shown when the menu bar icon is clicked.
/// Splits processes into "Dev Servers" (with listening ports) and
/// "Background" (tooling, MCP servers, etc.) which is collapsed by default.
struct ProcessListView: View {
    @ObservedObject var manager: ProcessManager

    // Whether the "Background" section is expanded. Collapsed by default
    // so dev servers are front and center.
    @State private var showBackground = false

    // Split processes into two groups based on whether they have listening ports.
    private var devServers: [JSProcess] {
        manager.processes.filter { !$0.ports.isEmpty }
    }
    private var backgroundProcesses: [JSProcess] {
        manager.processes.filter { $0.ports.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ---- Header ----
            HStack {
                Text("jstop")
                    .font(.headline)
                Spacer()
                if !manager.processes.isEmpty {
                    Text("\(manager.processes.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            if manager.processes.isEmpty {
                // ---- Empty state ----
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text("No JS processes running")
                        .foregroundColor(.secondary)
                        .font(.callout)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // ---- Dev Servers section ----
                        // Processes with listening ports — the ones you actually care about.
                        if !devServers.isEmpty {
                            sectionHeader("Dev Servers", count: devServers.count)
                            ForEach(devServers) { process in
                                ProcessRowView(process: process, manager: manager)
                                Divider().padding(.leading, 12)
                            }
                        }

                        // ---- Background section ----
                        // Tooling processes (MCP servers, language servers, etc.)
                        // collapsed by default to reduce noise.
                        if !backgroundProcesses.isEmpty {
                            // Clickable header toggles the section open/closed.
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    showBackground.toggle()
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    // Chevron rotates to indicate open/closed state.
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .rotationEffect(.degrees(showBackground ? 90 : 0))
                                    Text("Background")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(verbatim: "\(backgroundProcesses.count)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(Color.secondary.opacity(0.12))
                                        .cornerRadius(3)
                                    Spacer()
                                }
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)

                            if showBackground {
                                ForEach(backgroundProcesses) { process in
                                    ProcessRowView(process: process, manager: manager)
                                    Divider().padding(.leading, 12)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 400)
            }

            Divider()

            // ---- Quit button ----
            Button("Quit jstop") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 320)
        // When the popover appears/disappears, toggle the polling speed.
        // onAppear fires when the user clicks the menu bar icon (popover opens).
        // onDisappear fires when the popover closes.
        .onAppear { manager.isActive = true }
        .onDisappear { manager.isActive = false }
    }

    /// A small section header with a label and count badge.
    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(verbatim: "\(count)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(Color.secondary.opacity(0.12))
                .cornerRadius(3)
            Spacer()
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
