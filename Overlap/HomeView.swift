//
//  ContentView.swift
//  Overlap
//
//  Created by Paul Davis on 7/24/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // Setup Background
                BlobBackgroundView()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    //App Title
                    VStack(spacing: 10) {
                        Text("Overlap")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("See where your opinions overlap")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        HomeMenuView()
                            .padding()
                            .frame(maxWidth: 400)
                        Spacer()
                    }
                    
                    Spacer()
                }
                .padding(30)
            }
        }
    }
}

#Preview {
    HomeView()
}
