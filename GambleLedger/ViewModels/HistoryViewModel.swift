// GambleLedger/ViewModels/HistoryViewModel.swift
import Foundation
import Combine
import SwiftUI

class HistoryViewModel: ObservableObject {
    // 表示データ
    @Published var betRecords: [BetDisplayModel] = []
    @Published var filteredRecords: [BetDisplayModel] = []
    
    // BetRecordModelのキャッシュ（編集時に使用）
    private var recordModelsCache: [String: BetRecordModel] = [:]
    
    // フィルタ設定
    @Published var filterStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published var filterEndDate: Date = Date()
    @Published var selectedGambleTypeID: UUID?
    @Published var searchText: String = ""
    
    // 状態管理
    @Published var isLoading: Bool = false
    @Published var isDeleting: Bool = false
    @Published var sortOption: SortOption = .dateDesc
    @Published var gambleTypes: [GambleTypeModel] = []
    @Published var errorMessage: String? = nil
    @Published var showError: Bool = false
    
    private let coreDataManager: CoreDataManager
    private var cancellables = Set<AnyCancellable>()
    
    // ソートオプション
    enum SortOption: String, CaseIterable, Identifiable {
        case dateDesc = "日付（新→古）"
        case dateAsc = "日付（古→新）"
        case amountDesc = "金額（高→低）"
        case amountAsc = "金額（低→高）"
        case profitDesc = "損益（高→低）"
        case profitAsc = "損益（低→高）"
        
        var id: String { self.rawValue }
    }
    
    init(coreDataManager: CoreDataManager = CoreDataManager.shared) {
        self.coreDataManager = coreDataManager
        
        // ギャンブル種別のロード
        loadGambleTypes()
        
        // 履歴データのロード
        loadBetRecords()
        
        // フィルタとソートの変更を監視
        setupObservers()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // バインディングの設定
    private func setupObservers() {
        // 検索テキスト、日付範囲、ギャンブル種別、ソートオプションの変更を監視
        Publishers.CombineLatest4(
            $searchText,
            $sortOption,
            $filterStartDate,
            $filterEndDate
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _, _, _, _ in
            self?.applyFiltersAndSort()
        }
        .store(in: &cancellables)
        
        $selectedGambleTypeID
            .sink { [weak self] _ in
                self?.applyFiltersAndSort()
            }
            .store(in: &cancellables)
    }
    
    // ギャンブル種別のロード
    private func loadGambleTypes() {
        coreDataManager.fetchGambleTypes { [weak self] results in
            guard let self = self else { return }
            
            let types = results.compactMap { GambleTypeModel.fromManagedObject($0) }
            
            DispatchQueue.main.async {
                self.gambleTypes = types
            }
        }
    }
    
    // 履歴データのロード
    func loadBetRecords() {
        isLoading = true
        
        // 終了日は日付の最後（23:59:59）を使用
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: filterEndDate) ?? filterEndDate
        
        coreDataManager.fetchBetRecords(startDate: filterStartDate, endDate: endOfDay, gambleTypeID: selectedGambleTypeID) { [weak self] records in
            guard let self = self else { return }
            
            var displayModels: [BetDisplayModel] = []
            var modelsCache: [String: BetRecordModel] = [:]
            
            for record in records {
                if let gambleTypeID = record.value(forKey: "gambleTypeID") as? UUID {
                    let gambleType = self.gambleTypes.first { $0.id == gambleTypeID }
                    
                    let betRecord = BetRecordModel.fromManagedObject(record)
                    let displayModel = betRecord.toDisplayModel(with: gambleType)
                    
                    displayModels.append(displayModel)
                    modelsCache[betRecord.id.uuidString] = betRecord
                }
            }
            
            DispatchQueue.main.async {
                self.betRecords = displayModels
                self.recordModelsCache = modelsCache
                self.applyFiltersAndSort()
                self.isLoading = false
            }
        }
    }
    
    // フィルタとソートの適用
    private func applyFiltersAndSort() {
        // 検索テキストによるフィルタリング
        var filtered = betRecords
        
        if !searchText.isEmpty {
            filtered = filtered.filter { record in
                record.eventName.localizedCaseInsensitiveContains(searchText) ||
                record.bettingSystem.localizedCaseInsensitiveContains(searchText) ||
                record.gambleType.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // ギャンブル種別によるフィルタリング
        if let typeID = selectedGambleTypeID, let selectedType = gambleTypes.first(where: { $0.id == typeID }) {
            filtered = filtered.filter { record in
                record.gambleType == selectedType.name
            }
        }
        
        // 日付範囲によるフィルタリング
        let endOfFilterDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: filterEndDate) ?? filterEndDate
        
        filtered = filtered.filter { record in
            let recordDate = record.date
            return recordDate >= filterStartDate && recordDate <= endOfFilterDay
        }
        
        // ソート
        switch sortOption {
        case .dateDesc:
            filtered.sort { $0.date > $1.date }
        case .dateAsc:
            filtered.sort { $0.date < $1.date }
        case .amountDesc:
            filtered.sort { $0.betAmount > $1.betAmount }
        case .amountAsc:
            filtered.sort { $0.betAmount < $1.betAmount }
        case .profitDesc:
            filtered.sort { $0.profit > $1.profit }
        case .profitAsc:
            filtered.sort { $0.profit < $1.profit }
        }
        
        DispatchQueue.main.async {
            self.filteredRecords = filtered
        }
    }
    
    // ベット記録の削除
    func deleteBetRecord(id: String) {
        guard let uuid = UUID(uuidString: id) else {
            self.showError(message: "無効なIDです")
            return
        }
        
        isLoading = true
        isDeleting = true
        
        // CoreDataから削除する処理を実装
        coreDataManager.deleteBetRecord(id: uuid) { [weak self] success, errorMsg in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.isDeleting = false
                
                if success {
                    // UIから削除
                    if let index = self.filteredRecords.firstIndex(where: { $0.id == id }) {
                        self.filteredRecords.remove(at: index)
                    }
                    
                    if let index = self.betRecords.firstIndex(where: { $0.id == id }) {
                        self.betRecords.remove(at: index)
                    }
                    
                    // キャッシュからも削除
                    self.recordModelsCache.removeValue(forKey: id)
                    
                    self.provideHapticFeedback(type: .success)
                } else {
                    self.showError(message: errorMsg ?? "削除中にエラーが発生しました")
                }
            }
        }
    }
    
    // BetRecordModelを取得
    func getBetRecordModel(id: String) -> BetRecordModel? {
        // キャッシュから取得（メモも含む完全なデータ）
        return recordModelsCache[id]
    }
    
    // 触覚フィードバック
    private func provideHapticFeedback(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    // 期間フィルタの設定
    func setDateFilter(period: DateFilterPeriod) {
        let calendar = Calendar.current
        let today = Date()
        
        switch period {
        case .today:
            filterStartDate = calendar.startOfDay(for: today)
            filterEndDate = today
        case .yesterday:
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
                filterStartDate = calendar.startOfDay(for: yesterday)
                filterEndDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: yesterday) ?? yesterday
            }
        case .thisWeek:
            if let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) {
                filterStartDate = startOfWeek
                filterEndDate = today
            }
        case .thisMonth:
            filterStartDate = today.startOfMonth()
            filterEndDate = today
        case .lastMonth:
            if let lastMonth = calendar.date(byAdding: .month, value: -1, to: today) {
                filterStartDate = lastMonth.startOfMonth()
                filterEndDate = lastMonth.endOfMonth()
            }
        case .threeMonths:
            if let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: today) {
                filterStartDate = threeMonthsAgo
                filterEndDate = today
            }
        case .allTime:
            if let yearsAgo = calendar.date(byAdding: .year, value: -5, to: today) {
                filterStartDate = yearsAgo
                filterEndDate = today
            }
        }
    }
    
    // エラー表示
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    // 日付フィルタ期間
    enum DateFilterPeriod {
        case today
        case yesterday
        case thisWeek
        case thisMonth
        case lastMonth
        case threeMonths
        case allTime
    }
}
