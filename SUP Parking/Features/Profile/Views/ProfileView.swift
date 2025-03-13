//
//  ProfileView.swift
//  SUP Parking
//
//  Created by Pyae Sone Hein on 3/1/25.
//

import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import UIKit

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String = ""
    @State private var isEditing: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var inputImage: UIImage?
    @State private var profileImage: Image?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            VStack {
                // Header with profile picture
                VStack(spacing: 20) {
                    ZStack {
                        if let profileImage = profileImage {
                            profileImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                .shadow(radius: 5)
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.gray)
                        }
                        
                        if isEditing {
                            Button(action: {
                                showImagePicker = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 18))
                                }
                            }
                            .offset(x: 40, y: 40)
                        }
                    }
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                .padding(.top, 40)
                
                // Profile information
                Form {
                    Section(header: Text("Account Information")) {
                        if isEditing {
                            TextField("Name", text: $name)
                                .padding(.vertical, 8)
                        } else {
                            HStack {
                                Text("Name")
                                Spacer()
                                Text(name)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(authViewModel.user?.email ?? "")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                        
                        HStack {
                            Text("Account Type")
                            Spacer()
                            Text(authViewModel.user?.isAdmin == true ? "Administrator" : "User")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Section {
                        Button(action: {
                            authViewModel.signOut()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Spacer()
                                Text("Sign Out")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("Profile", displayMode: .inline)
            .navigationBarItems(
                trailing: Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveProfile()
                    } else {
                        isEditing = true
                    }
                }
            )
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $inputImage)
            }
            .onChange(of: inputImage) { newImage in
                if let newImage = newImage {
                    profileImage = Image(uiImage: newImage)
                }
            }
            .onAppear {
                loadUserProfile()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
        }
    }
    
    private func loadUserProfile() {
        guard let user = authViewModel.user else { return }
        name = user.name
        
        // Load profile image if it exists
        guard let userId = authViewModel.user?.id else { return }
        let storageRef = storage.reference().child("profileImages/\(userId)")
        
        storageRef.downloadURL { url, error in
            if let url = url {
                URLSession.shared.dataTask(with: url) { data, _, _ in
                    if let data = data, let uiImage = UIImage(data: data) {
                        DispatchQueue.main.async {
                            profileImage = Image(uiImage: uiImage)
                        }
                    }
                }.resume()
            }
        }
    }
    
    private func saveProfile() {
        guard let userId = authViewModel.user?.id else { return }
        isLoading = true
        
        // Update user document with new name
        let userRef = db.collection("users").document(userId)
        
        userRef.updateData([
            "name": name
        ]) { error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = "Error updating profile: \(error.localizedDescription)"
                    showError = true
                    isLoading = false
                }
                return
            }
            
            // Update profile image if changed
            if let inputImage = inputImage {
                uploadProfileImage(userId: userId, image: inputImage)
            } else {
                DispatchQueue.main.async {
                    isLoading = false
                    isEditing = false
                    // Update the authViewModel with the new name
                    if var updatedUser = authViewModel.user {
                        updatedUser.name = name
                        authViewModel.user = updatedUser
                    }
                }
            }
        }
    }
    
    private func uploadProfileImage(userId: String, image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            DispatchQueue.main.async {
                errorMessage = "Failed to process image"
                showError = true
                isLoading = false
            }
            return
        }
        
        let storageRef = storage.reference().child("profileImages/\(userId)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(imageData, metadata: metadata) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = "Failed to upload image: \(error.localizedDescription)"
                    showError = true
                } else {
                    // Update the authViewModel with the new name
                    if var updatedUser = authViewModel.user {
                        updatedUser.name = name
                        authViewModel.user = updatedUser
                    }
                }
                isLoading = false
                isEditing = false
            }
        }
    }
}

// ImagePicker to allow selecting images from the photo library
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}


