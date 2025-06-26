//
//  AtomInspectorView.swift
//  MoleculeAR Pro
//
//  Created by Myles Slack on 2025.06.25.
//
import SwiftUI

struct AtomInspectorView: View {
    let info: SelectedAtomInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🧪 Atom Inspector")
                .font(.headline)
            
            HStack {
                Text("Symbol:")
                    .bold()
                Spacer()
                Text(info.symbol)
            }
            HStack {
                Text("Index: ")
                    .bold()
                Spacer()
                Text("\(info.index)")
            }
            HStack {
                Text("Position:")
                    .bold()
                Spacer()
                Text(String(format: "(%.2f, %.2f, %.2f)", info.position.x, info.position.y, info.position.z))
            }
            HStack {
                Text("Atomic Number:")
                    .bold()
                Spacer()
                Text(info.atomicNumber.map{ "\($0)" } ?? "Unknown")
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    AtomInspectorView(info: SelectedAtomInfo(
        symbol: "C",
        index: 3,
        position: SIMD3<Float>(0.0, 1.2, -0.4)
    ))
}
