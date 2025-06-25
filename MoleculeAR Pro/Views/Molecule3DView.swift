//
//  Molecule3DView.swift
//  MoleculeAR Pro
//
//  Created by Myles Slack on 2025.06.23.
//
import SwiftUI
import SceneKit
#if os(macOS)
import UniformTypeIdentifiers
#endif

struct Molecule3DView: View {
    @EnvironmentObject var moleculeVM: MoleculeViewModel
    
    var body: some View {
        VStack{
            Text("Molecule 3D Viewer")
                .font(.title)
                .padding()
            SceneView(
                scene: moleculeVM.scene,
                pointOfView: nil,
                options: [.autoenablesDefaultLighting, .allowsCameraControl],
                preferredFramesPerSecond: 60,
                antialiasingMode: .multisampling4X,
                delegate: nil,
                technique: nil
            )
            .frame(minHeight: 400)
            .cornerRadius(12)
            .padding()
            
            // 🧪 Debug info to see what's loaded
            if let molecule = moleculeVM.molecularData {
                Text("Molecule loaded: \(molecule.atoms.count) atoms, \(molecule.bonds.count) bonds")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }else{
                Text("No molecule loaded yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            #if os(macOS)
            Button("Load Molecule from File") {
                openFilePicker()
            }
            .padding()
            #endif
            Button("Reload Example Molecule") {
                loadExampleMolecule()
            }
            .padding()
        }
        .onAppear {
            // Load the example CO molecule when the view appears
            loadExampleMolecule()
        }
    }
    
    private func loadExampleMolecule() {
        //Since MoleculeParser.parce() returns MolecularData.example(),
        //I can simulate loading from a "file" URL
        moleculeVM.molecularData = MolecularData.example()
        moleculeVM.buildScene(from: MolecularData.example())
    }
    
    #if os(macOS)
    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
                UTType(filenameExtension: "mol")!,
                UTType(filenameExtension: "sdf")!,
                UTType(filenameExtension: "pdb")!,
                UTType(filenameExtension: "xyz")!
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.begin { response in
            if response == .OK, let url = panel.url {
                moleculeVM.loadMoleculeFile(from: url)
            }
        }
    }
    #endif
}

#Preview {
    Molecule3DView()
        .environmentObject(MoleculeViewModel())
}
