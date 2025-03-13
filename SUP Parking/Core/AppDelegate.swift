//
//  AppDelegate.swift
//  SUP Parking
//
//  Created by Pyae Sone Hein on 2/23/25.
//
// MARK: - App Delegate
// AppDelegate.swift


// MARK: - Models
// User.swift
import UIKit
import FirebaseCore
import FirebaseFirestore
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

// MARK: - Models
// User.swift
struct User: Codable, Identifiable {
    let id: String
    let email: String
    var name: String
    let created: Date
    var isAdmin: Bool
    var profileImageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, email, name, created, isAdmin, profileImageUrl
    }
}

// ParkingSpot.swift
struct ParkingSpot: Identifiable, Codable {
    let id: String
    var status: SpotStatus
    let type: SpotType
    var lastUpdated: Date
    var floor: Int
    
    var dictionary: [String: Any] {
        return [
            "id": id,
            "status": status.rawValue,
            "type": type.rawValue,
            "lastUpdated": lastUpdated,
            "floor": floor
        ]
    }
}

enum SpotStatus: String, Codable, CaseIterable {
    case available, occupied, reserved, disabled
    
    var color: Color {
        switch self {
        case .available: return .green
        case .occupied: return .red
        case .reserved: return .yellow
        case .disabled: return .blue
        }
    }
}

enum SpotType: String, Codable {
    case standard, disabled
}
