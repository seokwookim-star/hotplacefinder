//
//  ModernLoadingView.swift
//  hotplace_finder
//
//  Created by 김석우 on 12/30/24.
//

import SwiftUI

// 🎨 세련된 로딩 뷰 (네이버 지도 스타일)
struct ModernLoadingView: View {
    @State private var isAnimating = false
    @State private var progress: CGFloat = 0.0
    
    let loadingText: String
    let showProgress: Bool
    
    init(loadingText: String = "로딩 중...", showProgress: Bool = true) {
        self.loadingText = loadingText
        self.showProgress = showProgress
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 🎯 메인 로딩 애니메이션
            ZStack {
                // 🔄 배경 원형 애니메이션
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                // 🎨 메인 원형 애니메이션
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple, .blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 1.0)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                
                // 🎯 중앙 점 애니메이션
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            
            // 📝 로딩 텍스트
            Text(loadingText)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
                .opacity(isAnimating ? 1.0 : 0.6)
                .animation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            // 📊 프로그레스 바 (선택적)
            if showProgress {
                ProgressBar(progress: progress)
                    .frame(width: 200, height: 4)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.0)) {
                            progress = 1.0
                        }
                    }
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// 📊 세련된 프로그레스 바
struct ProgressBar: View {
    let progress: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 🎨 배경 바
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.2))
                
                // 🎨 진행 바
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
    }
}

// 🖼️ 이미지 스켈레톤 로딩
struct ImageSkeletonLoading: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            // 🖼️ 이미지 스켈레톤
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0.3),
                            Color.gray.opacity(0.1),
                            Color.gray.opacity(0.3)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 200)
                .overlay(
                    // 🎨 스켈레톤 패턴
                    HStack(spacing: 8) {
                        ForEach(0..<3) { _ in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.6))
                                .frame(width: 40, height: 40)
                        }
                    }
                )
                .clipped()
                .overlay(
                    // 🔄 애니메이션 오버레이
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.clear,
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: isAnimating ? 200 : -200)
                        .animation(
                            Animation.linear(duration: 1.5)
                                .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                )
            
            // 📝 텍스트 스켈레톤
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 16)
                    .frame(maxWidth: .infinity)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// 🎯 전체 화면 로딩 오버레이
struct FullScreenLoadingOverlay: View {
    let isLoading: Bool
    let loadingText: String
    
    var body: some View {
        if isLoading {
            ZStack {
                // 🌫️ 배경 블러
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                // 🎨 로딩 뷰
                ModernLoadingView(loadingText: loadingText)
            }
            .transition(.opacity.combined(with: .scale))
            .animation(.easeInOut(duration: 0.3), value: isLoading)
        }
    }
}

// 🔄 페이드 인/아웃 애니메이션
struct FadeInOutView<Content: View>: View {
    let content: Content
    @State private var opacity: Double = 0.0
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5)) {
                    opacity = 1.0
                }
            }
            .onDisappear {
                withAnimation(.easeInOut(duration: 0.3)) {
                    opacity = 0.0
                }
            }
    }
}

// 🎨 프리뷰
struct ModernLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            ModernLoadingView()
            ImageSkeletonLoading()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
