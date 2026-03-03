import SwiftUI

struct ProcessListView: View {
    @StateObject private var manager = ProcessManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Node Processes")
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
                // Empty state
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
                // Process list — capped at 400pt to keep popover manageable
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(manager.processes) { process in
                            ProcessRowView(process: process, manager: manager)
                            Divider()
                                .padding(.leading, 12)
                        }
                    }
                }
                .frame(maxHeight: 400)
            }

            Divider()

            // Quit button — necessary since app has no Dock icon
            Button("Quit Node Processes") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 320)
    }
}
