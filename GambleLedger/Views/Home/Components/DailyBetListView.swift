// GambleLedger/Views/Home/Components/DailyBetListView.swift
import SwiftUI

/// 特定の日付のベット記録一覧と新規追加オプションを表示するビュー
struct DailyBetListView: View {
    let date: Date
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: DailyBetListViewModel
    @State private var showSimpleRecord = false
    @State private var showDetailedRecord = false
    @State private var showEditView = false
    @State private var recordToEdit: BetRecordModel?
    @State private var showDeleteAlert = false
    @State private var recordToDelete: String?
    
    init(date: Date) {
        self.date = date
        self._viewModel = StateObject(wrappedValue: DailyBetListViewModel(date: date))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 日付とサマリーヘッダー
                DailySummaryHeader(
                    date: date,
                    totalBet: viewModel.totalBet,
                    totalReturn: viewModel.totalReturn,
                    profit: viewModel.profit
                )
                .padding()
                .background(Color.backgroundSecondary)
                
                // ベット記録リスト
                if viewModel.records.isEmpty {
                    EmptyDailyRecordsView()
                } else {
                    List {
                        ForEach(viewModel.records, id: \.id) { record in
                            DailyBetRowView(record: record)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        recordToDelete = record.id
                                        showDeleteAlert = true
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        recordToEdit = record
                                        showEditView = true
                                    } label: {
                                        Label("編集", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                                .listRowBackground(Color.backgroundPrimary)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
                
                // 新規追加ボタン
                AddRecordButtonsView(
                    onSimpleAdd: {
                        showSimpleRecord = true
                    },
                    onDetailedAdd: {
                        showDetailedRecord = true
                    }
                )
                .padding()
                .background(Color.backgroundSecondary)
            }
            .background(Color.backgroundPrimary.edgesIgnoringSafeArea(.all))
            .navigationTitle(date.formattedString(format: "yyyy年MM月dd日"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.loadRecords()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.primaryColor)
                    }
                }
            }
            .sheet(isPresented: $showSimpleRecord) {
                SimpleBetRecordView(initialDate: date)
                    .onDisappear {
                        viewModel.loadRecords()
                    }
            }
            .sheet(isPresented: $showDetailedRecord) {
                DetailedBetRecordView(initialDate: date)
                    .onDisappear {
                        viewModel.loadRecords()
                    }
            }
            .sheet(item: $recordToEdit) { record in
                EditBetRecordView(recordId: record.id)
                    .onDisappear {
                        viewModel.loadRecords()
                    }
            }
            .alert("記録を削除", isPresented: $showDeleteAlert) {
                Button("キャンセル", role: .cancel) {
                    recordToDelete = nil
                }
                Button("削除", role: .destructive) {
                    if let id = recordToDelete {
                        viewModel.deleteRecord(id: id)
                        recordToDelete = nil
                    }
                }
            } message: {
                Text("この記録を削除してもよろしいですか？")
            }
        }
    }
}

// MARK: - Daily Summary Header
struct DailySummaryHeader: View {
    let date: Date
    let totalBet: Decimal
    let totalReturn: Decimal
    let profit: Decimal
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("賭け金額")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(totalBet))
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    Text("回収金額")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(totalReturn))
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("収支")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(profit))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(profit >= 0 ? .accentSuccess : .accentDanger)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.backgroundPrimary)
            )
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        return formatter.string(from: amount as NSDecimalNumber) ?? "¥0"
    }
}

// MARK: - Daily Bet Row View
struct DailyBetRowView: View {
    let record: BetRecordModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // ギャンブル種類
                Text(record.gambleTypeName)
                    .font(.headline)
                    .foregroundColor(.primaryColor)
                
                Spacer()
                
                // 時刻
                Text(record.date.formattedString(format: "HH:mm"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // メモ（あれば）
            if !record.memo.isEmpty {
                Text(record.memo)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                // 賭け金額
                Label {
                    Text(formatCurrency(record.betAmount))
                        .font(.subheadline)
                } icon: {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.orange)
                }
                
                // 回収金額
                Label {
                    Text(formatCurrency(record.returnAmount))
                        .font(.subheadline)
                } icon: {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                // 収支
                Text(formatProfit(record.profit))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(record.profit >= 0 ? .accentSuccess : .accentDanger)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        return formatter.string(from: amount as NSDecimalNumber) ?? "¥0"
    }
    
    private func formatProfit(_ amount: Decimal) -> String {
        let prefix = amount >= 0 ? "+" : ""
        return prefix + formatCurrency(amount)
    }
}

// MARK: - Empty Daily Records View
struct EmptyDailyRecordsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("この日の記録がありません")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("下のボタンから記録を追加してください")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Add Record Buttons View
struct AddRecordButtonsView: View {
    let onSimpleAdd: () -> Void
    let onDetailedAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 簡易記録ボタン
            Button(action: onSimpleAdd) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("簡易記録")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.primaryColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            // 詳細記録ボタン
            Button(action: onDetailedAdd) {
                HStack {
                    Image(systemName: "plus.square.fill")
                    Text("詳細記録")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.secondaryColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - BetRecordModel for Display
struct BetRecordModel: Identifiable {
    let id: String
    let date: Date
    let gambleTypeName: String
    let betAmount: Decimal
    let returnAmount: Decimal
    let profit: Decimal
    let memo: String
}
