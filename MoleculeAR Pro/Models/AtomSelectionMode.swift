//
//  AtomSelectionMode.swift
//  MoleculeAR Pro
//
//  Created by Myles Slack on 2025.06.24.
//
import Foundation

public enum InteractionMode: String, Codable, CaseIterable, Identifiable {
    case inspect = "Inspect"
    case edit = "Edit"
    
    public var id: String { rawValue }
}

enum AtomSelectionMode: String, CaseIterable, Identifiable, Codable {
    case none
    case single
    case multiple
    case box

    var id: Self { self }
}
