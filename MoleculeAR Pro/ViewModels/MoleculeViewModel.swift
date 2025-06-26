//
//  MoleculeViewModel.swift
//  MoleculeAR Pro
//
//  Created by Myles Slack on 2025.06.23.
//
import SwiftUI
import Combine
import SceneKit

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
    
    // MARK: - Init
    init(){
        // The initial scene setup is mainly for a placeholder or a default view
                // when no molecule is loaded yet. When a molecule *is* loaded,
                // buildScene will create a complete new scene with its own camera and lights.
                let initialScene = SCNScene()
                
                // Placeholder atom (blue sphere) - good for showing something is there initially
                let sphere = SCNSphere(radius: 0.5)
                sphere.firstMaterial?.diffuse.contents = NSColor.systemBlue
                let atomNode = SCNNode(geometry: sphere)
                atomNode.position = SCNVector3(0, 0, 0)
                initialScene.rootNode.addChildNode(atomNode)
                
                // Initial Camera for the placeholder scene
                let cameraNode = SCNNode()
                cameraNode.camera = SCNCamera()
                cameraNode.position = SCNVector3(0, 0, 5)
                initialScene.rootNode.addChildNode(cameraNode)
                
                // Initial Light for the placeholder scene
                let lightNode = SCNNode()
                lightNode.light = SCNLight()
                lightNode.light?.type = .omni
                lightNode.position = SCNVector3(0, 5, 5)
                initialScene.rootNode.addChildNode(lightNode)
                
                // Initial Ambient light for the placeholder scene
                let ambientLight = SCNNode()
                ambientLight.light = SCNLight()
                ambientLight.light?.type = .ambient
                ambientLight.light?.color = NSColor.darkGray
                initialScene.rootNode.addChildNode(ambientLight)

                // Background for the placeholder scene
                initialScene.background.contents = NSColor.black
                
                self.scene = initialScene
    }
    
    // MARK: - load molecule File
    func loadMoleculeFile(from url: URL) {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let parsed = try MolecularParser.parse(from: url)
                DispatchQueue.main.async {
                    self.molecularData = parsed
                    // Call buildScene to create and set up the new scene with the loaded molecule
                    self.buildScene(from: parsed)
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
    
    // MARK: - Build Scene
    // This function is responsible for creating a complete SCNScene
    // with the loaded molecular data, including its own camera and lights.
    func buildScene(from data: MolecularData){
        let newScene = SCNScene()
        // Add atoms as spheres
        for (index, atom) in data.atoms.enumerated() {
            let sphere = SCNSphere(radius: 0.2)
            let baseColor = elementColor(for: atom.symbol)

            let material = SCNMaterial()
            material.diffuse.contents = baseColor
            material.lightingModel = .blinn // Use a lighting model that supports emission

            if index == selectedAtomIndex {
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
        // Add bonds as cylinders
        for bond in data.bonds {
            let atom1 = data.atoms[bond.atom1Index]
            let atom2 = data.atoms[bond.atom2Index]
            
            let bondNode = cylinderBetween(atom1.position, atom2.position)
            bondNode.name = "Bond between Atoms \(bond.atom1Index) and \(bond.atom2Index)"
            newScene.rootNode.addChildNode(bondNode)
        }
        // --- IMPORTANT: Adding Camera to the new scene ---
        // Without a camera, you wouldn't be able to see the molecule!
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        // Position the camera to view the molecule. Adjust as needed for molecule size.
        cameraNode.position = SCNVector3(0, 0, 10) // Moved slightly back for better initial view
        newScene.rootNode.addChildNode(cameraNode)
        
        // --- IMPORTANT: Adding Light to the new scene ---
        // Without light, the molecule would be completely dark!
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni // Omnidirectional light
        lightNode.position = SCNVector3(0, 5, 5) // Position the light source
        newScene.rootNode.addChildNode(lightNode)
        
        // --- IMPORTANT: Adding Ambient Light to the new scene ---
        // Ambient light provides general illumination, preventing completely dark areas.
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = NSColor.darkGray // A subtle gray ambient light
        newScene.rootNode.addChildNode(ambientLight)

        // --- IMPORTANT: Setting Background for the new scene ---
        // Ensure the new scene also has a background color.
        newScene.background.contents = NSColor.black // Set the background to black
        
        // Assign the newly created and configured scene to the published property
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
    
    private func cylinderBetween(_ start: SIMD3<Float>, _ end: SIMD3<Float>) -> SCNNode {
        let startVec = SCNVector3(start)
        let endVec = SCNVector3(end)
        let mid = SCNVector3(
            (startVec.x + endVec.x)/2,
            (startVec.y + endVec.y)/2,
            (startVec.z + endVec.z)/2)
        
        let height = CGFloat(simd_distance(start, end))
        let cylinder = SCNCylinder(radius: 0.05, height: height)
        cylinder.firstMaterial?.diffuse.contents = NSColor.gray
        
        let node = SCNNode(geometry: cylinder)
        node.position = mid
        
        // Align cylinder between start and end
        let dir = end - start
        let up = SIMD3<Float>(0, 1, 0)
        let axis = simd_cross(up, simd_normalize(dir))
        let angle = acos(simd_dot(up, simd_normalize(dir)))
        node.rotation = SCNVector4(axis.x, axis.y, axis.z, angle)
        
        return node
        
    }
    
    func selectAtom(index: Int){
        selectedAtomIndex = index
        if let molecule = molecularData{
            buildScene(from: molecule) // Rebuild the scene to apply the highlight
        }
    }
    
    func clearMolecule(){
        molecularData = nil
    }
    
    func clearSelection(){
        selectedAtomIndex = nil
        selectedAtomIndices.removeAll()
        if let molecule = molecularData{
            buildScene(from: molecule) // Rebuild to remove glow
        }
    }
    
    func updateGlowForSelectedAtoms(){
        guard let molecule = molecularData else { return }
        let newScene = SCNScene()
        
        for (index, atom) in molecule.atoms.enumerated() {
            let sphere = SCNSphere(radius: 0.2)
            let baseColor = elementColor(for: atom.symbol)
            
            let material = SCNMaterial()
            material.diffuse.contents = baseColor
            material.lightingModel = .blinn
            
            if selectedAtomIndices.contains(index) {
                material.emission.contents = NSColor.systemYellow
                material.emission.intensity = 1.0
            }else{
                material.emission.contents = NSColor.black
                material.emission.intensity = 0.0
            }
            sphere.materials = [material]
            
            let node = SCNNode(geometry: sphere)
            node.position = SCNVector3(atom.position.x, atom.position.y, atom.position.z)
            node.name = "Atom \(index) \(atom.symbol)"
            newScene.rootNode.addChildNode(node)
        }
        
        for bond in molecule.bonds {
            let atom1 = molecule.atoms[bond.atom1Index]
            let atom2 = molecule.atoms[bond.atom2Index]
            let bondNode = cylinderBetween(atom1.position, atom2.position)
            bondNode.name = "Bond between Atoms \(bond.atom1Index) and \(bond.atom2Index)"
            newScene.rootNode.addChildNode(bondNode)
        }
        
        // Add camera, lights, and background as before
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 10)
        newScene.rootNode.addChildNode(cameraNode)
        
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
        
        self.scene = newScene
    }
    
    func toggleAtomSelection(index: Int){
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
        // I can add a smarter lookup later
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
