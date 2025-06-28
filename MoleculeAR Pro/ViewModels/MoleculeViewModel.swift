//
//  MoleculeViewModel.swift
//  MoleculeAR Pro
//
//  Created by Myles Slack on 2025.06.23.
//
import SwiftUI
import Combine
import SceneKit
import simd // Ensure simd is imported for SIMD3<Float>

@MainActor
final class MoleculeViewModel: ObservableObject {
    
    @Published var molecularData: MolecularData? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var selectedAtomIndex: Int? = nil
    @Published var selectionMode: AtomSelectionMode = .none
    @Published var scene: SCNScene = SCNScene()
    @Published var interactionMode: InteractionMode = .inspect
    @Published var selectedAtomIndices: Set<Int> = []
    @Published var dragStart: CGPoint? = nil // Where user starts to drag for selection
    @Published var dragEnd: CGPoint? = nil // Where user end to drag for selection
    
    // Injected dependency for AppPreferencesViewModel (NOT @EnvironmentObject here anymore)
    let appPreferences: AppPreferencesViewModel // <-- Corrected property declaration
    
    private var cancellables = Set<AnyCancellable>() // For Combine subscriptions
        
    var selectedAtomInfo: SelectedAtomInfo? {
        guard let index = selectedAtomIndex,
              let data = molecularData,
              index < data.atoms.count else {
            return nil
        }
        let atom = data.atoms[index]
        return SelectedAtomInfo(
            symbol: atom.symbol,
            index: index,
            position: atom.position
        )
    }
    
    var dragBox: CGRect? {
        guard let start = dragStart, let end = dragEnd else { return nil }
        let origin = CGPoint(x: min(start.x, end.x), y: min(start.y, end.y))
        let size = CGSize(width: abs(end.x - start.x), height: abs(end.y - start.y))
        return CGRect(origin: origin, size: size)
    }
    
    // MARK: - Init
    // Modified init to accept AppPreferencesViewModel as a parameter
    init(appPreferences: AppPreferencesViewModel){ // <-- Corrected initializer signature
        self.appPreferences = appPreferences // <-- Store the injected dependency
        
        let initialScene = SCNScene()
        
        let sphere = SCNSphere(radius: 0.5)
        sphere.firstMaterial?.diffuse.contents = NSColor.systemBlue
        let atomNode = SCNNode(geometry: sphere)
        atomNode.position = SCNVector3(0, 0, 0)
        initialScene.rootNode.addChildNode(atomNode)
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 5)
        initialScene.rootNode.addChildNode(cameraNode)
        
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(0, 5, 5)
        initialScene.rootNode.addChildNode(lightNode)
        
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = NSColor.darkGray
        initialScene.rootNode.addChildNode(ambientLight)

        initialScene.background.contents = NSColor.black
        
        self.scene = initialScene
        
        // Setup Combine subscription to react to changes in visualizationStyle
        // Now appPreferences is safely initialized here and its publisher accessed correctly.
        self.appPreferences.$visualizationStyle // <-- Corrected publisher access
            .sink { [weak self] newStyle in
                guard let self = self, let molecule = self.molecularData else { return }
                print("🔄 Visualization style changed to: \(newStyle.rawValue). Rebuilding scene.")
                self.buildScene(from: molecule)
            }
            .store(in: &cancellables) // Store the subscription to keep it active
    }
    
    // MARK: - load molecule File
    func loadMoleculeFile(from url: URL) { // <-- ADDED @MainActor
        isLoading = true
        errorMessage = nil
        
        // The parsing itself can happen on a background thread.
        // Once parsing is done, switch back to the main actor to update published properties and scene.
        Task.detached(priority: .userInitiated) { // Use Task.detached for background work
            do {
                let parsed = try MolecularParser.parse(from: url)
                // Since MoleculeViewModel is @MainActor, we can simply `await self.propertyName = value`
                // or `await self.methodCall()`
                await self.assignMolecularDataAndBuildScene(parsed) // Use a helper to update on MainActor
            } catch {
                await self.handleLoadingError(error) // Use a helper to update on MainActor
            }
        }
    }
    
    // Helper function to ensure all UI updates happen on the MainActor
    private func assignMolecularDataAndBuildScene(_ data: MolecularData) {
        molecularData = data
        buildScene(from: data)
        isLoading = false
    }
    
    //Helper function to handle errors on the MainActor
    private func handleLoadingError(_ error: Error) {
        isLoading = false
        errorMessage = "Failed to load molecule: \(error.localizedDescription)"
    }
    
    // MARK: - Build Scene
    func buildScene(from data: MolecularData){ // <-- ADDED @MainActor
        let newScene = SCNScene()
        
        let cameraNode = SCNNode()
        cameraNode.name = "MainCamera"
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 10)
        newScene.rootNode.addChildNode(cameraNode)
        
        // Determine rendering parameters based on the current visualization style
        let currentStyle = appPreferences.visualizationStyle // <-- Reads visualizationStyle
        
        var atomRadius: CGFloat
        var bondRadius: CGFloat
        var hideBonds: Bool
        
        switch currentStyle {
        case .ballAndStick:
            atomRadius = 0.2
            bondRadius = 0.05
            hideBonds = false
        case .spaceFilling:
            atomRadius = 0.0 // Placeholder, will be set per atom
            bondRadius = 0.0 // Bonds effectively hidden
            hideBonds = true
        }
        
        for (index, atom) in data.atoms.enumerated() {
            // Adjust atom radius based on style and element for space-filling
            let effectiveAtomRadius: CGFloat
            if currentStyle == .spaceFilling {
                effectiveAtomRadius = CGFloat(vanDerWaalsRadius(for: atom.symbol))
            } else {
                effectiveAtomRadius = atomRadius
            }
            
            let sphere = SCNSphere(radius: effectiveAtomRadius) // <-- Uses effectiveAtomRadius
            let baseColor = elementColor(for: atom.symbol)

            let material = SCNMaterial()
            material.diffuse.contents = baseColor
            material.lightingModel = .blinn

            // Apply glow for selected atoms based on selectedAtomIndices
            if selectedAtomIndices.contains(index) {
                material.emission.contents = NSColor.systemYellow
                material.emission.intensity = 1.0
            } else {
                material.emission.contents = NSColor.black
                material.emission.intensity = 0.0
            }

            sphere.materials = [material]

            let node = SCNNode(geometry: sphere)
            node.position = SCNVector3(atom.position.x, atom.position.y, atom.position.z)
            node.name = "Atom \(index) \(atom.symbol)"
            newScene.rootNode.addChildNode(node)
        }
        
        // Add bonds as cylinders, only if not hidden by the current style
        if !hideBonds { // <-- Conditional bond rendering
            for bond in data.bonds {
                let atom1 = data.atoms[bond.atom1Index]
                let atom2 = data.atoms[bond.atom2Index]
                
                let bondNode = cylinderBetween(atom1.position, atom2.position, radius: bondRadius) // <-- Uses bondRadius
                bondNode.name = "Bond between Atoms \(bond.atom1Index) and \(bond.atom2Index)"
                newScene.rootNode.addChildNode(bondNode)
            }
        }
        
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(0, 5, 5)
        newScene.rootNode.addChildNode(lightNode)
        
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = NSColor.darkGray
        newScene.rootNode.addChildNode(ambientLight)

        newScene.background.contents = NSColor.black
        
        self.scene = newScene
    }
    
    private func elementColor(for symbol: String) -> NSColor {
        switch symbol.uppercased() {
        case "H": return .white
        case "C": return .darkGray
        case "N": return .blue
        case "O": return .red
        case "S": return .yellow
        default: return .green
        }
    }
    
    // Helper function to get Van der Waals radius for an element (in Angstroms)
    private func vanDerWaalsRadius(for symbol: String) -> Float { // <-- ADDED helper
        switch symbol.uppercased() {
        case "H": return 1.20
        case "C": return 1.70
        case "N": return 1.55
        case "O": return 1.52
        case "F": return 1.47
        case "P": return 1.80
        case "S": return 1.80
        case "CL": return 1.75
        case "BR": return 1.85
        case "I": return 1.98
        case "NA": return 2.27
        case "MG": return 1.73
        case "K": return 2.75
        case "CA": return 2.31
        default: return 1.5
        }
    }
    
    // Modified cylinderBetween to accept a radius parameter
    private func cylinderBetween(_ start: SIMD3<Float>, _ end: SIMD3<Float>, radius: CGFloat) -> SCNNode { // <-- Corrected signature
        let startVec = SCNVector3(start)
        let endVec = SCNVector3(end)
        let mid = SCNVector3(
            (startVec.x + endVec.x)/2,
            (startVec.y + endVec.y)/2,
            (startVec.z + endVec.z)/2)
        
        let height = CGFloat(simd_distance(start, end))
        let cylinder = SCNCylinder(radius: radius, height: height) // <-- Uses passed radius
        cylinder.firstMaterial?.diffuse.contents = NSColor.gray
        
        let node = SCNNode(geometry: cylinder)
        node.position = mid
        
        let dir = end - start
        let up = SIMD3<Float>(0, 1, 0)
        let axis = simd_cross(up, simd_normalize(dir))
        let angle = acos(simd_dot(up, simd_normalize(dir)))
        node.rotation = SCNVector4(axis.x, axis.y, axis.z, angle)
        
        return node
    }
    
    func selectAtom(index: Int){ // <-- ADDED @MainActor
        selectedAtomIndex = index
        if let molecule = molecularData{
            buildScene(from: molecule)
        }
    }
    
    func clearMolecule(){ // <-- ADDED @MainActor
        molecularData = nil
    }
    
    func clearSelection(){ // <-- ADDED @MainActor
        selectedAtomIndex = nil
        selectedAtomIndices.removeAll()
        if let molecule = molecularData{
            buildScene(from: molecule)
        }
    }
    
    func updateGlowForSelectedAtoms(){ // <-- ADDED @MainActor
        guard let molecule = molecularData else { return }
        buildScene(from: molecule)
    }
    
    func toggleAtomSelection(index: Int){ // <-- ADDED @MainActor
        if selectedAtomIndices.contains(index) {
            selectedAtomIndices.remove(index)
        }else{
            selectedAtomIndices.insert(index)
        }
        updateGlowForSelectedAtoms()
    }
}

struct SelectedAtomInfo {
    let symbol: String
    let index: Int
    let position: SIMD3<Float>
    var atomicNumber: Int? {
        switch symbol.uppercased() {
        case "H": return 1
        case "C": return 6
        case "N": return 7
        case "O": return 8
        case "S": return 16
        default: return nil
        }
    }
}
