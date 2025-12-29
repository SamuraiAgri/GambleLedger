// GambleLedger/Common/Utilities/AdMobManager.swift
// ⚠️ このファイルはAdMob SDKインストール後に使用する実装版です
// ⚠️ SDKインストール後、AdMobManager.swiftをこのファイルの内容で置き換えてください

import Foundation
import GoogleMobileAds
import UIKit

/// Google AdMob広告管理クラス
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
    
    // インタースティシャル広告の表示管理
    @Published var interstitialAd: GADInterstitialAd?
    @Published var isInterstitialReady = false
    
    // 頻度制限用
    private var lastInterstitialShownDate: Date?
    private var recordSaveCount = 0
    private let interstitialFrequency = 5 // 5回に1回表示
    
    private override init() {
        super.init()
    }
    
    /// AdMobの初期化
    func initialize() {
        GADMobileAds.sharedInstance().start { status in
            print("✅ AdMob initialized")
        }
        
        // インタースティシャル広告をプリロード
        loadInterstitialAd()
    }
    
    /// バナー広告IDを取得
    func getBannerAdUnitID() -> String {
        #if DEBUG
        return AdUnitIDs.testBanner
        #else
        return AdUnitIDs.banner
        #endif
    }
    
    /// インタースティシャル広告をロード
    func loadInterstitialAd() {
        let adUnitID: String
        #if DEBUG
        adUnitID = AdUnitIDs.testInterstitial
        #else
        adUnitID = AdUnitIDs.interstitial
        #endif
        
        let request = GADRequest()
        
        GADInterstitialAd.load(withAdUnitID: adUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Failed to load interstitial ad: \(error.localizedDescription)")
                self.isInterstitialReady = false
                return
            }
            
            self.interstitialAd = ad
            self.isInterstitialReady = true
            self.interstitialAd?.fullScreenContentDelegate = self
            print("✅ Interstitial ad loaded")
        }
    }
    
    /// 記録保存後にインタースティシャル広告を表示（頻度制限付き）
    func showInterstitialOnRecordSave() {
        recordSaveCount += 1
        
        // 5回に1回だけ表示
        if recordSaveCount % interstitialFrequency == 0 {
            showInterstitialAd()
        }
    }
    
    /// アプリ起動時にインタースティシャル広告を表示（1日1回）
    func showInterstitialOnAppLaunch() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastShown = lastInterstitialShownDate,
           calendar.isDate(lastShown, inSameDayAs: today) {
            // 今日既に表示済み
            return
        }
        
        // 広告表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.showInterstitialAd()
            self?.lastInterstitialShownDate = Date()
        }
    }
    
    /// インタースティシャル広告を表示
    private func showInterstitialAd() {
        guard let interstitialAd = interstitialAd,
              let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            print("⚠️ Interstitial ad not ready or no root view controller")
            loadInterstitialAd() // 次回のためにリロード
            return
        }
        
        interstitialAd.present(fromRootViewController: rootViewController)
    }
}

// MARK: - GADFullScreenContentDelegate
extension AdMobManager: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("✅ Interstitial ad dismissed")
        // 次の広告をプリロード
        loadInterstitialAd()
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ Interstitial ad failed to present: \(error.localizedDescription)")
        // 次の広告をプリロード
        loadInterstitialAd()
    }
    
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("📢 Interstitial ad will present")
    }
}
