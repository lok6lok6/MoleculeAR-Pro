//
//  AppPreferencesViewModel.swift
//  MoleculeAR Pro
//
//  Created by Myles Slack on 2025.06.23.
//
import SwiftUI

@MainActor
final class AppPreferencesViewModel: ObservableObject {
    @Published var isDarkModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isDarkModeEnabled, forKey: "isDarkModeEnabled")
        }
    }
    @Published var isPreviewModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isPreviewModeEnabled, forKey: "isPreviewModeEnabled")
        }
    }
    
    @Published var visualizationStyle: VisualizationStyle {
        didSet {
            UserDefaults.standard.set(visualizationStyle.rawValue, forKey: "visualizationStyle")
        }
    }
    init() {
        // Initialize isDarkModeEnabled from UserDefaults, default to false if not found.
        self.isDarkModeEnabled = UserDefaults.standard.bool(forKey: "isDarkModeEnabled")
        
        // Initialize isPreviewModeEnabled from UserDefaults, default to false if not found.
        self.isPreviewModeEnabled = UserDefaults.standard.bool(forKey: "isPreviewModeEnabled")
        
        // Initialize visualizationStyle from UserDefaults.
        // 1. Try to retrieve the saved String rawValue.
        if let savedStyleString = UserDefaults.standard.string(forKey: "visualizationStyle"),
           // 2. Attempt to create a VisualizationStyle enum case from the saved String.
           // This uses the Failable Initializer `VisualizationStyle(rawValue:)` provided by `RawRepresentable`.
           let savedStyle = VisualizationStyle(rawValue: savedStyleString) {
            self.visualizationStyle = savedStyle
        } else {
            // 3. If no style is saved or if the saved string is invalid, default to .ballAndStick.
            // This ensures a consistent starting point for new users or after app resets.
            self.visualizationStyle = .ballAndStick
        }
    }
}
