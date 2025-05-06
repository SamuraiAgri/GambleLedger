// GambleLedger/Common/Utilities/ErrorHandler.swift
import Foundation
import SwiftUI

enum AppError: Error, Identifiable {
    case coreDataError(String)
    case networkError(String)
    case validationError(String)
    case generalError(String)
    
    var id: String {
        switch self {
        case .coreDataError(let message): return "coreData_\(message)"
        case .networkError(let message): return "network_\(message)"
        case .validationError(let message): return "validation_\(message)"
        case .generalError(let message): return "general_\(message)"
        }
    }
    
    var message: String {
        switch self {
        case .coreDataError(let message): return "データエラー: \(message)"
        case .networkError(let message): return "ネットワークエラー: \(message)"
        case .validationError(let message): return "入力エラー: \(message)"
        case .generalError(let message): return message
        }
    }
    
    var title: String {
        switch self {
        case .coreDataError: return "データエラー"
        case .networkError: return "ネットワークエラー"
        case .validationError: return "入力エラー"
        case .generalError: return "エラー"
        }
    }
    
    static func fromError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        // CoreDataエラーの場合
        if let nsError = error as NSError?, nsError.domain == NSCocoaErrorDomain {
            return .coreDataError(nsError.localizedDescription)
        }
        
        // その他のエラー
        return .generalError(error.localizedDescription)
    }
}

class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: AppError?
    @Published var showingError = false
    
    func handle(_ error: AppError) {
        DispatchQueue.main.async {
            self.currentError = error
            self.showingError = true
        }
    }
    
    func handleError(_ error: Error) {
        handle(AppError.fromError(error))
    }
    
    func handleCoreDataError(_ error: Error, customMessage: String? = nil) {
        let message = customMessage ?? error.localizedDescription
        handle(.coreDataError(message))
    }
    
    func handleValidationError(_ message: String) {
        handle(.validationError(message))
    }
    
    func dismiss() {
        DispatchQueue.main.async {
            self.showingError = false
            self.currentError = nil
        }
    }
}

// アプリに統合するための拡張
extension View {
    func withErrorHandling() -> some View {
        self.environmentObject(ErrorHandler.shared)
            .alert(isPresented: .constant(ErrorHandler.shared.showingError),
                  content: {
                Alert(
                    title: Text(ErrorHandler.shared.currentError?.title ?? "エラー"),
                    message: Text(ErrorHandler.shared.currentError?.message ?? "不明なエラーが発生しました"),
                    dismissButton: .default(Text("OK")) {
                        ErrorHandler.shared.dismiss()
                    }
                )
            })
    }
}
