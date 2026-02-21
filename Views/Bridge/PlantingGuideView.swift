//
//  PlantingGuideView.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 21/02/26.
//

import SwiftUI

struct PlantingGuideView: View {
    @Environment(\.dismiss) var dismiss
    let plant: PlantSpecies
    
    var body: some View {
        NavigationView{
            ScrollView{
                VStack(spacing: 25){
                    
                    Text("How to plant your \(plant.name)")
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .padding(.top)
                    
                    ForEach(Array(plant.careInstructions.enumerated()), id: \.offset) { index, instruction in
                        HStack(alignment: .top, spacing: 15) {
                            
                            // Placeholder
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .cornerRadius(8)
                                .overlay(Text("Art").foregroundColor(.gray))
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Step \(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                
                                Text(instruction)
                                    .font(.system(size: 16, design: .serif))
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider().padding(.vertical)
                    
                    Text("Come back when you plant yours — your virtual \(plant.name) will grow with the real one.")
                         .font(.system(size: 14, design: .serif))
                         .italic()
                         .foregroundColor(.gray)
                         .multilineTextAlignment(.center)
                         .padding(.horizontal, 30)
                }
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing){
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
