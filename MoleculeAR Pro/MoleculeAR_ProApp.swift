//
//  MoleculeAR_ProApp.swift
//  MoleculeAR Pro
//
//  Created by Myles Slack on 2025.06.23.
//

import SwiftUI

@main
struct MoleculeAR_ProApp: App {
    @StateObject private var appPreferences = AppPreferencesViewModel()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appPreferences)
        }
    }
}
