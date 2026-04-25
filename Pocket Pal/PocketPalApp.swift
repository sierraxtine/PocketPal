//
//  PocketPalApp.swift
//  Pocket Pal
//
//  Created by Sierra Christine on 3/11/26.
//


import SwiftUI

@main
struct PocketPalApp: App {
    
    var body: some Scene {
        WindowGroup {
            PocketPalHomeView()
                .preferredColorScheme(.dark) // Force Dark Mode
        }
    }
}