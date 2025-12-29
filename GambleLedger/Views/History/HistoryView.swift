// GambleLedger/Views/History/HistoryView.swift
import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var showDatePicker = false
    @State private var showDeleteAlert = false
    @State private var recordToDelete: String?
    @State private var showEditView = false
    @State private var recordToEdit: BetRecordModel?
    @State private var recordToEditId: String?
    @EnvironmentObject private var errorHandler: ErrorHandler
    
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
                        endDate: $viewModel.filterEndDate,
                        onQuickSelect: { period in
                            viewModel.setDateFilter(period: period)
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // 履歴リスト
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .primaryColor))
                    Spacer()
                } else if viewModel.filteredRecords.isEmpty {
                    EmptyHistoryView()
                } else {
                    BetHistoryList(
                        records: viewModel.filteredRecords,
                        onDelete: { id in
                            recordToDelete = id
                            showDeleteAlert = true
                        },
                        onEdit: { id in
                            recordToEditId = id
                            // 非同期でレコードを取得
                            Task {
                                await viewModel.loadBetRecordForEdit(id: id) { record in
                                    recordToEdit = record
                                    showEditView = true
                                }
                            }
                        }
                    )
                }
                
                // バナー広告（履歴画面下部）
                BannerAdContainer()
            }
            .background(Color.backgroundPrimary.edgesIgnoringSafeArea(.all))
            .navigationTitle("ベット履歴")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            viewModel.loadBetRecords()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.primaryColor)
                    }
                    .accessibilityLabel("データを再読み込み")
                }
            }
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
            .alert(isPresented: $viewModel.showError) {
                Alert(
                    title: Text("エラー"),
                    message: Text(viewModel.errorMessage ?? "不明なエラーが発生しました"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showEditView) {
                if let record = recordToEdit {
                    EditBetRecordView(viewModel: EditBetRecordViewModel(record: record))
                        .onDisappear {
                            recordToEdit = nil
                            recordToEditId = nil
                            // 編集後にデータを再読み込み
                            viewModel.loadBetRecords()
                        }
                }
            }
        }
        .withErrorHandling()
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
                    .foregroundColor(.primaryColor)
                
                TextField("イベント名・賭式で検索", text: $searchText)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(8)
                    .background(Color.backgroundTertiary.opacity(0.3))
                    .cornerRadius(8)
                
                if !searchText.isEmpty {
                    Button(action: {
                        withAnimation {
                            searchText = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
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
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .background(
                    Color.backgroundTertiary.opacity(0.3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primaryColor.opacity(0.3), lineWidth: 1)
                        )
                )
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.backgroundSecondary)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
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
                            .foregroundColor(.primaryColor)
                        Text("並び替え")
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.backgroundTertiary.opacity(0.2))
                    )
                }
                
                Spacer()
                
                // ギャンブル種別フィルター
                Menu {
                    Button(action: {
                        withAnimation {
                            selectedGambleTypeID = nil
                        }
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
                            withAnimation {
                                selectedGambleTypeID = type.id
                            }
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
                            .foregroundColor(.secondaryColor)
                        Text("種別")
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.backgroundTertiary.opacity(0.2))
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.backgroundSecondary)
            
            Divider()
        }
    }
}

// 日付範囲ピッカー
struct DateRangePickerView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    var onQuickSelect: (HistoryViewModel.DateFilterPeriod) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("開始日")
                    .font(.subheadline)
                    .foregroundColor(.primaryColor)
                
                Spacer()
                
                DatePicker(
                    "",
                    selection: $startDate,
                    displayedComponents: .date
                )
                .labelsHidden()
                .accentColor(.primaryColor)
            }
            
            HStack {
                Text("終了日")
                    .font(.subheadline)
                    .foregroundColor(.primaryColor)
                
                Spacer()
                
                DatePicker(
                    "",
                    selection: $endDate,
                    displayedComponents: .date
                )
                .labelsHidden()
                .accentColor(.primaryColor)
            }
            
            // クイック選択ボタン
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    QuickDateButton(title: "今日", action: {
                        onQuickSelect(.today)
                    })
                    
                    QuickDateButton(title: "昨日", action: {
                        onQuickSelect(.yesterday)
                    })
                    
                    QuickDateButton(title: "今週", action: {
                        onQuickSelect(.thisWeek)
                    })
                    
                    QuickDateButton(title: "今月", action: {
                        onQuickSelect(.thisMonth)
                    })
                    
                    QuickDateButton(title: "先月", action: {
                        onQuickSelect(.lastMonth)
                    })
                    
                    QuickDateButton(title: "3ヶ月", action: {
                        onQuickSelect(.threeMonths)
                    })
                    
                    QuickDateButton(title: "全期間", action: {
                        onQuickSelect(.allTime)
                    })
                }
            }
        }
        .padding()
        .background(
            Color.backgroundSecondary
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        )
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
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.primaryColor)
                .cornerRadius(8)
                .shadow(color: Color.primaryColor.opacity(0.3), radius: 2, x: 0, y: 1)
        }
    }
}

// ベット履歴リスト
struct BetHistoryList: View {
    let records: [BetDisplayModel]
    let onDelete: (String) -> Void
    let onEdit: (String) -> Void
    
    var body: some View {
        List {
            ForEach(records) { record in
                BetHistoryCell(record: record)
                    .padding(.vertical, 4)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .background(Color.backgroundSecondary)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            onDelete(record.id)
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                        .accessibilityLabel("記録を削除")
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            onEdit(record.id)
                        } label: {
                            Label("編集", systemImage: "pencil")
                        }
                        .tint(.secondaryColor)
                        .accessibilityLabel("記録を編集")
                    }
            }
        }
        .listStyle(PlainListStyle())
        .background(Color.backgroundPrimary)
    }
}

// BetHistoryCell の修正
struct BetHistoryCell: View {
    let record: BetDisplayModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // ギャンブル種別マーク
                Circle()
                    .fill(record.gambleTypeColor)
                    .frame(width: 14, height: 14)
                    .shadow(color: record.gambleTypeColor.opacity(0.5), radius: 2, x: 0, y: 1)
                
                Text(record.gambleType)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(record.gambleTypeColor)
                
                Spacer()
                
                // 日付
                Text(record.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.eventName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(record.bettingSystem)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 損益表示
                VStack(alignment: .trailing, spacing: 4) {
                    Text(record.isWin ? "勝ち" : "負け")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(
                            record.isWin ?
                                Color.accentSuccess.opacity(0.2) :
                                Color.accentDanger.opacity(0.2)
                        )
                        .foregroundColor(record.isWin ? .accentSuccess : .accentDanger)
                        .cornerRadius(8)
                    
                    Text(record.formattedProfit)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(record.profit >= 0 ? .accentSuccess : .accentDanger)
                }
            }
            
            Divider()
                .background(Color.backgroundTertiary)
            
            HStack {
                Text("賭け金: \(record.formattedBetAmount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("払戻: \(record.formattedReturnAmount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("ROI: \(record.formattedROI)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(record.roi >= 0 ? .accentSuccess : .accentDanger)
                    .padding(.leading, 8)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.backgroundSecondary)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        )
    }
}

// 履歴がない場合の表示
struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondaryColor.opacity(0.7))
                .padding()
                .background(
                    Circle()
                        .fill(Color.secondaryColor.opacity(0.1))
                        .frame(width: 120, height: 120)
                )
            
            Text("記録がありません")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primaryColor)
            
            Text("ベット記録を追加すると、ここに履歴が表示されます")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary)
    }
}
