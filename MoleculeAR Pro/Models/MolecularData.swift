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

public struct Atom: Codable, Identifiable {
    public let id: UUID // Correct: Declare as `let` without initial value.
                        // It will be initialized by one of the custom initializers.
    public let symbol: String
    public let position: SIMD3<Float>
    
    // MARK: - Codable Conformance
    
    // Define CodingKeys for all properties we want to encode/decode
    // This is required when providing custom initializers.
    private enum CodingKeys: String, CodingKey {
        case id, symbol, position
    }
    
    // Custom Decodable initializer: handles decoding 'id' or generating a new one
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Decode 'id' if present, otherwise generate a new UUID.
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.symbol = try container.decode(String.self, forKey: .symbol)
        self.position = try container.decode(SIMD3<Float>.self, forKey: .position)
    }
    
    // Custom Encodable method: handles encoding all properties
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(symbol, forKey: .symbol)
        try container.encode(position, forKey: .position)
    }
    
    // MARK: - Regular Initializer (for creating Atoms in code)
    
    // Convenience initializer for creating Atom instances directly in code.
    // It provides a default UUID, allowing you to omit it if a new one is desired.
    public init(id: UUID = UUID(), symbol: String, position: SIMD3<Float>) {
        self.id = id
        self.symbol = symbol
        self.position = position
    }
}

public struct Bond: Codable, Identifiable {
    public let id: UUID // Correct: Declare as `let` without initial value
    public let atom1Index: Int
    public let atom2Index: Int
    public let order: Int
    
    // MARK: - Codable Conformance
    
    // Define CodingKeys for all properties we want to encode/decode
    private enum CodingKeys: String, CodingKey {
        case id, atom1Index, atom2Index, order
    }
    
    // Custom Decodable initializer
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.atom1Index = try container.decode(Int.self, forKey: .atom1Index)
        self.atom2Index = try container.decode(Int.self, forKey: .atom2Index)
        self.order = try container.decode(Int.self, forKey: .order)
    }
    
    // Custom Encodable method
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(atom1Index, forKey: .atom1Index)
        try container.encode(atom2Index, forKey: .atom2Index)
        try container.encode(order, forKey: .order)
    }
    
    // MARK: - Regular Initializer (for creating Bonds in code)
    
    // Convenience initializer for creating Bond instances directly in code.
    public init(id: UUID = UUID(), atom1Index: Int, atom2Index: Int, order: Int) {
        self.id = id
        self.atom1Index = atom1Index
        self.atom2Index = atom2Index
        self.order = order
    }
}
