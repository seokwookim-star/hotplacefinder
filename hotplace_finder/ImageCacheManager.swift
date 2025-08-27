//
//  ImageCacheManager.swift
//  hotplace_finder
//
//  Created by 김석우 on 12/30/24.
//

import SwiftUI
import UIKit
import Foundation

// 🚀 고성능 이미지 캐싱 매니저
class ImageCacheManager: ObservableObject {
    static let shared = ImageCacheManager()
    
    // 🧠 메모리 캐시 (NSCache는 메모리 부족 시 자동 정리)
    private let memoryCache = NSCache<NSString, UIImage>()
    
    // 💾 디스크 캐시 경로
    private let diskCacheURL: URL
    
    // 📊 캐시 설정
    private let maxMemoryCost = 50 * 1024 * 1024 // 50MB
    private let maxDiskCost = 200 * 1024 * 1024  // 200MB
    
    // 🔄 다운로드 세션
    private let session: URLSession
    
    private init() {
        // 🧠 메모리 캐시 설정
        memoryCache.totalCostLimit = maxMemoryCost
        memoryCache.countLimit = 100 // 최대 100개 이미지
        
        // 💾 디스크 캐시 경로 설정
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = cacheDirectory.appendingPathComponent("ImageCache")
        
        // 🔄 URL 세션 설정 (캐싱 활성화)
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(memoryCapacity: 50 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024, diskPath: "ImageCache")
        
        session = URLSession(configuration: config)
        
        // 📁 디스크 캐시 디렉토리 생성
        createDiskCacheDirectory()
        
        // 🧹 메모리 부족 시 캐시 정리
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearMemoryCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    // 📁 디스크 캐시 디렉토리 생성
    private func createDiskCacheDirectory() {
        do {
            try FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        } catch {
            print("❌ 디스크 캐시 디렉토리 생성 실패: \(error)")
        }
    }
    
    // 🖼️ 이미지 로드 (캐시 우선)
    func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        let key = NSString(string: urlString)
        
        // 🧠 1. 메모리 캐시 확인
        if let cachedImage = memoryCache.object(forKey: key) {
            completion(cachedImage)
            return
        }
        
        // 💾 2. 디스크 캐시 확인
        if let diskImage = loadImageFromDisk(for: key) {
            // 메모리 캐시에 저장
            memoryCache.setObject(diskImage, forKey: key, cost: diskImage.jpegData(compressionQuality: 0.8)?.count ?? 0)
            completion(diskImage)
            return
        }
        
        // 🌐 3. 네트워크에서 다운로드
        downloadImage(from: url, key: key, completion: completion)
    }
    
    // 💾 디스크에서 이미지 로드
    private func loadImageFromDisk(for key: NSString) -> UIImage? {
        let fileURL = diskCacheURL.appendingPathComponent(key.hash.description)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    // 🌐 이미지 다운로드 및 캐싱 (최적화된 버전)
    private func downloadImage(from url: URL, key: NSString, completion: @escaping (UIImage?) -> Void) {
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self,
                      let data = data,
                      let image = UIImage(data: data),
                      error == nil else {
                    completion(nil)
                    return
                }
                
                // 🖼️ 이미지 크기 최적화 (메모리 사용량 감소)
                let optimizedImage = self.optimizeImageSize(image)
                
                // 🧠 메모리 캐시에 저장 (최적화된 이미지)
                let cost = optimizedImage.jpegData(compressionQuality: 0.8)?.count ?? 0
                self.memoryCache.setObject(optimizedImage, forKey: key, cost: cost)
                
                // 💾 디스크 캐시에 저장
                self.saveImageToDisk(optimizedImage, for: key)
                
                completion(optimizedImage)
            }
        }
        task.resume()
    }
    
    // 🖼️ 이미지 크기 최적화
    private func optimizeImageSize(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1024 // 최대 1024x1024
        
        // 이미지가 최대 크기보다 작으면 그대로 반환
        if image.size.width <= maxDimension && image.size.height <= maxDimension {
            return image
        }
        
        // 비율 유지하면서 크기 조정
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let optimizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return optimizedImage ?? image
    }
    
    // 💾 디스크에 이미지 저장
    private func saveImageToDisk(_ image: UIImage, for key: NSString) {
        DispatchQueue.global(qos: .utility).async {
            guard let data = image.jpegData(compressionQuality: 0.8) else { return }
            
            let fileURL = self.diskCacheURL.appendingPathComponent(key.hash.description)
            try? data.write(to: fileURL)
            
            // 🧹 디스크 캐시 크기 관리
            self.manageDiskCacheSize()
        }
    }
    
    // 🧹 디스크 캐시 크기 관리
    private func manageDiskCacheSize() {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: [.fileSizeKey])
            
            var totalSize: Int64 = 0
            var fileSizes: [(URL, Int64)] = []
            
            for fileURL in fileURLs {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                if let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                    fileSizes.append((fileURL, Int64(fileSize)))
                }
            }
            
            // 📊 캐시 크기가 제한을 초과하면 오래된 파일부터 삭제
            if totalSize > maxDiskCost {
                let sortedFiles = fileSizes.sorted { $0.1 < $1.1 } // 오래된 파일부터
                
                for (fileURL, fileSize) in sortedFiles {
                    try? FileManager.default.removeItem(at: fileURL)
                    totalSize -= fileSize
                    
                    if totalSize <= maxDiskCost {
                        break
                    }
                }
            }
        } catch {
            print("❌ 디스크 캐시 관리 실패: \(error)")
        }
    }
    
    // 🧹 메모리 캐시 정리
    @objc private func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    // 🧹 모든 캐시 정리
    func clearAllCaches() {
        memoryCache.removeAllObjects()
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            print("❌ 디스크 캐시 정리 실패: \(error)")
        }
    }
    
    // 📊 캐시 통계
    func getCacheStats() -> (memoryCount: Int, diskSize: Int64) {
        let memoryCount = memoryCache.totalCostLimit
        var diskSize: Int64 = 0
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: [.fileSizeKey])
            for fileURL in fileURLs {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                diskSize += Int64(resourceValues.fileSize ?? 0)
            }
        } catch {
            print("❌ 디스크 캐시 통계 확인 실패: \(error)")
        }
        
        return (memoryCount, diskSize)
    }
}

// 🖼️ 최적화된 AsyncImage 래퍼
struct OptimizedAsyncImage: View {
    let url: String
    let placeholder: Image
    let content: (Image) -> AnyView
    
    @StateObject private var imageLoader = ImageLoader()
    
    init(url: String, placeholder: Image = Image(systemName: "photo"), @ViewBuilder content: @escaping (Image) -> some View) {
        self.url = url
        self.placeholder = placeholder
        self.content = { AnyView(content($0)) }
    }
    
    var body: some View {
        Group {
            if let image = imageLoader.image {
                // ✅ 이미지 로딩 완료
                FadeInOutView {
                    content(Image(uiImage: image))
                }
            } else {
                // 🎨 스켈레톤 로딩 (네이버 지도 스타일)
                ImageSkeletonLoading()
            }
        }
        .onAppear {
            imageLoader.loadImage(from: url)
        }
    }
}

// 🖼️ 이미지 로더 (ObservableObject)
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var cancellable: AnyCancellable?
    
    func loadImage(from urlString: String) {
        ImageCacheManager.shared.loadImage(from: urlString) { [weak self] image in
            DispatchQueue.main.async {
                self?.image = image
            }
        }
    }
    
    deinit {
        cancellable?.cancel()
    }
}

// 🔄 Combine import 추가
import Combine
