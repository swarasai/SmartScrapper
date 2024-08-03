//
//  LoginView.swift
//  SmartScrapper
//
//  Created by Raeva Desai on 8/2/24.
//

import SwiftUI

struct LoginView: View {
    let onLogin: () -> Void
    let streakCount: Int

    var body: some View {
        VStack {
            Spacer()
            
            Text("SmartScrapper")
                .font(.custom("Avenir Next", size: 40))
                .padding(.bottom, 20)
            
            Text("Your current streak: \(streakCount) days")
                .font(.custom("Avenir Next", size: 20))
                .padding(.bottom, 20)
            
            Button(action: onLogin) {
                Text("Take a Photo")
                    .font(.custom("Avenir Next", size: 20))
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
    }
}
