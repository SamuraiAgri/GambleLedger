// GambleLedger/Common/Utilities/AdMobManager.swift
import Foundation
import UIKit

// TODO: AdMob SDKをインストール後、このファイルを置き換えてください
// 現在はスタブ実装（広告は表示されません）

/// Google AdMob広告管理クラス（スタブ版）
@MainActor
class AdMobManager: NSObject, ObservableObject {
    static let shared = AdMobManager()
    
    // 広告ユニットID
    struct AdUnitIDs {
        // バナー広告
        static let banner = "ca-app-pub-8001546494492220/9111383815"
        
        // インタースティシャル広告
        static let interstitial = "ca-app-pub-8001546494492220/3023831073"
        
        // テスト用ID（開発時に使用）
        #if DEBUG
        static let testBanner = "ca-app-pub-3940256099942544/2934735716"
        static let testInterstitial = "ca-app-pub-3940256099942544/4411468910"
        #endif
    }
    
    @Published var isInterstitialReady = false
    
    // 頻度制限用
    private var lastInterstitialShownDate: Date?
    private var recordSaveCount = 0
    private let interstitialFrequency = 5 // 5回に1回表示
    
    private override init() {
        super.init()
    }
    
    /// AdMobの初期化（スタブ）
    func initialize() {
        print("⚠️ AdMob SDK not installed - Using stub implementation")
    }
    
    /// バナー広告IDを取得
    func getBannerAdUnitID() -> String {
        #if DEBUG
        return AdUnitIDs.testBanner
        #else
        return AdUnitIDs.banner
        #endif
    }
    
    /// インタースティシャル広告をロード（スタブ）
    func loadInterstitialAd() {
        // スタブ実装 - 何もしない
    }
    
    /// 記録保存後にインタースティシャル広告を表示（スタブ）
    func showInterstitialOnRecordSave() {
        recordSaveCount += 1
        print("⚠️ Interstitial ad stub - Record save count: \(recordSaveCount)")
    }
    
    /// アプリ起動時にインタースティシャル広告を表示（スタブ）
    func showInterstitialOnAppLaunch() {
        print("⚠️ Interstitial ad stub - App launch")
    }
}
