// GambleLedger/Views/Budget/BudgetView.swift
import SwiftUI

struct BudgetView: View {
    @StateObject private var viewModel = BudgetViewModel()
    @State private var showingAddBudgetSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
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
            .background(Color.backgroundPrimary.edgesIgnoringSafeArea(.all))
            .navigationTitle("予算管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddBudgetSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.primaryColor)
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.loadBudgetData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.primaryColor)
                    }
                }
            }
            .sheet(isPresented: $showingAddBudgetSheet) {
                AddBudgetSheetView(viewModel: viewModel)
            }
            .overlay(
                viewModel.isLoading ?
                    ZStack {
                        Color.black.opacity(0.2)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            
                            Text("読み込み中...")
                                .foregroundColor(.white)
                                .font(.caption)
                                .padding(.top, 4)
                        }
                        .padding(24)
                        .background(Color.gray.opacity(0.8))
                        .cornerRadius(12)
                    }
                    : nil
            )
        }
        .withErrorHandling()
    }
}

// 現在の予算表示カード
struct CurrentBudgetCard: View {
    let budget: BudgetDisplayModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "banknote")
                    .foregroundColor(.primaryColor)
                
                Text("今月の予算")
                    .font(.headline)
                    .foregroundColor(.primaryColor)
                
                Spacer()
                
                Text(budget.period)
                    .font(.subheadline)
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
                        .foregroundColor(.primaryColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("使用済み")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(budget.formattedUsedAmount)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(budget.usagePercentage > 80 ? .accentDanger : budget.usagePercentage > 60 ? .accentWarning : .gray)
                }
            }
            
            Divider()
                .background(Color.backgroundTertiary)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("残額")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(budget.formattedRemainingAmount)
                        .font(.headline)
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
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.backgroundSecondary)
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
        )
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
            HStack {
                Image(systemName: "chart.pie")
                    .foregroundColor(.secondaryColor)
                
                Text("予算使用状況")
                    .font(.headline)
                    .foregroundColor(.secondaryColor)
            }
            
            // 円グラフの代わりに改良した表示
            HStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        .frame(width: 110, height: 110)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(min(percentageUsed / 100, 1.0)))
                        .stroke(
                            getProgressColor(percentage: percentageUsed),
                            lineWidth: 12
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text("\(Int(percentageUsed))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(getProgressColor(percentage: percentageUsed))
                        
                        Text("使用済み")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    LegendItem(
                        color: .accentSuccess,
                        label: "残額",
                        amount: remainingAmount
                    )
                    
                    LegendItem(
                        color: getProgressColor(percentage: percentageUsed),
                        label: "使用済み",
                        amount: usedAmount
                    )
                    
                    // 予測情報
                    if totalAmount > 0 {
                        let daysInMonth = Double(Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30)
                        let dayOfMonth = Double(Calendar.current.component(.day, from: Date()))
                        let projectedUsage = (usedAmount / Decimal(dayOfMonth)) * Decimal(daysInMonth)
                        
                        if projectedUsage > totalAmount {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.accentWarning)
                                    .font(.caption)
                                
                                Text("この使用ペースだと予算オーバーします")
                                    .font(.caption)
                                    .foregroundColor(.accentWarning)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            
            Text("期間: \(period)")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.backgroundSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.secondaryColor.opacity(0.5), .secondaryColor]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
    }
    
    private func getProgressColor(percentage: Double) -> Color {
        if percentage < 60 {
            return .accentSuccess
        } else if percentage < 80 {
            return .accentWarning
        } else {
            return .accentDanger
        }
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
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(amount.formatted(.currency(code: "JPY")))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

// ギャンブル種別別予算カード
struct GambleTypeBudgetsCard: View {
    let budgets: [BudgetDisplayModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bookmark.circle")
                    .foregroundColor(.secondaryColor)
                
                Text("ギャンブル種別別予算")
                    .font(.headline)
                    .foregroundColor(.secondaryColor)
            }
            
            ForEach(budgets, id: \.id) { budget in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        if let color = budget.gambleTypeColor {
                            Circle()
                                .fill(color)
                                .frame(width: 14, height: 14)
                                .shadow(color: color.opacity(0.5), radius: 1, x: 0, y: 1)
                        }
                        
                        Text(budget.gambleType ?? "不明")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(budget.formattedUsagePercentage) 使用")
                            .font(.caption)
                            .fontWeight(.medium)
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
                        .background(Color.backgroundTertiary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.backgroundSecondary)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
    }
}

// 予算未設定時のビュー
struct NoBudgetView: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.secondaryColor)
                .padding()
                .background(
                    Circle()
                        .fill(Color.secondaryColor.opacity(0.1))
                        .frame(width: 110, height: 110)
                )
            
            Text("予算が設定されていません")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primaryColor)
            
            Text("月別予算を設定して、効果的な資金管理を始めましょう。予算設定はギャンブルを健全に楽しむための第一歩です。")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            
            Button(action: action) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("予算を設定する")
                        .fontWeight(.semibold)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.primaryColor, .primaryColor.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(color: Color.primaryColor.opacity(0.4), radius: 4, x: 0, y: 2)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.backgroundSecondary)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

// 予算設定シート
struct AddBudgetSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: BudgetViewModel
    
    var body: some View {
        NavigationView {
            Form {
                // 予算金額
                Section(header: Text("予算金額")) {
                    HStack {
                        Text("金額")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        TextField("0", text: $viewModel.budgetAmount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.primary)
                        
                        Text("円")
                            .foregroundColor(.gray)
                    }
                }
                
                // 期間
                Section(header: Text("期間")) {
                    DatePicker("開始日", selection: $viewModel.selectedStartDate, displayedComponents: .date)
                        .accentColor(.primaryColor)
                    
                    DatePicker("終了日", selection: $viewModel.selectedEndDate, displayedComponents: .date)
                        .accentColor(.primaryColor)
                    
                    // クイック期間選択
                    HStack {
                        Spacer()
                        
                        Button("今月") {
                            let today = Date()
                            viewModel.selectedStartDate = today.startOfMonth()
                            viewModel.selectedEndDate = today.endOfMonth()
                        }
                        .buttonStyle(.bordered)
                        .tint(.primaryColor)
                        
                        Button("翌月") {
                            let today = Date()
                            let calendar = Calendar.current
                            if let nextMonth = calendar.date(byAdding: .month, value: 1, to: today) {
                                viewModel.selectedStartDate = nextMonth.startOfMonth()
                                viewModel.selectedEndDate = nextMonth.endOfMonth()
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.secondaryColor)
                        
                        Spacer()
                    }
                }
                
                // 通知設定
                Section(header: Text("通知設定")) {
                    HStack {
                        Text("予算\(viewModel.notifyThreshold)%使用で通知")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Stepper("", value: $viewModel.notifyThreshold, in: 50...90, step: 5)
                            .labelsHidden()
                    }
                }
                
                // ギャンブル種別（任意）
                Section(header: Text("ギャンブル種別（任意）")) {
                    Picker("ギャンブル種別", selection: $viewModel.selectedGambleTypeID) {
                        Text("全ギャンブル").tag(nil as UUID?)
                        
                        ForEach(viewModel.gambleTypes) { type in
                            HStack {
                                Circle()
                                    .fill(type.color)
                                    .frame(width: 10, height: 10)
                                
                                Text(type.name)
                            }
                            .tag(type.id as UUID?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // 保存ボタン
                Section {
                    Button(action: {
                        // タイマーを使用して、保存アクションを少し遅らせ、UIをブロックしないようにする
                        viewModel.isLoading = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            viewModel.saveBudget()
                            viewModel.isLoading = false
                            dismiss()
                        }
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("予算を設定")
                                    .fontWeight(.bold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isLoading)
                    .listRowBackground(Color.primaryColor)
                    .foregroundColor(.white)
                }
            }
            .navigationTitle("予算設定")
            .alert(isPresented: $viewModel.showError) {
                Alert(
                    title: Text("エラー"),
                    message: Text(viewModel.errorMessage ?? "不明なエラーが発生しました"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

#Preview {
    BudgetView()
}
