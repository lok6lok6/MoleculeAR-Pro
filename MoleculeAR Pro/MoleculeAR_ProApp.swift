//
//  MoleculeAR_ProApp.swift
//  MoleculeAR Pro
//
//  Created by Myles Slack on 2025.06.23.
//

import SwiftUI

@main
struct MoleculeAR_ProApp: App {
    // These are your top-level state objects, managing app-wide preferences and molecule data.
    @StateObject private var appPreferences: AppPreferencesViewModel
    @StateObject private var moleculeVM: MoleculeViewModel
    
    // Custom initializer to correctly inject AppPreferencesViewModel into MoleculeViewModel
    init() {
        // Initialize the wrappedValue directly.
        // For app-level StateObjects that are conceptually singletons for the app lifecycle,
        // this is a clean way to ensure they are available.
        let preferencesInstance = AppPreferencesViewModel()
        _appPreferences = StateObject(wrappedValue: preferencesInstance)
        
        // Then initialize moleculeVM, passing the wrappedValue of appPreferences
        // .wrappedValue gives you the actual AppPreferencesViewModel instance.
        _moleculeVM = StateObject(wrappedValue: MoleculeViewModel(appPreferences: preferencesInstance))
    }
    
    var body: some Scene {
        WindowGroup {
            // RootView is your main content view.
            // We provide the ObservableObjects to the environment, making them accessible
            // to any descendant views using @EnvironmentObject.
            RootView()
                .environmentObject(appPreferences) // Provides AppPreferencesViewModel to the environment
                .environmentObject(moleculeVM)    // Provides MoleculeViewModel to the environment
        }
    }
}
