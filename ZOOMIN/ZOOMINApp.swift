// ZOOMINApp.swift
// ZOOMIN - 앱 진입점
// 역할: @main 앱 구조체, ContentView를 루트로 설정

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
