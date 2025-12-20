// GambleLedger/Common/Utilities/DataExporter.swift
import Foundation
import SwiftUI
import UIKit

class DataExporter {
    static let shared = DataExporter()
    
    private init() {}
    
    // MARK: - CSV Export
    
    func exportToCSV(records: [BetDisplayModel]) -> URL? {
        var csvString = "日時,ギャンブル種別,イベント名,賭式,賭け金,払戻金,損益,回収率,勝敗\n"
        
        for record in records {
            let dateString = formatDate(record.date)
            let gambleType = escapeCSVField(record.gambleType)
            let eventName = escapeCSVField(record.eventName)
            let bettingSystem = escapeCSVField(record.bettingSystem)
            let betAmount = String(format: "%.0f", record.betAmount)
            let returnAmount = String(format: "%.0f", record.returnAmount)
            let profit = String(format: "%.0f", record.profit)
            let roi = String(format: "%.2f", record.roi)
            let result = record.isWin ? "勝ち" : "負け"
            
            let row = "\(dateString),\(gambleType),\(eventName),\(bettingSystem),\(betAmount),\(returnAmount),\(profit),\(roi),\(result)\n"
            csvString.append(row)
        }
        
        return saveToTemporaryFile(content: csvString, fileName: "bet_records_\(currentDateString()).csv")
    }
    
    // MARK: - JSON Export
    
    func exportToJSON(records: [BetDisplayModel]) -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let exportData = records.map { record -> [String: Any] in
            return [
                "id": record.id,
                "date": ISO8601DateFormatter().string(from: record.date),
                "gambleType": record.gambleType,
                "eventName": record.eventName,
                "bettingSystem": record.bettingSystem,
                "betAmount": record.betAmount,
                "returnAmount": record.returnAmount,
                "profit": record.profit,
                "roi": record.roi,
                "isWin": record.isWin
            ]
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return saveToTemporaryFile(content: jsonString, fileName: "bet_records_\(currentDateString()).json")
            }
        } catch {
            print("JSON export error: \(error)")
        }
        
        return nil
    }
    
    // MARK: - Helper Methods
    
    private func escapeCSVField(_ field: String) -> String {
        // フィールドにカンマ、改行、ダブルクォートが含まれる場合はエスケープ
        if field.contains(",") || field.contains("\n") || field.contains("\"") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
    
    private func saveToTemporaryFile(content: String, fileName: String) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to save file: \(error)")
            return nil
        }
    }
    
    // MARK: - Share Function
    
    func shareFile(url: URL, from viewController: UIViewController) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // iPadの場合のポップオーバー設定
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = CGRect(x: viewController.view.bounds.midX,
                                                   y: viewController.view.bounds.midY,
                                                   width: 0,
                                                   height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        viewController.present(activityVC, animated: true)
    }
}

// SwiftUIでシェア機能を使うためのヘルパー
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// ViewModifierでエクスポート機能を追加
struct ExportModifier: ViewModifier {
    @Binding var isPresented: Bool
    let records: [BetDisplayModel]
    let exportFormat: ExportFormat
    
    @State private var fileURL: URL?
    @State private var showShareSheet = false
    
    enum ExportFormat {
        case csv
        case json
    }
    
    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    exportData()
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = fileURL {
                    ActivityViewController(activityItems: [url], applicationActivities: nil)
                }
            }
    }
    
    private func exportData() {
        let url: URL?
        
        switch exportFormat {
        case .csv:
            url = DataExporter.shared.exportToCSV(records: records)
        case .json:
            url = DataExporter.shared.exportToJSON(records: records)
        }
        
        if let url = url {
            fileURL = url
            showShareSheet = true
        }
        
        isPresented = false
    }
}

extension View {
    func exportData(isPresented: Binding<Bool>, records: [BetDisplayModel], format: ExportModifier.ExportFormat) -> some View {
        self.modifier(ExportModifier(isPresented: isPresented, records: records, exportFormat: format))
    }
}
