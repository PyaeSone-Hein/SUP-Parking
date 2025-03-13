//
//  AuthViewModel.swift
//  SUP Parking
//
//  Created by Pyae Sone Hein on 2/23/25.
//

// MARK: - View Models
// AuthViewModel.swift
import Foundation
import FirebaseAuth
import FirebaseFirestore
import UIKit

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    init() {
        setupAuthStateListener()
    }

    private func setupAuthStateListener() {
        auth.addStateDidChangeListener { [weak self] _, user in
            if let userId = user?.uid {
                self?.fetchUser(userId: userId)
            } else {
                DispatchQueue.main.async {
                    self?.isAuthenticated = false
                    self?.user = nil
                }
            }
        }
    }

    func signIn(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }

        isLoading = true
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                if let userId = result?.user.uid {
                    self?.fetchUser(userId: userId)
                }
            }
        }
    }

    func signUp(email: String, password: String, name: String) {
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }

        isLoading = true
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                    return
                }

                if let userId = result?.user.uid {
                    let user = User(id: userId, email: email, name: name, created: Date(), isAdmin: false)
                    self?.createUserDocument(user: user)
                }
            }
        }
    }

    private func createUserDocument(user: User) {
        do {
            let data = try JSONEncoder().encode(user)
            if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                db.collection("users").document(user.id).setData(dict) { [weak self] error in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if let error = error {
                            self?.errorMessage = error.localizedDescription
                            return
                        }
                        self?.user = user
                        self?.isAuthenticated = true
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to encode user data"
                self.isLoading = false
            }
        }
    }

    private func fetchUser(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                }
                return
            }

            if let data = snapshot?.data(),
               let userData = try? JSONSerialization.data(withJSONObject: data),
               let user = try? JSONDecoder().decode(User.self, from: userData) {
                DispatchQueue.main.async {
                    self?.user = user
                    self?.isAuthenticated = true
                }
            }
        }
    }
    
    func updateUserProfile(name: String, profileImage: UIImage? = nil, completion: @escaping (Bool, String?) -> Void) {
        guard let userId = user?.id else {
            completion(false, "User not authenticated")
            return
        }
        
        let userRef = db.collection("users").document(userId)
        
        // Update name in Firestore
        userRef.updateData([
            "name": name
        ]) { [weak self] error in
            if let error = error {
                completion(false, "Failed to update profile: \(error.localizedDescription)")
                return
            }
            
            // Update local user object
            DispatchQueue.main.async {
                if var currentUser = self?.user {
                    currentUser.name = name
                    self?.user = currentUser
                    completion(true, nil)
                } else {
                    completion(false, "Failed to update local user data")
                }
            }
        }
    }

    func signOut() {
        do {
            try auth.signOut()
            DispatchQueue.main.async {
                self.user = nil
                self.isAuthenticated = false
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
