import SwiftUI

// @main marks this as the app's entry point (like main() in other languages).
// In SwiftUI, the App protocol defines the top-level structure of your app.
@main
struct jstopApp: App {
    init() {
        // MenuBarExtra's content closure is lazy — it only runs when you click
        // the menu bar icon. We access the shared ProcessManager here to force
        // it to initialize immediately so it starts scanning for processes
        // right when the app launches, not on first click.
        _ = ProcessManager.shared
    }

    // @ObservedObject so the label re-renders when the process count changes.
    @ObservedObject private var manager = ProcessManager.shared

    // `body` describes what the app shows. Instead of a normal window,
    // we use MenuBarExtra to put an icon in the macOS menu bar.
    var body: some Scene {
        MenuBarExtra {
            // This view appears as a popover when the menu bar icon is clicked.
            ProcessListView(manager: manager)
        } label: {
            // The menu bar label: terminal icon + process count (if any).
            // HStack lays them out side by side in the menu bar.
            HStack(spacing: 2) {
                Image(systemName: "terminal")
                if !manager.processes.isEmpty {
                    Text(verbatim: "\(manager.processes.count)")
                        .font(.caption2)
                }
            }
        }
        // .window style gives us a proper popover with custom SwiftUI layout,
        // as opposed to the default .menu style which looks like a plain menu.
        .menuBarExtraStyle(.window)
    }
}
