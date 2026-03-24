import SwiftUI

@main
struct LamaLamaRangersApp: App {
    @StateObject private var appEnv = AppEnvironment.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appEnv)
                .environmentObject(appEnv.authManager)
                .onAppear {
                    Task {
                        await appEnv.syncEngine.startMonitoring()
                    }
                }
        }
    }
}
