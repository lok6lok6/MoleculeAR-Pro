//
//  RootView.swift
//  MoleculeAR Pro
//
//  Created by Myles Slack on 2025.06.23.
//
import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20){
                Text("Welcome to MoleculeAR Pro")
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Text("Start building your molecular world in 3D and AR!")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            .padding()
#if os(MacOS)
            .frame(minWidth: 600, minHeight: 400)
#else
            .frame(maxWidth: .infinity, maxHeight: .infinity)
#endif
        }
    }
}

#Preview {
    RootView()
}
