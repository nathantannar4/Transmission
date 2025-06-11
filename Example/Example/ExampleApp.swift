//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            AppContentView()
        }
    }
}

struct AppContentView: View {
    var body: some View {
        NavigationView {
            ContentView()
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("Transmission")
        }
        .navigationViewStyle(.stack)
    }
}
