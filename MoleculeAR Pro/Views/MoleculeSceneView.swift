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
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.antialiasingMode = .multisampling4X
        scnView.backgroundColor = .black
        
        //Add drag gesture
        let panGesture = NSPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDrag(_:)))
                scnView.addGestureRecognizer(panGesture)
        
        //Enable click handling
        let clickGesture = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleClick(_:)))
                scnView.addGestureRecognizer(clickGesture)

        return scnView
    }
    
    func updateNSView(_ nsView: SCNView, context: Context) {
        nsView.scene = viewModel.scene
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator: NSObject {
        var viewModel: MoleculeViewModel
        
        init(viewModel: MoleculeViewModel) {
            self.viewModel = viewModel
        }
        
        @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            let point = gesture.location(in: scnView)
            
            let hitResults = scnView.hitTest(point, options: [:])
            if let hit = hitResults.first, let name = hit.node.name {
                //print("🟢 Clicked node: \(String(describing: hit.node.name))")
                //Parse atom index from node name
                
                if name.starts(with: "Atom") {
                    let components = name.split(separator: " ")
                    if components.count > 2,
                       let index = Int(components[1]) {
                        
                        switch viewModel.selectionMode {
                        case .none:
                            print("🔘 Mode: single")
                        case .single:
                            print("🔘 Mode: single")
                        case .multiple:
                            print("🔘 Mode: multiple")
                        case .box:
                            print("📦 Mode: box")
                        }
                        
                        print("🔘 Current Mode: \(viewModel.interactionMode)")
                        print("🟢 Selected atom index: \(index)")
                        viewModel.selectAtom(index: index)
                        return
                    }
                }
            }
            print("⚪️ Clicked background")
            viewModel.clearSelection()
        }
        
        @objc func handleDrag(_ gesture: NSPanGestureRecognizer) {
            guard viewModel.selectionMode == .box,
                  let scnView = gesture.view as? SCNView else { return }
            
            let location = gesture.location(in: scnView)
            
            switch gesture.state {
            case .began:
                viewModel.dragStart = location
            case .changed:
                viewModel.dragEnd = location
                //Optional: live-preview atoms can be added here
            case .ended:
                viewModel.dragEnd = location
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
                
                let projectedPoint = scnView.projectPoint(node.position)
                let screenPoint = CGPoint(x: CGFloat(projectedPoint.x), y: CGFloat(scnView.bounds.height) - CGFloat(projectedPoint.y))
                
                if screenPoint.x >= minX, screenPoint.x <= maxX, screenPoint.y >= minY,
                   screenPoint.y <= maxY {
                    let parts = name.split(separator: " ")
                    if parts.count > 2, let index = Int(parts[1]) {
                        newlySelectedIndices.insert(index)
                    }
                }
            }
            viewModel.selectedAtomIndices.formUnion(newlySelectedIndices)
            viewModel.updateGlowForSelectedAtoms()
        }
    }
}
