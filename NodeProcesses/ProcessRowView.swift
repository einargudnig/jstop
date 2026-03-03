import SwiftUI

struct ProcessRowView: View {
    let process: JSProcess
    @ObservedObject var manager: ProcessManager

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(process.name)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                    Text("PID \(process.pid)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.12))
                        .cornerRadius(3)
                }
                Text(process.args)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 4)

            // Kill button
            Button {
                manager.kill(pid: process.pid)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red.opacity(0.75))
            }
            .buttonStyle(.plain)
            .help("Kill process \(process.pid)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
