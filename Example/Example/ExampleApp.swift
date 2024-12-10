//
//  ExampleApp.swift
//  Example
//
//  Created by Nathan Tannar on 2022-12-06.
//

import SwiftUI

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
            .navigationViewStyle(.stack)
        }
    }
}
