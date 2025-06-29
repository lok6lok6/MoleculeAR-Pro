//
//  RootView.swift
//  MoleculeAR Pro
//
//  Created by Myles Slack on 2025.06.23.
//
import SwiftUI

struct RootView: View {
    // Inject environment objects that RootView (or its children) will need
    @EnvironmentObject var appPreferences: AppPreferencesViewModel // <-- ADDED THIS
    @EnvironmentObject var moleculeVM: MoleculeViewModel // <-- ADDED THIS

    var body: some View {
        NavigationStack {
            VStack {
                // Molecule3DView is now the main content
                Molecule3DView() // This view correctly picks up @EnvironmentObjects from its ancestors.

                // Example of how you might navigate to settings later
                NavigationLink("Settings") {
                    SettingsView()
                        // SettingsView already uses @EnvironmentObject, so it will receive `preferences`
                        // from the environment provided by MoleculeAR_ProApp (via this RootView)
                }
                .padding()
            }
        }
    }
}

#Preview {
    // CRUCIAL: Provide ALL environment objects needed by the preview
    RootView()
        .environmentObject(AppPreferencesViewModel()) // <-- ADDED THIS
        .environmentObject(MoleculeViewModel(appPreferences: AppPreferencesViewModel())) // <-- ADDED THIS, matching app's init
}
