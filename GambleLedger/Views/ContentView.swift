// GambleLedger/Views/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var errorHandler: ErrorHandler
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
        .overlay(
            errorHandler.showingError ?
                VStack {
                    Spacer()
                    
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                        
                        Text(errorHandler.currentError?.message ?? "エラーが発生しました")
                            .foregroundColor(.white)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Button(action: {
                            errorHandler.dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(Color.accentDanger)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: errorHandler.showingError)
                : nil
        )
    }
}
