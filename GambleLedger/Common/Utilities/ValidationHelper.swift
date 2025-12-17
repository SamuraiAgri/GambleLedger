// GambleLedger/Common/Utilities/ValidationHelper.swift
import Foundation

struct ValidationHelper {
    // 金額のバリデーション
    static func validateAmount(_ amountString: String, fieldName: String = "金額", maxAmount: Decimal = 100_000_000) -> ValidationResult {
        // 空白チェック
        let trimmed = amountString.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .failure("\(fieldName)を入力してください。")
        }
        
        // カンマを除去して数値に変換
        let cleaned = trimmed.replacingOccurrences(of: ",", with: "")
        
        // 数値形式チェック
        guard let amount = Decimal(string: cleaned) else {
            return .failure("\(fieldName)には有効な数値を入力してください。")
        }
        
        // 範囲チェック
        if amount < 0 {
            return .failure("\(fieldName)は0以上の値を入力してください。")
        }
        
        if amount > maxAmount {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            let maxString = formatter.string(from: NSDecimalNumber(decimal: maxAmount)) ?? String(describing: maxAmount)
            return .failure("\(fieldName)は\(maxString)円以下で入力してください。")
        }
        
        return .success(amount)
    }
    
    // テキストフィールドのバリデーション
    static func validateText(_ text: String, fieldName: String, minLength: Int = 1, maxLength: Int = 100) -> ValidationResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .failure("\(fieldName)を入力してください。")
        }
        
        if trimmed.count < minLength {
            return .failure("\(fieldName)は\(minLength)文字以上で入力してください。")
        }
        
        if trimmed.count > maxLength {
            return .failure("\(fieldName)は\(maxLength)文字以下で入力してください。")
        }
        
        return .success(trimmed)
    }
    
    // 日付のバリデーション
    static func validateDate(_ date: Date, allowFuture: Bool = false) -> ValidationResult {
        if !allowFuture && date > Date() {
            return .failure("未来の日時は選択できません。")
        }
        
        // 過去10年以内かチェック
        if let tenYearsAgo = Calendar.current.date(byAdding: .year, value: -10, to: Date()),
           date < tenYearsAgo {
            return .failure("日時は10年以内で選択してください。")
        }
        
        return .success(date)
    }
    
    // UUID文字列のバリデーション
    static func validateUUID(_ uuidString: String?, fieldName: String = "ID") -> ValidationResult {
        guard let uuidString = uuidString else {
            return .failure("\(fieldName)が選択されていません。")
        }
        
        guard let uuid = UUID(uuidString: uuidString) else {
            return .failure("無効な\(fieldName)です。")
        }
        
        return .success(uuid)
    }
    
    // 選択肢のバリデーション
    static func validateSelection<T>(_ value: T?, fieldName: String) -> ValidationResult {
        guard let value = value else {
            return .failure("\(fieldName)を選択してください。")
        }
        
        return .success(value)
    }
}

// バリデーション結果
enum ValidationResult {
    case success(Any)
    case failure(String)
    
    var isValid: Bool {
        if case .success = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case .failure(let message) = self {
            return message
        }
        return nil
    }
    
    var value: Any? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }
}

// 複数のバリデーション結果を統合
struct ValidationResults {
    private var results: [ValidationResult] = []
    
    mutating func add(_ result: ValidationResult) {
        results.append(result)
    }
    
    var isAllValid: Bool {
        return results.allSatisfy { $0.isValid }
    }
    
    var firstError: String? {
        return results.first { !$0.isValid }?.errorMessage
    }
    
    var allErrors: [String] {
        return results.compactMap { $0.errorMessage }
    }
}
