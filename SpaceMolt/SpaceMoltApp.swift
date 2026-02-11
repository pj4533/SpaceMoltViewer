import SwiftUI

@main
struct SpaceMoltApp: App {
    @State private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(appViewModel: appViewModel)
                .frame(minWidth: 900, minHeight: 600)
        }
    }
}
