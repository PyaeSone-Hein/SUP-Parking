//
//  AddSpotView.swift
//  SUP Parking
//
//  Created by Pyae Sone Hein on 2/23/25.
//

// AddSpotView.swift
import SwiftUI
import Firebase
import FirebaseFirestore

struct AddSpotView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var parkingViewModel: ParkingViewModel
    
    @State private var spotId = ""
    @State private var selectedFloor = 1
    @State private var selectedType = SpotType.standard
    @State private var errorMessage: String?
    @State private var showError = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Spot ID", text: $spotId)
                
                Picker("Floor", selection: $selectedFloor) {
                    ForEach(1...5, id: \.self) { floor in
                        Text("Floor \(floor)").tag(floor)
                    }
                }
                
                Picker("Type", selection: $selectedType) {
                    Text("Standard").tag(SpotType.standard)
                    Text("Disabled").tag(SpotType.disabled)
                }
            }
            .navigationTitle("Add New Spot")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveSpot()
                }
            )
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
        }
    }
    
    private func saveSpot() {
        guard !spotId.isEmpty else {
            errorMessage = "Please enter a spot ID"
            showError = true
            return
        }
        
        let newSpot = ParkingSpot(
            id: spotId,
            status: .available,
            type: selectedType,
            lastUpdated: Date(),
            floor: selectedFloor
        )
        
        db.collection("parkingSpots").document(spotId).setData(newSpot.dictionary) { error in
            if let error = error {
                errorMessage = "Error saving spot: \(error.localizedDescription)"
                showError = true
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
