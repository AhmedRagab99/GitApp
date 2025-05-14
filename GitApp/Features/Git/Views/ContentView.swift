//
//  ContentView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 17/04/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = RepositoryViewModel()

    var body: some View {
        RepositorySelectionView(viewModel: viewModel)
        
    }
}

#Preview {
    ContentView()
}
