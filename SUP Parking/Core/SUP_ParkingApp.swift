//
//  SUP_ParkingApp.swift
//  SUP Parking
//
//  Created by Pyae Sone Hein on 2/23/25.
//
import SwiftUI
import Firebase

@main
struct SUP_ParkingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
}


