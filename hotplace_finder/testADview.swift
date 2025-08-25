//
//  mainTabView.swift
//  hotplace_finder
//
//  Created by 김석우 on 5/27/25.
//

import SwiftUI
import GoogleMobileAds

struct TestAdView: View {
    var body: some View {
        VStack {
            Text("🔍 광고 테스트 화면")
                .font(.title)
                .padding()

            Spacer()

            BannerAdView(adUnitID: "ca-app-pub-1784560805883962/9475697003") // 여기에 실제 광고 ID 입력
                .frame(width: 320, height: 50)

            Spacer()
        }
        .onAppear {
            print("✅ TestAdView appeared")
        }
    }
}
