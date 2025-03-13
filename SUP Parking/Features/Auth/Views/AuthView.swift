//
//  AuthView.swift
//  SUP Parking
//
//  Created by Pyae Sone Hein on 2/23/25.
//
// AuthView.swift
import SwiftUI
import FirebaseAuth

struct AuthView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignUp = false
    
    var body: some View {
        if authViewModel.isAuthenticated {
            ContentView()
                .environmentObject(authViewModel)
        } else {
            ZStack {
                // Black background
                Color.black.edgesIgnoringSafeArea(.all)
                
                
                VStack {
                    // Logo and tagline area
                    HStack(spacing: 60) {
                        Image("SUPLogo1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .offset(x: 65)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("SUP Parking")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Drive Easy, Live Free.")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    Spacer()
                    
                    // White content area with curved top
                    VStack {
                        Text(isSignUp ? "Create Account" : "Login")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top, 100)
                            .padding(.bottom, 30)
                        
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .fontWeight(.medium)
                                
                                TextField("", text: $name)
                                    .padding()
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .padding(.horizontal)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .fontWeight(.medium)
                            
                            TextField("", text: $email)
                                .padding()
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 15)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Passsword")
                                .fontWeight(.medium)
                            
                            SecureField("", text: $password)
                                .padding()
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 25)
                        
                        if authViewModel.isLoading {
                            ProgressView()
                                .padding()
                        } else {
                            Button(action: {
                                if isSignUp {
                                    authViewModel.signUp(email: email, password: password, name: name)
                                } else {
                                    authViewModel.signIn(email: email, password: password)
                                }
                            }) {
                                Text(isSignUp ? "Sign Up" : "Log In")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                            .background(Color(UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0)))
                            .cornerRadius(4)
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                        
                        if let errorMessage = authViewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                                .padding(.bottom, 10)
                        }
                        
                        HStack(spacing: 5) {
                            Text(isSignUp ? "Already have account?" : "Don't have account?")
                                .foregroundColor(.gray)
                            
                            Button(isSignUp ? "Sign In" : "Create now") {
                                isSignUp.toggle()
                            }
                            .foregroundColor(.black)
                            .fontWeight(.medium)
                        }
                        .padding(.bottom, 40)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                        Color.white
                            .clipShape(
                                CustomShape()
                            )
                    )
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}

// Custom shape for the curved top of the white content area
struct CustomShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: 0, y: 10))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: 50),
            control: CGPoint(x: rect.width / 2, y: 0)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    AuthView()
}
