// GambleLedgerApp.swift
import SwiftUI

@main
struct GambleLedgerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appState)
        }
    }
}

// AppState.swift
import Foundation

class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var showAddBetSheet: Bool = false
    @Published var alertMessage: String?
    @Published var showAlert: Bool = false
}
