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
    init() {
        self.isDarkModeEnabled = UserDefaults.standard.bool(forKey: "isDarkModeEnabled")
        self.isPreviewModeEnabled = UserDefaults.standard.bool(forKey: "isPreviewModeEnabled")
    }
}
