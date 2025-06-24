//
//  FamilOSApp.swift
//  FamilOS
//
//  Created by Camilo Nunez on 23-06-25.
//

import SwiftUI

@main
struct FamilOSApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .preferredColorScheme(colorScheme)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
    }
    
    // Implementación básica para preferencia de tema
    private var colorScheme: ColorScheme? {
        let temaModo = UserDefaults.standard.integer(forKey: "tema")
        switch temaModo {
        case 1: return .light
        case 2: return .dark
        default: return nil // Seguir tema del sistema
        }
    }
}
