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
            
            Picker("Interaction", selection: $moleculeVM.interactionMode) {
                ForEach(InteractionMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top])
            
           Picker("Selection", selection: $moleculeVM.selectionMode) {
                ForEach(AtomSelectionMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top])
            
            ZStack(alignment: .bottomTrailing) {
                MoleculeSceneView(viewModel: moleculeVM)
                    .edgesIgnoringSafeArea(.all)
                
                if moleculeVM.interactionMode == .inspect, let info = moleculeVM.selectedAtomInfo {
                    VStack(alignment: .trailing, spacing: 8) {
                        AtomInspectorView(info: info)

                        Button("Clear Selection") {
                            moleculeVM.clearSelection()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding([.trailing, .bottom], 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut, value: info.index)
                }
            }
            
            VStack(spacing: 4) {
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
                .padding(.top)
                #endif
                
                Button("Reload Example Molecule") {
                    loadExampleMolecule()
                }
                .padding()
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
