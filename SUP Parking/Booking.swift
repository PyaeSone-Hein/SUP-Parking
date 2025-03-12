//
//  Booking.swift
//  SUP Parking
//
//  Created by Pyae Sone Hein on 2/23/25.
//

import Foundation

struct Booking: Identifiable, Codable {
    let id: String
    let userId: String
    let spotId: String
    let startTime: Date
    let endTime: Date
    let status: BookingStatus
    let amount: Double
    
    var isActive: Bool {
        return status == .active && endTime > Date()
    }
}

enum BookingStatus: String, Codable {
    case active, completed, cancelled
}
