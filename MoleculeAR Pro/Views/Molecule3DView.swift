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
    @EnvironmentObject var appPreferences: AppPreferencesViewModel // <-- ADDED THIS LINE

    var body: some View {
        VStack{
            Text("Molecule 3D Viewer")
                .font(.title)
                .padding()

            // --- ADDED: Visualization Style Picker ---
            Picker("Visualization Style", selection: $appPreferences.visualizationStyle) { // <-- ADDED THIS BLOCK
                ForEach(VisualizationStyle.allCases) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top])
            // ----------------------------------------

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
                    .overlay(
                        GeometryReader { geo in
                            if moleculeVM.selectionMode == .box,
                               let rect = moleculeVM.dragBox {

                                // This flippedY calculation might still be needed depending on your coordinate system.
                                // If the box draws upside down, keep it. Otherwise, if dragBox already provides
                                // SwiftUI-compatible coordinates, it can be simplified.
                                let flippedY = geo.size.height - rect.origin.y - rect.size.height

                                Rectangle()
                                    .stroke(Color.yellow, lineWidth: 2)
                                    .background(Color.yellow.opacity(0.2))
                                    .frame(width: rect.width, height: rect.height)
                                    .position(x: rect.origin.x + rect.width / 2, y: flippedY + rect.height / 2)
                                    .allowsHitTesting(false)
                                    .animation(.easeInOut(duration: 0.05), value: rect)
                            }
                        }
                    )

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
                if let molecule = moleculeVM.molecularData {
                    Text("Molecule loaded: \(molecule.atoms.count) atoms, \(molecule.bonds.count) bonds")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
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
                    // Only reload example if no molecule is loaded, to avoid overwriting user's file.
                    // Or, provide a specific "Load Example" button separate from the primary load.
                    // For now, let's keep it simple.
                    loadExampleMolecule()
                }
                .padding()
            }
            .padding()
        }
        .onAppear {
            // Load example molecule only if nothing is loaded.
            // This prevents it from overriding a molecule the user just loaded if this onAppear fires again.
            if moleculeVM.molecularData == nil { // <-- ADDED CONDITIONAL LOAD
                loadExampleMolecule()
            }
        }
    }

    private func loadExampleMolecule() {
        // We now call loadMoleculeFile, which will use the MolecularParser.example() via URL if needed.
        // For now, let's pass a placeholder URL for the example.
        // In a real app, this might load from app bundle resources.
        // For now, it will simply call MolecularData.example() through MolecularParser's current implementation.
        // This will still use the old parser's example. For testing actual XYZ, use the file picker.
        // If MolecularParser.parse(from:) is fully implemented for XYZ, this example URL won't work without a file.
        // Let's simplify this to directly assign the example for now until we handle resource loading properly.

        moleculeVM.molecularData = MolecularData.example()
        moleculeVM.buildScene(from: MolecularData.example()) // Builds scene for example molecule
    }

    #if os(macOS)
    private func openFilePicker() {
        let panel = NSOpenPanel()
        var allowedTypes: [UTType] = [
            .text // Allow generic plain text files
        ]
        
        let specificExtensions = ["mol", "sdf", "pdb", "xyz"]
        allowedTypes.append(contentsOf: specificExtensions.compactMap { UTType(filenameExtension: $0) })
        
        panel.allowedContentTypes = allowedTypes
        
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
    // CRUCIAL: Provide ALL environment objects needed by the view and its children
    Molecule3DView()
        .environmentObject(MoleculeViewModel(appPreferences: AppPreferencesViewModel())) // <-- CORRECTED INIT
        .environmentObject(AppPreferencesViewModel()) // <-- ADDED THIS LINE
}
