//
//  ImagePreloader.swift
//  hotplace_finder
//
//  Created by 김석우 on 12/30/24.
//

import SwiftUI
import UIKit
import Combine

// 🚀 이미지 프리로더 (성능 최적화)
class ImagePreloader: ObservableObject {
    static let shared = ImagePreloader()
    
    // 🔄 프리로드 큐
    private var preloadQueue: [String] = []
    private var isLoading = false
    
    // 📱 화면에 보이는 이미지들
    private var visibleImages: Set<String> = []
    
    // 🎯 프리로드 설정
    private let maxPreloadCount = 10
    private let preloadDistance = 2 // 현재 화면 기준 앞뒤 2개씩
    
    private init() {}
    
    // 🔄 이미지 프리로드 시작 (최적화된 버전)
    func preloadImages(_ urls: [String], currentIndex: Int) {
        // 🧹 기존 큐 정리
        preloadQueue.removeAll()
        
        // 🎯 프리로드할 이미지 선택 (현재 위치 기준 앞뒤)
        let startIndex = max(0, currentIndex - preloadDistance)
        let endIndex = min(urls.count - 1, currentIndex + preloadDistance)
        
        // 🚀 우선순위 기반 프리로드
        var priorityUrls: [String] = []
        var normalUrls: [String] = []
        
        for i in startIndex...endIndex {
            if i != currentIndex && !visibleImages.contains(urls[i]) {
                let url = urls[i]
                
                // 🎯 우선순위: 가까운 이미지부터
                let distance = abs(i - currentIndex)
                if distance <= 1 {
                    priorityUrls.append(url)
                } else {
                    normalUrls.append(url)
                }
            }
        }
        
        // 🔄 우선순위 순서로 큐에 추가
        preloadQueue = priorityUrls + normalUrls
        
        print("🚀 프리로드 시작 - 우선순위: \(priorityUrls.count)개, 일반: \(normalUrls.count)개")
        
        // 🚀 프리로드 시작
        startPreloading()
    }
    
    // 🚀 프리로드 실행
    private func startPreloading() {
        guard !isLoading && !preloadQueue.isEmpty else { return }
        
        isLoading = true
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.processPreloadQueue()
        }
    }
    
    // 🔄 프리로드 큐 처리
    private func processPreloadQueue() {
        while !preloadQueue.isEmpty {
            let url = preloadQueue.removeFirst()
            
            // 🖼️ 이미지 프리로드 (캐시에만 저장)
            ImageCacheManager.shared.loadImage(from: url) { _ in
                // 프리로드는 백그라운드에서 조용히 실행
            }
            
            // ⏱️ 너무 빠르게 로드하지 않도록 딜레이
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
        }
    }
    
    // 👁️ 이미지가 화면에 보임
    func imageDidBecomeVisible(_ url: String) {
        visibleImages.insert(url)
        
        // 🚀 주변 이미지 프리로드
        if let currentIndex = getCurrentVisibleIndex(for: url) {
            let allUrls = Array(visibleImages)
            preloadImages(allUrls, currentIndex: currentIndex)
        }
    }
    
    // 🙈 이미지가 화면에서 사라짐
    func imageDidBecomeInvisible(_ url: String) {
        visibleImages.remove(url)
    }
    
    // 🎯 현재 보이는 이미지 인덱스 찾기
    private func getCurrentVisibleIndex(for url: String) -> Int? {
        return Array(visibleImages).firstIndex(of: url)
    }
    
    // 🧹 프리로드 큐 정리
    func clearPreloadQueue() {
        preloadQueue.removeAll()
        isLoading = false
    }
    
    // 📊 프리로드 상태 확인
    func getPreloadStatus() -> (queueCount: Int, isLoading: Bool, visibleCount: Int) {
        return (preloadQueue.count, isLoading, visibleImages.count)
    }
}

// 🖼️ 지연 로딩 이미지 뷰
struct LazyLoadingImage: View {
    let url: String
    let placeholder: Image
    let content: (Image) -> AnyView
    
    @StateObject private var imageLoader = ImageLoader()
    @StateObject private var preloader = ImagePreloader.shared
    
    init(url: String, placeholder: Image = Image(systemName: "photo"), @ViewBuilder content: @escaping (Image) -> some View) {
        self.url = url
        self.placeholder = placeholder
        self.content = { AnyView(content($0)) }
    }
    
    var body: some View {
        Group {
            if let image = imageLoader.image {
                content(Image(uiImage: image)) // UIImage → Image 변환
            } else {
                placeholder
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            // 👁️ 화면에 보일 때만 로드
            imageLoader.loadImage(from: url)
            preloader.imageDidBecomeVisible(url)
        }
        .onDisappear {
            // 🙈 화면에서 사라질 때
            preloader.imageDidBecomeInvisible(url)
        }
    }
}

// 🖼️ 썸네일 + 고화질 이미지 래더
struct ProgressiveImage: View {
    let url: String
    let thumbnailUrl: String?
    let placeholder: Image
    let content: (Image) -> AnyView
    
    @State private var currentImage: UIImage?
    @State private var isLoadingHighQuality = false
    
    init(url: String, thumbnailUrl: String? = nil, placeholder: Image = Image(systemName: "photo"), @ViewBuilder content: @escaping (Image) -> some View) {
        self.url = url
        self.thumbnailUrl = thumbnailUrl
        self.placeholder = placeholder
        self.content = { AnyView(content($0)) }
    }
    
    var body: some View {
        Group {
            if let image = currentImage {
                content(Image(uiImage: image))
                    .overlay(
                        // 🔄 고화질 로딩 중 표시
                        Group {
                            if isLoadingHighQuality {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(8),
                        alignment: .topTrailing
                    )
            } else {
                placeholder
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            loadProgressiveImage()
        }
    }
    
    // 🔄 프로그레시브 이미지 로딩
    private func loadProgressiveImage() {
        // 🖼️ 1. 썸네일 먼저 로드 (빠른 로딩)
        if let thumbnailUrl = thumbnailUrl {
            ImageCacheManager.shared.loadImage(from: thumbnailUrl) { thumbnailImage in
                DispatchQueue.main.async {
                    if let thumbnail = thumbnailImage {
                        self.currentImage = thumbnail
                    }
                    
                    // 🖼️ 2. 고화질 이미지 로드
                    self.loadHighQualityImage()
                }
            }
        } else {
            // 썸네일이 없으면 바로 고화질 로드
            loadHighQualityImage()
        }
    }
    
    // 🖼️ 고화질 이미지 로드
    private func loadHighQualityImage() {
        isLoadingHighQuality = true
        
        ImageCacheManager.shared.loadImage(from: url) { highQualityImage in
            DispatchQueue.main.async {
                self.isLoadingHighQuality = false
                
                if let highQuality = highQualityImage {
                    self.currentImage = highQuality
                }
            }
        }
    }
}

// 🎯 이미지 로딩 최적화 설정
struct ImageLoadingConfig {
    // 🚀 프리로딩 설정
    static let enablePreloading = true
    static let preloadDistance = 2
    
    // 🖼️ 썸네일 설정
    static let enableThumbnails = true
    static let thumbnailSize = CGSize(width: 200, height: 200)
    
    // 💾 캐시 설정
    static let memoryCacheSize = 50 * 1024 * 1024 // 50MB
    static let diskCacheSize = 200 * 1024 * 1024  // 200MB
    
    // ⏱️ 로딩 타임아웃
    static let loadingTimeout: TimeInterval = 30.0
}
