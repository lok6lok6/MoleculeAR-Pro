//
//  MoleculeViewModel.swift
//  MoleculeAR Pro
//
//  Created by Myles Slack on 2025.06.23.
//
import SwiftUI
import Combine

final class MoleculeViewModel: ObservableObject {
    
    @Published var molecule: MoleculeData? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var selectedAtomIndex: Int? = nil
    @Published var selectionMode: AtomSelectionMode = .none
    // MARK: - Init
    init(){
        //For now , staart with nothing loaded
    }
    
    // MARK: - load molecule File
    func loadMoleculeFile(from url: URL) {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let parsed = try MolecularParser.parse(from: url)
                DispatchQueue.main.async {
                    self.molecule = parsed
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to load molecule: \(error.localizedDescription)"
                }
            }
        }
    }
    func clearMolecule(){
        molecule = nil
    }
}


