//
//  VisualizationStyle.swift
//  MoleculeAR Pro
//
//  Created by Myles Slack on 2025.06.27.
//
import Foundation

enum VisualizationStyle: String, CaseIterable, Codable, Identifiable {
    case ballAndStick = "Ball and Stick"
    case spaceFilling = "Space Filling"
    
    var id: String {
        rawValue
    }
}
