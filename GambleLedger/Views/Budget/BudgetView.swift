// GambleLedger/Views/Budget/BudgetView.swift
import SwiftUI

struct BudgetView: View {
    @StateObject private var viewModel = BudgetViewModel()
    @State private var showingAddBudgetSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 現在の予算カード
                    if let currentBudget = viewModel.currentBudget {
                        CurrentBudgetCard(budget: currentBudget)
                    } else {
                        NoBudgetView(action: { showingAddBudgetSheet = true })
                    }
                    
                    // 予算使用状況グラフ
                    if let currentBudget = viewModel.currentBudget {
                        BudgetUsageCard(
                            totalAmount: currentBudget.totalAmount,
                            usedAmount: currentBudget.usedAmount,
                            period: currentBudget.period
                        )
                    }
                    
                    // ギャンブル種別別予算（あれば表示）
                    if !viewModel.gambleTypeBudgets.isEmpty {
                        GambleTypeBudgetsCard(budgets: viewModel.gambleTypeBudgets)
                    }
                }
                .padding()
            }
            .navigationTitle("予算管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddBudgetSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.loadBudgetData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingAddBudgetSheet) {
                AddBudgetView(viewModel: viewModel)
            }
            .overlay(
                viewModel.isLoading ?
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle())
                    : nil
            )
        }
    }
}

// 現在の予算表示カード
struct CurrentBudgetCard: View {
    let budget: BudgetDisplayModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("今月の予算")
                    .font(.headline)
                    .foregroundColor(.secondaryColor)
                
                Spacer()
                
                Text(budget.period)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("予算総額")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(budget.formattedTotalAmount)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("使用済み")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(budget.formattedUsedAmount)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(budget.usagePercentage > 80 ? .accentDanger : .primary)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("残額")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(budget.formattedRemainingAmount)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(budget.statusColor)
                }
                
                BudgetProgressBar(
                    current: budget.usedAmount,
                    total: budget.totalAmount
                )
                
                Text(budget.statusMessage)
                    .font(.caption)
                    .foregroundColor(budget.statusColor)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// 予算使用状況グラフカード
struct BudgetUsageCard: View {
    let totalAmount: Decimal
    let usedAmount: Decimal
    let period: String
    
    private var remainingAmount: Decimal {
        totalAmount - usedAmount
    }
    
    private var percentageUsed: Double {
        Double(truncating: (usedAmount / totalAmount * 100) as NSNumber)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("予算使用状況")
                .font(.headline)
                .foregroundColor(.secondaryColor)
            
            // 円グラフの代わりに簡易的な表示
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(min(percentageUsed / 100, 1.0)))
                        .stroke(
                            percentageUsed < 60 ? Color.accentSuccess :
                                percentageUsed < 80 ? Color.accentWarning : Color.accentDanger,
                            lineWidth: 10
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text("\(Int(percentageUsed))%")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("使用済み")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    LegendItem(
                        color: .accentSuccess,
                        label: "残額",
                        amount: remainingAmount
                    )
                    
                    LegendItem(
                        color: .accentDanger,
                        label: "使用済み",
                        amount: usedAmount
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
            
            Text("期間: \(period)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// 凡例アイテム
struct LegendItem: View {
    let color: Color
    let label: String
    let amount: Decimal
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            Text(amount.formatted(.currency(code: "JPY")))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

// ギャンブル種別別予算カード
struct GambleTypeBudgetsCard: View {
    let budgets: [BudgetDisplayModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ギャンブル種別別予算")
                .font(.headline)
                .foregroundColor(.secondaryColor)
            
            ForEach(budgets, id: \.id) { budget in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if let color = budget.gambleTypeColor {
                            Circle()
                                .fill(color)
                                .frame(width: 10, height: 10)
                        }
                        
                        Text(budget.gambleType ?? "不明")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(budget.formattedUsagePercentage) 使用")
                            .font(.caption)
                            .foregroundColor(budget.statusColor)
                    }
                    
                    BudgetProgressBar(
                        current: budget.usedAmount,
                        total: budget.totalAmount,
                        showPercentage: false
                    )
                    
                    HStack {
                        Text("残額: \(budget.formattedRemainingAmount)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("予算: \(budget.formattedTotalAmount)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
                
                if budget.id != budgets.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// 予算未設定時のビュー
struct NoBudgetView: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("予算が設定されていません")
                .font(.headline)
            
            Text("月別予算を設定して、効果的な資金管理を始めましょう。")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button(action: action) {
                Text("予算を設定する")
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x:
