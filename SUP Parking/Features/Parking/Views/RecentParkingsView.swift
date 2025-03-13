//
//  RecentParkingsView.swift
//  SUP Parking
//
//  Created by Pyae Sone Hein on 2/23/25.
//
import SwiftUI

struct RecentParkingsView: View {
    @EnvironmentObject private var viewModel: ParkingViewModel
    
    // Get active bookings sorted by start time (most recent first)
    var activeBookings: [Booking] {
        return viewModel.bookings
            .filter { $0.isActive }
            .sorted(by: { $0.startTime > $1.startTime })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Parkings")
                    .font(.title2)
                    .bold()
                Spacer()
                NavigationLink("See all") {
                    BookingView()
                        .environmentObject(viewModel)
                }
            }
            
            if activeBookings.isEmpty {
                Text("No active parkings")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical)
            } else {
                ForEach(activeBookings.prefix(3)) { booking in
                    RecentParkingCardView(booking: booking)
                }
            }
        }
        .padding()
    }
}

struct RecentParkingCardView: View {
    let booking: Booking
    @EnvironmentObject private var viewModel: ParkingViewModel
    
    // Format time range for display
    var timeRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return "\(formatter.string(from: booking.startTime)) - \(formatter.string(from: booking.endTime))"
    }
    
    // Calculate time remaining
    var timeRemaining: String {
        let remaining = booking.endTime.timeIntervalSince(Date())
        if remaining <= 0 {
            return "Expired"
        }
        
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else {
            return "\(minutes)m remaining"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Parking Spot \(booking.spotId)")
                        .font(.headline)
                    Text(timeRange)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                Text(booking.status.rawValue.capitalized)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(20)
            }
            
            HStack {
                Text("$\(String(format: "%.2f", booking.amount))")
                    .foregroundColor(.gray)
                Spacer()
                Text(timeRemaining)
                    .font(.caption)
                    .foregroundColor(.orange)
                Spacer()
                Button("Extend") {
                    // Add extension functionality here when ready
                    // For now, just show an alert
                    viewModel.errorMessage = "Extend functionality coming soon!"
                    viewModel.showError = true
                }
                .foregroundColor(.blue)
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
