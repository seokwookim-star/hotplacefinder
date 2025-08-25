//
//  ContentView.swift
//  hotplace_finder
//
//  Created by 김석우 on 4/17/25.
//


import SwiftUI
import NMapsMap

struct ContentView: View {
    @State private var selectedImageUrls: [String] = []
    @State private var selectedTimestamps: [Date] = []
    @State private var selectedImageIndex: Int = 0
    @State private var showPopup = false
    @StateObject var viewModel = hotplace_import_firebase()
    @State private var searchQuery = ""
    @State private var regionQuery = ""
    @State private var selectedUIImage: UIImage? = nil // 카메라 촬영용 단일 이미지
    @State private var selectedUIImages: [UIImage] = [] // 앨범 선택용 여러 이미지 배열
    @State private var showImagePicker = false // 카메라 촬영용 피커
    @State private var showMultiImagePicker = false // 앨범 선택용 여러 이미지 피커
    @State private var newCategoryText = ""
    @State private var isRegisteringNewImage = false
    @State private var popupLat: Double? = nil
    @State private var popupLng: Double? = nil
    @State private var isLoading = true
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isUploading: Bool = false // 🔄 업로드 중 상태
    @State private var showFullScreenImage = false
    @State private var fullScreenImageUrl: String = ""
    @AppStorage("userID") private var userID: String = ""
    private let adminUserIDs = ["zd6UgeCsZlWsCrmwL1NUIYR9b4F3","naver_abc123456","kakao_4279811343","kakao_4290953619","000139.0c41053e403f4f108f2216af73e01d3b.1130",
    "000824.a9474df8dd5c4d65a6e6817d5ba7fdea.0048", "001933.3decf7313602466a9f98e2da6461cd-f0.0625" ] // 관리자 ID 리스트
    @State private var showCategoryNotice = false
    @State private var takenAt: Date = Date()
    @State private var titleText: String = ""
    @State private var descriptionText: String = ""
    @State private var selectedTakenAtList: [Date] = []
    @State private var selectedImageTitles: [String] = []
    @State private var selectedDescriptions: [String] = []


    var body: some View {
        ZStack {
            if isLoading {
                loadingView()
            } else {
                NaverMapView(
                    places: viewModel.filteredPlaces,
                    cameraTarget: $viewModel.cameraTarget,
                    showImagePopup: $showPopup,
                    userLocationMarker: $viewModel.userLocationMarker,  // ✅ 수정된 부분
                    searchResultMarker: $viewModel.searchResultMarker,  // ✅ 수정된 부분
                    popupLat: $popupLat,
                    popupLng: $popupLng,
                    selectedImageUrls: $selectedImageUrls,
                    selectedTimestamps: $selectedTimestamps,
                    selectedImageIndex: $selectedImageIndex,
                    shouldMoveToUserLocation: $viewModel.shouldMoveToUserLocation,
                    shouldMoveToSearchLocation: $viewModel.shouldMoveToSearchLocation,
                    selectedTakenAtList: $selectedTakenAtList,
                    selectedImageTitles: $selectedImageTitles,
                    selectedDescriptions: $selectedDescriptions
                )
                .ignoresSafeArea()
                searchBarView(searchQuery: $searchQuery, viewModel: viewModel)
                VStack{
                    Spacer()
                    HStack{
                        Spacer()
                        Button(action: {
                            viewModel.shouldMoveToUserLocation = true
                            if let coord = viewModel.userLocation {
                                viewModel.cameraTarget = nil
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                    viewModel.cameraTarget = NMGLatLng(lat: coord.latitude, lng: coord.longitude)
                                }
                            }
                            print("📍현재 위치: \(String(describing: viewModel.userLocation))")
                        }) {
                            Image(systemName: "location.circle.fill")
                                .resizable()
                                .frame(width: 38, height: 38)
                                .foregroundColor(.black)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 90)
                    }
                }
                if showPopup {
                    ImagePopupView(
                        showPopup: $showPopup,
                        isRegisteringNewImage: $isRegisteringNewImage,
                        selectedImageUrls: $selectedImageUrls,
                        selectedTimestamps: $selectedTimestamps,
                        selectedImageIndex: $selectedImageIndex,
                        selectedUIImage: $selectedUIImage,
                        selectedUIImages: $selectedUIImages, // 🔄 여러 이미지 배열 전달
                        showImagePicker: $showImagePicker,
                        showMultiImagePicker: $showMultiImagePicker, // 🔄 여러 이미지 피커 상태 전달
                        imageSourceType: $imageSourceType,
                        takenAt: $takenAt,
                        titleText: $titleText,
                        descriptionText: $descriptionText,
                        isUploading: $isUploading,
                        newCategoryText: $newCategoryText,
                        selectedTakenAtList: $selectedTakenAtList,
                        selectedImageTitles: $selectedImageTitles,
                        selectedDescriptions: $selectedDescriptions,
                        fullScreenImageUrl: $fullScreenImageUrl,
                        showFullScreenImage: $showFullScreenImage,
                        showCategoryNotice: $showCategoryNotice,
                        viewModel: viewModel,
                        popupLat: popupLat,
                        popupLng: popupLng,
                        userID: userID,
                        adminUserIDs: adminUserIDs,
                        dateFormatter: dateFormatter
                    )
                }
            }
        }
        .onAppear {
            viewModel.fetchPlaces()
            viewModel.requestUserLocation()

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isLoading = false
                if !viewModel.didInitialMapMove,
                   let coord = viewModel.userLocation {
                    viewModel.cameraTarget = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        viewModel.cameraTarget = NMGLatLng(lat: coord.latitude, lng: coord.longitude)
                        viewModel.shouldMoveToUserLocation = true
                        viewModel.didInitialMapMove = true   // ✅ 한 번만 실행되도록 플래그 설정
                    }
                }
            }
        }
        .onChange(of: showPopup, initial: false) { oldValue, newValue in
            if newValue {
                selectedImageIndex = 0
            }
        }
        .fullScreenCover(isPresented: $showFullScreenImage) {
                FullScreenImageView(imageUrl: fullScreenImageUrl, isPresented: $showFullScreenImage)
            }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}
