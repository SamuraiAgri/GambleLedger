// GambleLedger/App/GambleLedgerApp.swift
import SwiftUI

@main
struct GambleLedgerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var appState = AppState()
    @StateObject private var errorHandler = ErrorHandler.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appState)
                .environmentObject(errorHandler)
                .withErrorHandling()
                .accentColor(.primaryColor)
                .preferredColorScheme(appState.useSystemTheme ? nil : (appState.isDarkMode ? .dark : .light))
                .onAppear {
                    // アプリ起動時の処理
                    appState.loadGambleTypes()
                    setupAppearance()
                }
        }
    }
    
    // UIの外観設定
    private func setupAppearance() {
        // ナビゲーションバーのスタイル設定
        UINavigationBar.appearance().tintColor = UIColor(Color.primaryColor)
        
        // タブバーのスタイル設定
        UITabBar.appearance().tintColor = UIColor(Color.primaryColor)
    }
}
