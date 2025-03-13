//
//  SplashView.swift
//  SUP Parking
//
//  Created by Pyae Sone Hein on 2/23/25.
//
// MARK: - Views
// SplashView.swift
import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    
    var body: some View {
        if isActive {
            AuthView()
        } else {
            VStack {
                Image("SUPLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                   
                
                Text("SUP Parking")
                    .font(.title)
                    .bold()
                    .padding(.top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure background fills screen
            .background(Color.black) // Set background color to black
            .ignoresSafeArea()
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
