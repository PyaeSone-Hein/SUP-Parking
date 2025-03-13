//
//  UserProfileComponent.swift
//  SUP Parking
//
//  Created by Pyae Sone Hein on 3/3/25.
//

import SwiftUI
import FirebaseStorage

struct UserProfileComponent: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var profileImage: Image?
    @State private var isLoading = false
    var action: () -> Void
    
    init(action: @escaping () -> Void = {}) {
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .frame(width: 40, height: 40)
                } else if let profileImage = profileImage {
                    profileImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.gray)
                }
                
                if let userName = authViewModel.user?.name {
                    Text(userName)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            loadProfileImage()
        }
    }
    
    private func loadProfileImage() {
        guard let userId = authViewModel.user?.id else { return }
        isLoading = true
        
        let storageRef = Storage.storage().reference().child("profileImages/\(userId)")
        
        storageRef.downloadURL { url, error in
            if let url = url {
                URLSession.shared.dataTask(with: url) { data, _, _ in
                    if let data = data, let uiImage = UIImage(data: data) {
                        DispatchQueue.main.async {
                            profileImage = Image(uiImage: uiImage)
                            isLoading = false
                        }
                    } else {
                        DispatchQueue.main.async {
                            isLoading = false
                        }
                    }
                }.resume()
            } else {
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
        }
    }
}
