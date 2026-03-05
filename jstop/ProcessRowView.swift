import SwiftUI

struct ProcessRowView: View {
    let process: JSProcess
    @ObservedObject var manager: ProcessManager

    @State private var isHovering = false
    @State private var isKilling = false

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Colored alive dot
            Circle()
                .fill(process.ports.isEmpty ? Color.secondary.opacity(0.4) : Color.green)
                .frame(width: 7, height: 7)
                .shadow(color: process.ports.isEmpty ? .clear : .green.opacity(0.5), radius: 4)

            VStack(alignment: .leading, spacing: 4) {
                // Top row: framework badge + PID + ports
                HStack(spacing: 6) {
                    // Framework badge with brand color
                    Text(process.framework)
                        .font(.system(.callout, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(process.frameworkColor)

                    Text("PID \(process.pid)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.7))

                    ForEach(process.ports, id: \.self) { port in
                        Button {
                            if let url = URL(string: "http://localhost:\(port)") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            Text(verbatim: ":\(port)")
                                .font(.system(.caption, design: .monospaced))
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(isHovering ? 0.18 : 0.10))
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        .help("Open http://localhost:\(port)")
                    }
                }

                // Bottom row: path + uptime
                HStack(spacing: 0) {
                    Text(process.shortPath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text("  ·  \(process.uptimeString)")
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary.opacity(0.7))
            }

            Spacer(minLength: 4)

            // Kill button — appears more prominently on hover
            Button {
                withAnimation(.easeOut(duration: 0.3)) {
                    isKilling = true
                }
                // Delay the actual kill so the animation plays
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    manager.kill(pid: process.pid)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red.opacity(isHovering ? 0.9 : 0.4))
                    .scaleEffect(isHovering ? 1.0 : 0.85)
            }
            .buttonStyle(.plain)
            .help("Kill process \(process.pid)")
            .animation(.easeOut(duration: 0.15), value: isHovering)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isKilling ? Color.red.opacity(0.12) :
                      isHovering ? Color.primary.opacity(0.04) : Color.clear)
        )
        .opacity(isKilling ? 0 : 1)
        .offset(x: isKilling ? 60 : 0)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
