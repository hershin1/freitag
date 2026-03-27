import SwiftUI
import SwiftData

@main
struct FreitagApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try SharedModelContainer.create()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
