//
//  PrimaryButton.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 21/02/26.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let icon: String?
    var backgroundColor: Color
    var textColor: Color
    let action: () -> Void
    
    init(title: String,
         icon: String? = nil,
         backgroundColor: Color = Color(red: 0.3, green: 0.5, blue: 0.3),
         textColor: Color = .white,
         action: @escaping () -> Void) {
        
        self.title = title
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.headline)
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .padding()
            .background(backgroundColor)
            .cornerRadius(12)
        }
    }
}
