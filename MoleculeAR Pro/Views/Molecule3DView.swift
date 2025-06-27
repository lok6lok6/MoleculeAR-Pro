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
                    .overlay(
                        GeometryReader { geo in
                            if moleculeVM.selectionMode == .box,
                               let rect = moleculeVM.dragBox {

                                let flippedY = geo.size.height - rect.origin.y - rect.size.height

                                Rectangle()
                                    .stroke(Color.yellow, lineWidth: 2)
                                    .background(Color.yellow.opacity(0.2))
                                    .frame(width: rect.width, height: rect.height)
                                    //.position(x: rect.origin.x + rect.width / 2, y: rect.origin.y + rect.height / 2) // Changed this line
                                    .position(x: rect.origin.x + rect.width / 2, y: flippedY + rect.height / 2)
                                    .allowsHitTesting(false) // ✅ Don't block mouse input to SceneKit
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
                    loadExampleMolecule()
                }
                .padding()
            }
            .padding()
        }
        .onAppear {
            loadExampleMolecule()
        }
    }

    private func loadExampleMolecule() {
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
