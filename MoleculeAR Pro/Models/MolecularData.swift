//
//  MolecularData.swift
//  MoleculeAR Pro
//
//  Created by Myles Slack on 2025.06.24.
//
import Foundation
import simd

struct MolecularData: Codable, Identifiable {
    let id: UUID
    let atoms: [Atom]
    let bonds: [Bond]
    
    init(id: UUID = UUID(), atoms: [Atom], bonds: [Bond]) {
        self.id = id
        self.atoms = atoms
        self.bonds = bonds
    }
    
    //MARK: - Static Example for testing
    static func example() -> MolecularData{
        let atoms: [Atom] = [
            Atom(symbol: "C", position: SIMD3<Float>(0,0,0)),
            Atom(symbol: "O", position: SIMD3<Float>(1.2,0,0))
        ]
        
        let bonds: [Bond] = [
            Bond(atom1Index: 0, atom2Index: 1, order: 2)
        ]
        
        return MolecularData(atoms: atoms, bonds: bonds)
    }
}

struct Atom: Codable {
    let id: UUID = UUID()
    let symbol: String
    let position: SIMD3<Float>
    
    enum CodingKeys: String, CodingKey {
        case symbol, position
    }
}

struct Bond: Codable {
    let id: UUID = UUID()
    let atom1Index: Int
    let atom2Index: Int
    let order: Int
    
    enum CodingKeys: String, CodingKey {
        case atom1Index, atom2Index, order
    }
}
