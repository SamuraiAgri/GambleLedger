// GambleLedger/Common/Components/AdMobBannerView.swift
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
        banner.rootViewController = UIApplication.shared.windows.first?.rootViewController
        banner.load(GADRequest())
        banner.delegate = context.coordinator
        return banner
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // 必要に応じて更新
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
                .background(Color.backgroundSecondary)
        }
    }
}
