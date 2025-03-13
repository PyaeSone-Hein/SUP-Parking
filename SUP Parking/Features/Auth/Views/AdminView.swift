//
//  AdminView.swift
//  SUP Parking
//
//  Created by Pyae Sone Hein on 2/23/25.
//
import SwiftUI
import Firebase

struct AdminView: View {
    @EnvironmentObject var parkingViewModel: ParkingViewModel
    @State private var showingAddSpot = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(parkingViewModel.parkingSpots.keys.sorted()), id: \.self) { floor in
                    Section("Floor \(floor)") {
                        ForEach(parkingViewModel.parkingSpots[floor] ?? []) { spot in
                            SpotManagementRow(spot: spot)
                        }
                    }
                }
            }
            .navigationTitle("Parking Management")
            .toolbar {
                Button("Add Spot") {
                    showingAddSpot = true
                }
            }
            .sheet(isPresented: $showingAddSpot) {
                AddSpotView()
            }
        }
    }
}

struct SpotManagementRow: View {
    let spot: ParkingSpot
    @EnvironmentObject var parkingViewModel: ParkingViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Spot \(spot.id)")
                    .font(.headline)
                Text(spot.status.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundColor(spot.status.color)
            }
            
            Spacer()
            
            Menu {
                ForEach(SpotStatus.allCases, id: \.self) { status in
                    Button(status.rawValue.capitalized) {
                        parkingViewModel.updateSpotStatus(spotId: spot.id, status: status)
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
}
