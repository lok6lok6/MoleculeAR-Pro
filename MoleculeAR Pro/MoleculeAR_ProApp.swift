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
    @StateObject private var moleculeVM = MoleculeViewModel()
    var body: some Scene {
        WindowGroup {
            //Temporarily show Molecule3DView directly for testing
            //RootView()
                //.environmentObject(appPreferences)
            Molecule3DView() // Temporary
                .environmentObject(appPreferences) // Temporary
                .environmentObject(moleculeVM) // Temporory
                    
        }
    }
}
