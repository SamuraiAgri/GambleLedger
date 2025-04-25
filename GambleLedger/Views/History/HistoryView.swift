// GambleLedger/Views/History/HistoryView.swift
import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var showDatePicker = false
    @State private var showDeleteAlert = false
    @State private var recordToDelete: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 検索・フィルターバー
                SearchFilterBar(
                    searchText: $viewModel.searchText,
                    showDatePicker: $showDatePicker,
                    startDate: viewModel.filterStartDate.formattedString(),
                    endDate: viewModel.filterEndDate.formattedString()
                )
                
                // 絞り込みオプション
                FilterOptionsView(
                    sortOption: $viewModel.sortOption,
                    selectedGambleTypeID: $viewModel.selectedGambleTypeID,
                    gambleTypes: viewModel.gambleTypes
                )
                
                // 日付ピッカー（表示/非表示切り替え）
                if showDatePicker {
                    DateRangePickerView(
                        startDate: $viewModel.filterStartDate,
                        endDate: $viewModel.filterEndDate
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // 履歴リスト
                if viewModel.filteredRecords.isEmpty {
                    EmptyHistoryView()
                } else {
                    BetHistoryList(
                        records: viewModel.filteredRecords,
                        onDelete: { id in
                            recordToDelete = id
                            showDeleteAlert = true
                        }
                    )
                }
            }
            .navigationTitle("ベット履歴")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.loadBetRecords()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .overlay(
                viewModel.isLoading ?
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle())
                    : nil
            )
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("記録の削除"),
                    message: Text("この記録を削除してもよろしいですか？"),
                    primaryButton: .destructive(Text("削除")) {
                        if let id = recordToDelete {
                            viewModel.deleteBetRecord(id: id)
                        }
                    },
                    secondaryButton: .cancel(Text("キャンセル"))
                )
            }
        }
    }
}

// 検索・フィルターバー
struct SearchFilterBar: View {
    @Binding var searchText: String
    @Binding var showDatePicker: Bool
    let startDate: String
    let endDate: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("イベント名・賭式で検索", text: $searchText)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color.backgroundTertiary.opacity(0.3))
            .cornerRadius(8)
            
            Button(action: {
                withAnimation {
                    showDatePicker.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.primaryColor)
                    
                    Text("\(startDate) - \(endDate)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: showDatePicker ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(8)
                .background(Color.backgroundTertiary.opacity(0.3))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.backgroundSecondary)
    }
}

// フィルターオプション
struct FilterOptionsView: View {
    @Binding var sortOption: HistoryViewModel.SortOption
    @Binding var selectedGambleTypeID: UUID?
    let gambleTypes: [GambleTypeModel]
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack {
                // ソートオプション
                Menu {
                    Picker("並び替え", selection: $sortOption) {
                        ForEach(HistoryViewModel.SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                        Text("並び替え")
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)
                }
                
                Spacer()
                
                // ギャンブル種別フィルター
                Menu {
                    Button(action: {
                        selectedGambleTypeID = nil
                    }) {
                        HStack {
                            Text("すべて")
                            if selectedGambleTypeID == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Divider()
                    
                    ForEach(gambleTypes) { type in
                        Button(action: {
                            selectedGambleTypeID = type.id
                        }) {
                            HStack {
                                Text(type.name)
                                if selectedGambleTypeID == type.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("種別")
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.backgroundSecondary)
            
            Divider()
        }
    }
}

// 日付範囲ピッカー
struct DateRangePickerView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("開始日")
                    .font(.subheadline)
                
                Spacer()
                
                DatePicker(
                    "",
                    selection: $startDate,
                    displayedComponents: .date
                )
                .labelsHidden()
            }
            
            HStack {
                Text("終了日")
                    .font(.subheadline)
                
                Spacer()
                
                DatePicker(
                    "",
                    selection: $endDate,
                    displayedComponents: .date
                )
                .labelsHidden()
            }
            
            // クイック選択ボタン
            HStack(spacing: 8) {
                QuickDateButton(title: "今月", action: {
                    let today = Date()
                    startDate = today.startOfMonth()
                    endDate = today
                })
                
                QuickDateButton(title: "先月", action: {
                    let today = Date()
                    let calendar = Calendar.current
                    if let prevMonth = calendar.date(byAdding: .month, value: -1, to: today) {
                        startDate = prevMonth.startOfMonth()
                        endDate = prevMonth.endOfMonth()
                    }
                })
                
                QuickDateButton(title: "3ヶ月", action: {
                    let today = Date()
                    let calendar = Calendar.current
                    if let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: today) {
                        startDate = threeMonthsAgo
                        endDate = today
                    }
                })
                
                QuickDateButton(title: "全期間", action: {
                    let today = Date()
                    let calendar = Calendar.current
                    if let yearAgo = calendar.date(byAdding: .year, value: -3, to: today) {
                        startDate = yearAgo
                        endDate = today
                    }
                })
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
    }
}

// クイック日付選択ボタン
struct QuickDateButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.backgroundTertiary)
                .foregroundColor(.primary)
                .cornerRadius(4)
        }
    }
}

// ベット履歴リスト
struct BetHistoryList: View {
    let records: [BetRecordDisplayModel]
    let onDelete: (String) -> Void
    
    var body: some View {
        List {
            ForEach(records) { record in
                BetHistoryCell(record: record)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            onDelete(record.id)
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(PlainListStyle())
    }
}

// ベット履歴セル
struct BetHistoryCell: View {
    let record: BetRecordDisplayModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // ギャンブル種別マーク
                Circle()
                    .fill(record.gambleTypeColor)
                    .frame(width: 12, height: 12)
                
                Text(record.gambleType)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                // 日付
                Text(record.formattedDate)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.eventName)
                        .font(.headline)
                    
                    Text(record.bettingSystem)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 損益表示
                VStack(alignment: .trailing, spacing: 4) {
                    Text(record.profit >= 0 ? "勝ち" : "負け")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(record.isWin ? Color.accentSuccess.opacity(0.2) : Color.accentDanger.opacity(0.2))
                        .foregroundColor(record.isWin ? .accentSuccess : .accentDanger)
                        .cornerRadius(4)
                    
                    Text(record.formattedProfit)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(record.profit >= 0 ? .accentSuccess : .accentDanger)
                }
            }
            
            Divider()
            
            HStack {
                Text("賭け金: \(record.formattedBetAmount)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("払戻: \(record.formattedReturnAmount)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("ROI: \(record.formattedROI)")
                    .font(.caption)
                    .foregroundColor(record.roi >= 0 ? .accentSuccess : .accentDanger)
                    .padding(.leading, 8)
            }
        }
        .padding(.vertical, 8)
    }
}

// 履歴がない場合の表示
struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("記録がありません")
                .font(.headline)
            
            Text("ベット記録を追加すると、ここに履歴が表示されます")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary)
    }
}

#Preview {
    HistoryView()
}
