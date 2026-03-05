import SwiftUI

struct ProcessListView: View {
    @ObservedObject var manager: ProcessManager

    @State private var showBackground = false

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
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                Spacer()
                if !manager.processes.isEmpty {
                    Text("\(manager.processes.count) process\(manager.processes.count == 1 ? "" : "es")")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider().opacity(0.5)

            if manager.processes.isEmpty {
                // ---- Empty state ----
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.green.opacity(0.6))
                    Text("All clear")
                        .font(.system(.callout, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text("No JS processes running")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // ---- Dev Servers ----
                        if !devServers.isEmpty {
                            sectionHeader("Dev Servers", count: devServers.count, color: .green)
                            ForEach(devServers) { process in
                                ProcessRowView(process: process, manager: manager)
                            }
                        }

                        // ---- Background ----
                        if !backgroundProcesses.isEmpty {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showBackground.toggle()
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 9, weight: .bold))
                                        .rotationEffect(.degrees(showBackground ? 90 : 0))
                                    Text("Background")
                                        .font(.system(.caption, design: .rounded))
                                        .fontWeight(.medium)
                                    Text(verbatim: "\(backgroundProcesses.count)")
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundColor(.secondary.opacity(0.6))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(Color.secondary.opacity(0.08))
                                        .cornerRadius(3)
                                    Spacer()
                                }
                                .foregroundColor(.secondary.opacity(0.7))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)

                            if showBackground {
                                ForEach(backgroundProcesses) { process in
                                    ProcessRowView(process: process, manager: manager)
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 400)
            }

            Divider().opacity(0.5)

            // ---- Quit ----
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit jstop")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 8)
        }
        .frame(width: 340)
        .onAppear { manager.isActive = true }
        .onDisappear { manager.isActive = false }
    }

    private func sectionHeader(_ title: String, count: Int, color: Color) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color.opacity(0.6))
                .frame(width: 5, height: 5)
            Text(title)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.medium)
            Text(verbatim: "\(count)")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary.opacity(0.6))
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(3)
            Spacer()
        }
        .foregroundColor(.secondary.opacity(0.7))
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}
