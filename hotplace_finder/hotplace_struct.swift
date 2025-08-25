//
//  hotplace_struct.swift
//  hotplace_finder
//
//  Created by 김석우 on 4/20/25.
//
import Foundation
struct hotplace_struct: Identifiable {
    var id: String
//    var title: String
    var lat: Double
    var lng: Double
    var imageUrls: [String]
    var timestamps: [Date]
    var category: String
    var takenAtList: [Date] = []      // 촬영 시간 (선택적)
    var descriptions: [String] = []   // 이미지별 설명
    var titles: [String] = []         // 이미지별 제목
    var reportCounts: [Int] = []  // 신고 횟수
}

struct GeocodeResponse: Codable {
    let addresses: [GeocodeAddress]
}

struct GeocodeAddress: Codable {
    let roadAddress: String?
    let jibunAddress: String?
    let x: String // longitude
    let y: String // latitude
}

struct KakaoPlaceResponse: Codable {
    let documents: [KakaoPlace]
}

struct KakaoPlace: Codable, Hashable {
//    let id: String = UUID().uuidString
    let road_address_name: String
    let place_name: String
    let x: String // 경도
    let y: String // 위도
}
