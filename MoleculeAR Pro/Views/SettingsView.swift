//
//  SettingsView.swift
//  MoleculeAR Pro
//
//  Created by Myles Slack on 2025.06.23.
//
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var preferences: AppPreferencesViewModel
    
    var body: some View {
        Form{
            Section(header: Text("Apperance")){
                Toggle("Dark Mode", isOn: $preferences.isDarkModeEnabled)
            }
            
            Section(header: Text("Developer")){
                Toggle("Preview Mode", isOn: $preferences.isPreviewModeEnabled)
            }
        }
        .navigationTitle("Settings")
    }
}
