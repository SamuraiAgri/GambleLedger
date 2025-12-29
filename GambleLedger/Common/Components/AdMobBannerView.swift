// GambleLedger/Common/Components/AdMobBannerView.swift
// ⚠️ このファイルはAdMob SDKインストール後に使用する実装版です
// ⚠️ SDKインストール後、AdMobBannerView.swiftをこのファイルの内容で置き換えてください

import SwiftUI
import GoogleMobileAds

/// バナー広告のSwiftUIラッパー
struct AdMobBannerView: UIViewRepresentable {
    let adUnitID: String
    let adSize: GADAdSize
    
    init(adSize: GADAdSize = GADAdSizeBanner) {
        self.adUnitID = AdMobManager.shared.getBannerAdUnitID()
        self.adSize = adSize
    }
    
    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.rootViewController = getRootViewController()
        banner.load(GADRequest())
        banner.delegate = context.coordinator
        return banner
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // 必要に応じて更新
    }
    
    // iOS 15以降対応のrootViewController取得
    private func getRootViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return nil
        }
        return scene.windows.first?.rootViewController
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, GADBannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            print("✅ Banner ad loaded successfully")
        }
        
        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            print("❌ Banner ad failed to load: \(error.localizedDescription)")
        }
    }
}

/// バナー広告のコンテナビュー（影とパディング付き）
struct BannerAdContainer: View {
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.secondary.opacity(0.3))
            
            AdMobBannerView()
                .frame(height: 50)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
        }
    }
}
