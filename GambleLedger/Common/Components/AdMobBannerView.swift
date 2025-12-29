// GambleLedger/Common/Components/AdMobBannerView.swift
import SwiftUI
import UIKit

// TODO: AdMob SDKをインストール後、このファイルを置き換えてください
// 現在はスタブ実装（広告は表示されません）

/// バナー広告のSwiftUIラッパー（スタブ版）
struct AdMobBannerView: View {
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .overlay(
                Text("AdMob Banner (Not Loaded)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            )
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
