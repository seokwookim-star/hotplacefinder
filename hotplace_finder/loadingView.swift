//
//  startAnimation.swift
//  hotplace_finder
//
//  Created by 김석우 on 5/8/25.
//
// New File 1: LoadingView.swift

import SwiftUI

struct loadingView: View {
    var body: some View {
        Color.white.opacity(0.95).ignoresSafeArea()
        VStack(spacing: 60) {
            LottieView(animationName: "loading", loopMode: .loop)
                .frame(width: 150, height: 150)
            Text("실시간 핫플 정보를 불러오는 중...")
                .font(.headline)
                .foregroundColor(.gray)
            Text("Icons by @Icons8")
                .font(.headline)
                .foregroundColor(.gray)
        }
    }
}
