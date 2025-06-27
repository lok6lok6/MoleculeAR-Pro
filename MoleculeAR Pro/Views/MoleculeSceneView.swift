//
//  MoleculeSceneView.swift
//  MoleculeAR Pro
//
//  Created by Myles Slack on 2025.06.24.
//
import SwiftUI
import SceneKit

struct MoleculeSceneView: NSViewRepresentable {
    @ObservedObject var viewModel: MoleculeViewModel
    
    func makeNSView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = viewModel.scene

        // The camera should always be set from the scene's content
        if let cameraNode = viewModel.scene.rootNode.childNode(withName: "MainCamera", recursively: true) {
            scnView.pointOfView = cameraNode
        }

        scnView.autoenablesDefaultLighting = true
        scnView.antialiasingMode = .multisampling4X
        scnView.backgroundColor = .black
        
        // Add the click gesture recognizer once. It should always be active.
        let clickGesture = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleClick(_:)))
        scnView.addGestureRecognizer(clickGesture)

        // Assign the SCNView to the coordinator so it can manage gestures
        context.coordinator.scnView = scnView
        
        // Initial setup for gesture management based on current viewModel state
        context.coordinator.setupGestureRecognizers(for: scnView, selectionMode: viewModel.selectionMode)

        return scnView
    }
    
    func updateNSView(_ nsView: SCNView, context: Context) {
        // Only update the scene if it's a *different* scene object.
        // Re-assigning the same scene object is unnecessary and can cause flickering.
        if nsView.scene !== viewModel.scene {
            nsView.scene = viewModel.scene
            // Re-set pointOfView if scene changes, as the new scene might have a new camera
            if let cameraNode = viewModel.scene.rootNode.childNode(withName: "MainCamera", recursively: true) {
                nsView.pointOfView = cameraNode
            }
        }
        
        // Dynamically manage gestures based on selectionMode changes
        context.coordinator.setupGestureRecognizers(for: nsView, selectionMode: viewModel.selectionMode)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator: NSObject {
        var viewModel: MoleculeViewModel
        weak var scnView: SCNView? // Keep a weak reference to the SCNView
        var dragPanGesture: NSPanGestureRecognizer? // Store our custom pan gesture

        init(viewModel: MoleculeViewModel) {
            self.viewModel = viewModel
        }
        
        // MARK: - Gesture Management Logic
        func setupGestureRecognizers(for scnView: SCNView, selectionMode: AtomSelectionMode) {
            // Step 1: Control SCNView's built-in camera control
            scnView.allowsCameraControl = (selectionMode != .box) // Only allow camera control when not in box selection mode
            
            // Step 2: Manage our custom drag-box pan gesture
            if selectionMode == .box {
                // If not already added, add the dragPanGesture
                if dragPanGesture == nil {
                    let panGesture = NSPanGestureRecognizer(target: self, action: #selector(Coordinator.handleDrag(_:)))
                    scnView.addGestureRecognizer(panGesture)
                    self.dragPanGesture = panGesture
                    print("🔵 Added drag box pan gesture.")
                }
                // Ensure it's enabled if we are in box mode
                dragPanGesture?.isEnabled = true
            } else {
                // If we are not in box selection mode, disable our custom pan gesture
                if let gesture = dragPanGesture {
                    gesture.isEnabled = false
                    print("🔵 Disabled drag box pan gesture.")
                    // Optionally, you could remove it entirely and re-add, but disabling is often sufficient.
                    // scnView.removeGestureRecognizer(gesture)
                    // self.dragPanGesture = nil
                }
            }
            
            // Note: The `handleClick` gesture is added once in `makeNSView` and
            // is intended to always be active, as clicking outside the molecule or
            // on an atom is always a valid interaction for selection/deselection.
        }

        @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            let point = gesture.location(in: scnView)
            
            let hitResults = scnView.hitTest(point, options: [:])
            if let hit = hitResults.first, let name = hit.node.name {
                if name.starts(with: "Atom") {
                    let components = name.split(separator: " ")
                    if components.count > 2,
                       let index = Int(components[1]) {
                        
                        print("🔘 Current Interaction Mode: \(viewModel.interactionMode.rawValue)")
                        print("🔘 Current Selection Mode: \(viewModel.selectionMode.rawValue)")
                        
                        switch viewModel.selectionMode {
                        case .none:
                            // If selection mode is .none, clicking an atom does nothing explicitly beyond logging
                            print("Ignoring atom selection in .none mode.")
                            viewModel.clearSelection() // Still clear any previous selection
                        case .single:
                            viewModel.selectAtom(index: index)
                            print("🟢 Selected atom index (single mode): \(index)")
                        case .multiple:
                            viewModel.toggleAtomSelection(index: index)
                            print("🟢 Toggled atom index (multiple mode): \(index)")
                        case .box:
                            // In box mode, a single click should still select/toggle an atom
                            viewModel.toggleAtomSelection(index: index)
                            print("🟢 Toggled atom index (box mode): \(index)")
                        }
                        return // Atom was hit, so don't clear selection unless explicitly done above
                    }
                }
            }
            print("⚪️ Clicked background - Clearing selection.")
            viewModel.clearSelection() // If background or non-atom node clicked, clear selection
        }
        
        @objc func handleDrag(_ gesture: NSPanGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            
            // Ensure we are in .box selection mode before processing drag
            guard viewModel.selectionMode == .box else {
                // If mode changed during drag, cancel the drag logic
                if gesture.state != .ended {
                    viewModel.dragStart = nil
                    viewModel.dragEnd = nil
                }
                return
            }
            
            let location = gesture.location(in: scnView)
            switch gesture.state {
            case .began:
                viewModel.dragStart = location
                viewModel.dragEnd = location // Initialize dragEnd for immediate feedback
                print("📦 Drag began at: \(location)")
            case .changed:
                viewModel.dragEnd = location
                // Optional: live-preview atoms can be added here
                // This is already visually represented by the yellow box in Molecule3DView.swift
                print("📦 Drag changed to: \(location)")
            case .ended:
                viewModel.dragEnd = location
                print("📦 Drag ended at: \(location)")
                selectAtomsInDragBox(in: scnView)
                viewModel.dragStart = nil
                viewModel.dragEnd = nil
            default:
                break
            }
        }
        
        func selectAtomsInDragBox(in scnView: SCNView) {
            guard let start = viewModel.dragStart,
                  let end = viewModel.dragEnd,
                  let scene = scnView.scene else { return }
            
            let minX = min(start.x, end.x)
            let maxX = max(start.x, end.x)
            let minY = min(start.y, end.y)
            let maxY = max(start.y, end.y)
            
            var newlySelectedIndices: Set<Int> = []
            
            for node in scene.rootNode.childNodes {
                guard let name = node.name,
                      name.starts(with: "Atom") else { continue }
                
                // Project the 3D position of the atom to 2D screen coordinates
                let projectedPoint = scnView.projectPoint(node.position)
                
                // Convert SceneKit's Y-coordinate (origin bottom-left) to AppKit's/SwiftUI's Y-coordinate (origin top-left)
                // This ensures consistency with the dragBox drawing
                let screenPoint = CGPoint(x: CGFloat(projectedPoint.x), y: CGFloat(scnView.bounds.height) - CGFloat(projectedPoint.y))
                
                // Check if the projected screen point of the atom is within the drag box
                if screenPoint.x >= minX && screenPoint.x <= maxX &&
                   screenPoint.y >= minY && screenPoint.y <= maxY {
                    let parts = name.split(separator: " ")
                    if parts.count > 2, let index = Int(parts[1]) {
                        newlySelectedIndices.insert(index)
                    }
                }
            }
            
            // Instead of just adding, let's replace the selection if it's a new box drag.
            // If the user performs another box drag, it typically implies a new selection.
            // If we want "add to selection" for box, we would need a modifier key (e.g., Shift+Drag)
            // For now, let's assume a new box drag means a new selection.
            viewModel.selectedAtomIndices = newlySelectedIndices
            viewModel.updateGlowForSelectedAtoms()
            print("📦 Atoms selected in box: \(newlySelectedIndices.sorted())")
        }
    }
}
