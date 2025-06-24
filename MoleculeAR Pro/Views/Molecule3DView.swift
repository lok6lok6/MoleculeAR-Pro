//
//  Molecule3DView.swift
//  MoleculeAR Pro
//
//  Created by Myles Slack on 2025.06.23.
//
import SwiftUI
import SceneKit

struct Molecule3DView: View {
    @EnvironmentObject var moleculeVM: MoleculeViewModel
    
    var body: some View {
        VStack{
            Text("Molecule 3D Viewer")
                .font(.title)
                .padding()
            SceneView{
                scene: moleculeVM.scene,
                options: [.autoenablesDefaultLighting, .allowsCameraControl]
            }
            .frame(minHeight: 400)
            .cornerRadius(12)
            .padding()
        }
    }
}

#Preview {
    Molecule3DView()
        .environmentObject(MoleculeViewModel())
}
