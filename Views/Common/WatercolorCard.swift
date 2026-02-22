//
//  WatercolorCard.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 21/02/26.
//

import SwiftUI

struct WatercolorCard: View {
    let title: String
    let subtitle: String
    let illustrationName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                
                // Placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 220)
                    .cornerRadius(12)
                    .overlay(Text(illustrationName).foregroundColor(.gray))
                
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(.black)
                
                Text(subtitle)
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                
                Spacer()
            }
            .padding(16)
            .frame(width: 260, height: 380)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
