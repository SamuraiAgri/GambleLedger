// ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selection: Int = 0
    
    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }
                .tag(0)
            
            BetRecordView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("記録")
                }
                .tag(1)
            
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("統計")
                }
                .tag(2)
            
            BudgetView()
                .tabItem {
                    Image(systemName: "wallet.pass.fill")
                    Text("予算")
                }
                .tag(3)
            
            HistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("履歴")
                }
                .tag(4)
        }
        .accentColor(.primaryColor)
        .onChange(of: appState.selectedTab) { newValue in
            selection = newValue
        }
        .alert(isPresented: $appState.showAlert) {
            Alert(
                title: Text("通知"),
                message: Text(appState.alertMessage ?? ""),
                dismissButton: .default(Text("閉じる"))
            )
        }
    }
}
