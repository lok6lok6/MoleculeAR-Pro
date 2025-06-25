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
            if let hit = hitResults.first {
                print("🟢 Clicked node: \(String(describing: hit.node.name))")
                // TODO: Call viewModel to update selection
            } else {
                print("⚪️ Clicked background")
            }
        }
    }
}

