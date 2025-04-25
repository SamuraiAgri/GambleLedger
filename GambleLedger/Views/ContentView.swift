// GambleLedger/Views/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house")
                }
                .tag(0)
            
            BetRecordView()
                .tabItem {
                    Label("記録", systemImage: "plus.circle")
                }
                .tag(1)
            
            HistoryView()
                .tabItem {
                    Label("履歴", systemImage: "clock")
                }
                .tag(2)
            
            StatisticsView()
                .tabItem {
                    Label("統計", systemImage: "chart.bar")
                }
                .tag(3)
            
            BudgetView()
                .tabItem {
                    Label("予算", systemImage: "banknote")
                }
                .tag(4)
        }
        .accentColor(.primaryColor)
        .alert(isPresented: $appState.showAlert) {
            Alert(
                title: Text("お知らせ"),
                message: Text(appState.alertMessage ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppState())
}
