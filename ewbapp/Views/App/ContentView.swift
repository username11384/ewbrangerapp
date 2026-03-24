import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appEnv: AppEnvironment
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        if authManager.isAuthenticated {
            MainTabView()
        } else {
            LoginView()
        }
    }
}
