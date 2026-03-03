import SwiftUI

struct ProcessListView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Node Processes")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Placeholder content — replaced in Phase 2
            VStack(spacing: 6) {
                Image(systemName: "terminal")
                    .font(.system(size: 28))
                    .foregroundColor(.secondary)
                Text("No processes running")
                    .foregroundColor(.secondary)
                    .font(.callout)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)

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
