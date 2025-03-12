//
//  ContentView.swift
//  SUP Parking
//
//  Created by Pyae Sone Hein on 2/23/25.


// Models/ParkingSpot.swift
// ContentView.swift

// ContentView.swift

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var parkingViewModel = ParkingViewModel()
    @State private var selectedTab = 0
    @State private var showingProfile = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                HomeView()
                    .environmentObject(parkingViewModel)
                    .environmentObject(authViewModel)
                    .navigationTitle("Smart Parking")
                    .navigationBarItems(trailing:
                        UserProfileComponent(action: {
                            showingProfile = true
                        })
                        .environmentObject(authViewModel)
                    )
            }
            .tabItem {
                Label("Home", systemImage: "car.fill")
            }
            .tag(0)
            
            NavigationView {
                MapView()
                    .environmentObject(parkingViewModel)
                    .navigationBarItems(trailing:
                        UserProfileComponent()
                            .environmentObject(authViewModel)
                            .onTapGesture {
                                showingProfile = true
                            }
                    )
            }
            .tabItem {
                Label("Map", systemImage: "map.fill")
            }
            .tag(1)
            
            NavigationView {
                BookingView()
                    .environmentObject(parkingViewModel)
                    .navigationBarItems(trailing:
                        UserProfileComponent()
                            .environmentObject(authViewModel)
                            .onTapGesture {
                                showingProfile = true
                            }
                    )
            }
            .tabItem {
                Label("Bookings", systemImage: "clock.fill")
            }
            .tag(2)
            
            if authViewModel.user?.isAdmin == true {
                NavigationView {
                    AdminView()
                        .environmentObject(parkingViewModel)
                        .navigationBarItems(trailing:
                            UserProfileComponent()
                                .environmentObject(authViewModel)
                                .onTapGesture {
                                    showingProfile = true
                                }
                        )
                }
                .tabItem {
                    Label("Admin", systemImage: "gear")
                }
                .tag(3)
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
                .environmentObject(authViewModel)
        }
        .onAppear {
            parkingViewModel.observeParkingSpots()
            if let userId = authViewModel.user?.id {
                parkingViewModel.fetchUserBookings(userId: userId)
            }
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var viewModel: ParkingViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HeaderView()
                SearchBarView(text: $viewModel.searchQuery)
                StatsView()
                RecentParkingsView()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
}
// MapView.swift
struct MapView: View {
    @EnvironmentObject private var viewModel: ParkingViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                FloorSelectorView()
                ParkingGridView()
                    .padding()
                Spacer()
            }
            .navigationTitle("Parking Map")
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }
}

// BookingView.swift
struct BookingView: View {
    @EnvironmentObject private var viewModel: ParkingViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.bookings) { booking in
                    BookingRowView(booking: booking)
                }
            }
            .navigationTitle("My Bookings")
            .refreshable {
                if let userId = Auth.auth().currentUser?.uid {
                    viewModel.fetchUserBookings(userId: userId)
                }
            }
        }
    }
}

// MARK: - Components

struct HeaderView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .center) {
                Text("Welcome Back")
                    .font(.system(size: 24, weight: .bold))
                    .position(x: UIScreen.main.bounds.width / 3, y: 150)
                Text(authViewModel.user?.name ?? "")
                    .font(.title)
                    .bold()
            }
            
            Spacer()
            
            Button {
                authViewModel.signOut()
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.title2)
            }
        }
        .padding()
    }
}

struct SearchBarView: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search parking spots...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct StatsView: View {
    @EnvironmentObject private var viewModel: ParkingViewModel
    
    var availableSpots: Int {
        viewModel.parkingSpots.values.flatMap { $0 }.filter { $0.status == .available }.count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                StatCard(
                    title: "Available Spots",
                    value: "\(availableSpots)",
                    icon: "car.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Active Bookings",
                    value: "\(viewModel.bookings.filter { $0.isActive }.count)",
                    icon: "clock.fill",
                    color: .green
                )
            }
        }
        .padding()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.title2)
                    .bold()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FloorSelectorView: View {
    @EnvironmentObject private var viewModel: ParkingViewModel
    
    var body: some View {
        HStack {
            ForEach(1...5, id: \.self) { floor in
                Button {
                    viewModel.selectedFloor = floor
                } label: {
                    Text("\(floor)")
                        .font(.headline)
                        .frame(width: 40, height: 40)
                        .background(viewModel.selectedFloor == floor ? Color.blue : Color(.systemGray5))
                        .foregroundColor(viewModel.selectedFloor == floor ? .white : .primary)
                        .clipShape(Circle())
                }
            }
        }
        .padding()
    }
}

struct ParkingGridView: View {
    @EnvironmentObject private var viewModel: ParkingViewModel
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
            ForEach(viewModel.parkingSpots[viewModel.selectedFloor] ?? []) { spot in
                ParkingSpotView(spot: spot)
            }
        }
    }
}

struct ParkingSpotView: View {
    let spot: ParkingSpot
    @EnvironmentObject private var viewModel: ParkingViewModel
    
    var body: some View {
        Button {
            viewModel.handleSpotSelection(spot: spot)
        } label: {
            VStack {
                Text(spot.id)
                    .font(.headline)
                Text(spot.status.rawValue)
                    .font(.caption)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(spot.status.color.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(spot.status.color, lineWidth: 2)
            )
        }
        .disabled(spot.status != .available || viewModel.isLoading)
    }
}

struct BookingRowView: View {
    let booking: Booking
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Spot \(booking.spotId)")
                .font(.headline)
            
            HStack {
                Text(booking.startTime, style: .date)
                Text("-")
                Text(booking.endTime, style: .time)
            }
            .font(.subheadline)
            
            HStack {
                Text(booking.status.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(8)
                
                Spacer()
                
                Text("$\(String(format: "%.2f", booking.amount))")
                    .font(.subheadline)
                    .bold()
            }
        }
        .padding(.vertical, 8)
    }
    
    private var statusColor: Color {
        switch booking.status {
        case .active: return .green
        case .completed: return .blue
        case .cancelled: return .red
        }
    }
}


