//
//  ParkingViewModel.swift
//  SUP Parking
//
//  Created by Pyae Sone Hein on 2/23/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class ParkingViewModel: ObservableObject {
    @Published var parkingSpots: [Int: [ParkingSpot]] = [:]
    @Published var bookings: [Booking] = []
    @Published var selectedFloor = 1
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var isLoading = false
    @Published var searchQuery = ""
    
    private var listeners: [ListenerRegistration] = []
    private let db = Firestore.firestore()
    
    deinit {
        listeners.forEach { $0.remove() }
    }
    
    func observeParkingSpots() {
        let listener = db.collection("parkingSpots")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    self?.errorMessage = error?.localizedDescription ?? "Error fetching spots"
                    self?.showError = true
                    return
                }
                
                var newSpots: [Int: [ParkingSpot]] = [:]
                for document in documents {
                    do {
                        let data = document.data()
                        guard
                            let id = data["id"] as? String,
                            let statusRaw = data["status"] as? String,
                            let typeRaw = data["type"] as? String,
                            let lastUpdated = data["lastUpdated"] as? Timestamp,
                            let floor = data["floor"] as? Int,
                            let status = SpotStatus(rawValue: statusRaw),
                            let type = SpotType(rawValue: typeRaw)
                        else {
                            continue
                        }
                        
                        let spot = ParkingSpot(
                            id: id,
                            status: status,
                            type: type,
                            lastUpdated: lastUpdated.dateValue(),
                            floor: floor
                        )
                        
                        if newSpots[floor] == nil {
                            newSpots[floor] = []
                        }
                        newSpots[floor]?.append(spot)
                    } catch {
                        self?.errorMessage = "Error parsing spot data"
                        self?.showError = true
                    }
                }
                
                DispatchQueue.main.async {
                    self?.parkingSpots = newSpots
                }
            }
        
        listeners.append(listener)
    }
    
    func updateSpotStatus(spotId: String, status: SpotStatus) {
        isLoading = true
        db.collection("parkingSpots").document(spotId)
            .updateData([
                "status": status.rawValue,
                "lastUpdated": Date()
            ]) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        self?.showError = true
                    }
                }
            }
    }
    
    func fetchUserBookings(userId: String) {
        let listener = db.collection("bookings")
            .whereField("userId", isEqualTo: userId)
            .order(by: "startTime", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    self?.errorMessage = error?.localizedDescription ?? "Error fetching bookings"
                    self?.showError = true
                    return
                }
                
                var newBookings: [Booking] = []
                
                for document in documents {
                    do {
                        let data = document.data()
                        guard
                            let id = data["id"] as? String,
                            let spotId = data["spotId"] as? String,
                            let userId = data["userId"] as? String,
                            let startTime = data["startTime"] as? Timestamp,
                            let endTime = data["endTime"] as? Timestamp,
                            let statusRaw = data["status"] as? String,
                            let amount = data["amount"] as? Double,
                            let status = BookingStatus(rawValue: statusRaw)
                        else {
                            continue
                        }
                        
                        let booking = Booking(
                            id: id,
                            userId: userId,
                            spotId: spotId,
                            startTime: startTime.dateValue(),
                            endTime: endTime.dateValue(),
                            status: status,
                            amount: amount
                        )
                        
                        newBookings.append(booking)
                    } catch {
                        self?.errorMessage = "Error parsing booking data"
                        self?.showError = true
                    }
                }
                
                DispatchQueue.main.async {
                    self?.bookings = newBookings
                }
            }
        
        listeners.append(listener)
    }
    
    func handleSpotSelection(spot: ParkingSpot) {
        guard spot.status == .available else { return }
        isLoading = true
        
        updateSpotStatus(spotId: spot.id, status: .reserved)
        createBooking(spotId: spot.id)
    }
    
    private func createBooking(spotId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let bookingId = UUID().uuidString
        let startTime = Date()
        let endTime = Calendar.current.date(byAdding: .hour, value: 2, to: Date())!
        
        let bookingData: [String: Any] = [
            "id": bookingId,
            "userId": userId,
            "spotId": spotId,
            "startTime": startTime,
            "endTime": endTime,
            "status": BookingStatus.active.rawValue,
            "amount": 10.0
        ]
        
        db.collection("bookings").document(bookingId).setData(bookingData) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.showError = true
                }
            }
        }
    }
}
