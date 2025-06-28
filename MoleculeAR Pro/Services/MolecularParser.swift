//
//  MolecularParser.swift
//  MoleculeAR Pro
//
//  Created by Myles Slack on 2025.06.24.
//
import Foundation
import simd

struct MolecularParser {
    
    /// Parses molecular data from a given file URL.
    /// Supports a basic .xyz file format for now. Will be extended for others.
    /// - Parameter url: The URL of the molecule file (e.g., .xyz, .pdb, .sdf).
    /// - Returns: A MolecularData struct containing parsed atoms and bonds.
    /// - Throws: `MolecularParsingError` if the file cannot be read or parsed.
    static func parse(from url: URL) throws -> MolecularData {
        // 1. read the file content into a string
        let fileContent: String
        do{
            fileContent = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw MoleculeParsingError.fileReadError("Could not read file at URL: \(url.lastPathComponent) - \(error.localizedDescription)")
        }
        
        // 2. Split the content into individual lines
        let lines = fileContent.split(separator: "\n", omittingEmptySubsequences: true).map { String($0) }
        
        //Ensure there are at least 3 lines: atom count, comment, and at least one atom
        guard lines.count >= 3 else {
            throw MoleculeParsingError.invalidFormat("XYZ file must contain at least 3 lines.(atom count, comment, and at least one atom)")
        }
        
        // 3. Parse the first line for the number of atoms
        guard let numAtoms = Int(lines[0].trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw MoleculeParsingError.invalidFormat("First line of XYZ must contain an integer representing the number of atoms.")
        }
        
        // 4. The seconed line is a comment, so it can be ignored for righ now
        // let commentLine = lines[1]
        
        // 5. Parse atom data from the subsequent lines
        var atoms: [Atom] = []
        
        // start from index 2 because lines[0] is atom count and lines[1] is the comment.
        // also check against numAtoms to ensure we don't read beyond expected atom lines.
        for i in 2..<lines.count{
            if atoms.count >= numAtoms {
                //if expected number of atoms is already parsed then stop.
                // this can handel cases wher files have extra lines
                break
            }
            
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            let components = line.split(separator: " ", omittingEmptySubsequences: true).map { String($0) }
            
            // Expected format: [Symbol] [X] [Y] [Z]
            guard components.count == 4 else {
                throw MoleculeParsingError.invalidFormat("Atom line \(i+1) in XYZ file has incorrect format: '\(line)'. Expected 'Symbol X Y Z'.")
            }
            
            let symbol = components[0]
            
            guard let x = Float(components[1]), let y = Float(components[2]), let z = Float(components[3]) else {
                throw MoleculeParsingError.invalidFormat("Atom line \(i+1) in XYZ file contains non-numeric coordinates: '\(line)'.")
            }
            
            let position = SIMD3<Float>(x, y, z)
            atoms.append(Atom(symbol: symbol, position: position))
        }
        
        // Ensure the expected number of atoms were parsed
        guard atoms.count == numAtoms else {
            throw MoleculeParsingError.invalidFormat("Expected \(numAtoms) atoms, but found \(atoms.count) in XYZ file.")
        }
        
        // For .xyz files, bond information is typically not included.
        // Will add logic for parsing bonds when we support formats like .mol or .pdb.
        let bonds: [Bond] = []
        
        return MolecularData(atoms: atoms, bonds: bonds)
        //return MolecularData.example()
    }
}

///Custom error types for molecular parsing operations.
enum MoleculeParsingError: LocalizedError {
    case fileReadError(String)
    case invalidFormat(String)
    case unsupportedFormat(String)
    
    var errorDescription: String? {
        switch self {
        case .fileReadError(let message):
            return "File read error: \(message)"
        case .invalidFormat(let message):
            return "Invalid format: \(message)"
        case .unsupportedFormat(let message):
            return "Unsupported format: \(message)"
        }
    }
}
