import SwiftUI

@main
struct NodeProcessesApp: App {
    var body: some Scene {
        MenuBarExtra {
            ProcessListView()
        } label: {
            Image(systemName: "terminal")
        }
        .menuBarExtraStyle(.window)
    }
}
