// ZOOMINApp.swift
// ZOOMIN - App entry point
// Role: @main app struct, sets ContentView as root

import SwiftUI
import FirebaseCore

@main
struct ZOOMINApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
