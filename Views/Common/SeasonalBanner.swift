//
//  SeasonalBanner.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 21/02/26.
//

import SwiftUI

struct SeasonalBanner: View {
    let icon: String
    let message: String
    
    var body: some View {
        HStack {
            Text("\(icon) \(message)")
                .font(.subheadline)
                .foregroundColor(.white)
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.8))
        .cornerRadius(10)
    }
}
