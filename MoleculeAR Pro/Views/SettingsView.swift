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
            
            // --- ADDED: Visualization Style Picker (if you want it in Settings too) ---
            Section(header: Text("Visualization Style")) {
                Picker("Style", selection: $preferences.visualizationStyle) {
                    ForEach(VisualizationStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            // ----------------------------------------
            
            Section(header: Text("Developer")){
                Toggle("Preview Mode", isOn: $preferences.isPreviewModeEnabled)
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    // Crucial: Provide the AppPreferencesViewModel for the preview to work
    SettingsView()
        .environmentObject(AppPreferencesViewModel()) // <-- Ensure this is present
}
