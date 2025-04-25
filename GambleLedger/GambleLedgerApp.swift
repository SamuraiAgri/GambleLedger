//
//  GambleLedgerApp.swift
//  GambleLedger
//
//  Created by rinka on 2025/04/25.
//

import SwiftUI

@main
struct GambleLedgerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
