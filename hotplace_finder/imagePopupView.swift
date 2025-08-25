//
//  startAnimation.swift
//  hotplace_finder
//
//  Created by 김석우 on 5/8/25.
//
// New File 1: LoadingView.swift

import SwiftUI
import CoreLocation
import PhotosUI

struct ImagePopupView: View {
    @Binding var showPopup: Bool
    @Binding var isRegisteringNewImage: Bool
    @Binding var selectedImageUrls: [String]
    @Binding var selectedTimestamps: [Date]
    @Binding var selectedImageIndex: Int
    @Binding var selectedUIImage: UIImage? // 카메라 촬영용 단일 이미지
    @Binding var selectedUIImages: [UIImage] // 앨범 선택용 여러 이미지 배열
    @Binding var showImagePicker: Bool // 카메라 촬영용 피커
    @Binding var showMultiImagePicker: Bool // 앨범 선택용 여러 이미지 피커
    @Binding var imageSourceType: UIImagePickerController.SourceType
    @Binding var takenAt: Date
    @Binding var titleText: String
    @Binding var descriptionText: String
    @Binding var isUploading: Bool
    @Binding var newCategoryText: String
    @Binding var selectedTakenAtList: [Date]
    @Binding var selectedImageTitles: [String]
    @Binding var selectedDescriptions: [String]
    @Binding var fullScreenImageUrl: String
    @Binding var showFullScreenImage: Bool
@Binding var showCategoryNotice: Bool			
    @ObservedObject var viewModel: hotplace_import_firebase
    @State private var showReportPopup = false

    var popupLat: Double?
    var popupLng: Double?
    var userID: String
    var adminUserIDs: [String]
    var dateFormatter: DateFormatter
    var body: some View {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                showPopup = false
                                isRegisteringNewImage = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(.gray)
                            }
                            .padding(.trailing, 10)
                            .padding(.top, 10)
                        } // 닫기 버튼
                        ScrollView {
                            VStack(spacing: 4) {
                                if !isRegisteringNewImage {
                                    if !selectedImageUrls.isEmpty {
                                        // 🚨 신고 버튼
                                        if !selectedImageUrls.isEmpty && selectedImageIndex < selectedImageUrls.count {
                                            Button("🚨이미지 신고") {
                                                showReportPopup = true
                                            }
                                            .foregroundColor(.orange)
                                            .fontWeight(.bold)
                                            .padding(.top, 5)
                                        }
                                        TabView(selection: $selectedImageIndex) {
                                            ForEach(selectedImageUrls.indices, id: \.self) { index in
                                                if let url = URL(string: selectedImageUrls[index]) {
                                                    AsyncImage(url: url) { image in
                                                        image.resizable().scaledToFit()
                                                            .onTapGesture {
                                                                fullScreenImageUrl = selectedImageUrls[index]
                                                                showFullScreenImage = true
                                                            }
                                                    } placeholder: {
                                                        ProgressView()
                                                    }
                                                    .frame(height: 200)
                                                    .cornerRadius(16)
                                                    .tag(index)
                                                }
                                            }
                                        }
                                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                                        .frame(height: 220)
                                        
                                        if selectedTakenAtList.indices.contains(selectedImageIndex) {
                                            Text("촬영일: \(dateFormatter.string(from: selectedTakenAtList[selectedImageIndex]))")
                                                .font(.footnote)
                                                .padding(.top, 6)
                                                .cornerRadius(8)
                                        }

                                        // ✅ 이미지 제목
                                        if selectedImageTitles.indices.contains(selectedImageIndex) {
                                            Text("제목: \(selectedImageTitles[selectedImageIndex])")
                                                .font(.subheadline)
                                                .padding(.top, 2)
                                        }

                                        // ✅ 이미지 설명
                                        if selectedDescriptions.indices.contains(selectedImageIndex) {
                                            Text("설명: \(selectedDescriptions[selectedImageIndex])")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                                .padding(.top, 2)
                                        }
                                        
                                        

                                        // 🚨 신고 팝업 띄우기
                                        
                                        
                                        
//                                        if !selectedImageUrls.isEmpty && selectedImageIndex < selectedImageUrls.count {
//                                            // ✅ 🚨 신고 버튼 추가
//                                            Button("🚨 이미지 신고") {
//                                                let place = viewModel.filteredPlaces.first(where: { $0.imageUrls.contains(selectedImageUrls[selectedImageIndex]) })
//                                                if let placeId = place?.id {
//                                                    viewModel.reportImage(placeId: placeId, imageUrl: selectedImageUrls[selectedImageIndex])
//                                                }
//                                            }
//                                            .foregroundColor(.orange)
//                                            .fontWeight(.bold)
//                                            .padding(.top, 5)
//                                        }
                                        
                                        
                                        
//                                        if selectedTimestamps.indices.contains(selectedImageIndex) {
//                                            Text("업로드: \(dateFormatter.string(from: selectedTimestamps[selectedImageIndex]))")
//                                                .font(.footnote)
//                                                .padding(6)
//                                                .cornerRadius(8)
//                                                .padding(.top, 2)
//                                        }
                                    } else {
                                        Text("📮 업로드된 이미지가 없습니다.")
                                            .foregroundColor(.gray)
                                            .frame(height: 150)
                                    }
//                                    if adminUserIDs.contains(userID) {
                                        if !userID.isEmpty {
                                        Button("📷 이미지 추가 등록") {
                                            isRegisteringNewImage = true
                                        }
//                                        .foregroundColor(.black)
//                                        .padding(.top, 12)
                                        
//                                        .fontWeight(.bold)
                                        .padding(.top, 12)
//                                        .background(Color.black)
//                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                    }
//                                    if adminUserIDs.contains(userID) && !userID.isEmpty && !selectedImageUrls.isEmpty && selectedImageIndex < selectedImageUrls.count {
                                    if adminUserIDs.contains(userID) && !userID.isEmpty && !selectedImageUrls.isEmpty && selectedImageIndex < selectedImageUrls.count {
                                        Button("🗑️ 이미지 삭제") {
                                                let place = viewModel.filteredPlaces.first(where: { $0.imageUrls.contains(selectedImageUrls[selectedImageIndex]) })
                                                let placeId = place?.id ?? ""

                                                viewModel.deleteImageFromFirebase(
                                                    placeId: placeId,
                                                    imageUrl: selectedImageUrls[selectedImageIndex]
                                                ) { success in
                                                    if success {
                                                        selectedImageUrls.remove(at: selectedImageIndex)
                                                        selectedTimestamps.remove(at: selectedImageIndex)
                                                        selectedImageIndex = 0
                                                    }
                                                }
                                            }
                                        .foregroundColor(.red)
//                                        .padding(.top, 2)
//                                        .fontWeight(.bold)
                                        .padding(.top, 5)
//                                        .background(Color.black)
//                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                    }

                                } else {
                                    VStack(spacing: 20) {
                                        // 🔄 [NEW] 선택된 여러 이미지 미리보기
                                        if !selectedUIImages.isEmpty {
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 8) {
                                                    ForEach(selectedUIImages.indices, id: \.self) { index in
                                                        ZStack(alignment: .topTrailing) {
                                                            Image(uiImage: selectedUIImages[index])
                                                                .resizable()
                                                                .scaledToFill()
                                                                .frame(width: 80, height: 80)
                                                                .clipped()
                                                                .cornerRadius(8)
                                                            
                                                            // 삭제 버튼
                                                            Button(action: {
                                                                selectedUIImages.remove(at: index)
                                                            }) {
                                                                Image(systemName: "xmark.circle.fill")
                                                                    .foregroundColor(.red)
                                                                    .background(Color.white)
                                                                    .clipShape(Circle())
                                                            }
                                                            .offset(x: 5, y: -5)
                                                        }
                                                    }
                                                }
                                                .padding(.horizontal)
                                            }
                                            .frame(height: 90)
                                        }
                                        // 🔄 [ORIGINAL] 기존 단일 이미지 미리보기 (주석처리)
                                        // else if let previewImage = selectedUIImage {
                                        //     Image(uiImage: previewImage)
                                        //         .resizable()
                                        //         .scaledToFit()
                                        //         .frame(height: 100)
                                        //         .cornerRadius(12)
                                        // }
                                        else if let previewImage = selectedUIImage {
                                            Image(uiImage: previewImage)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: 100)
                                                .cornerRadius(12)
                                        }
                                        
                                        // 🔄 [ORIGINAL] 기존 버튼 구조 (주석처리)
                                        // HStack(spacing: 20) {
                                        //     Button("📸 카메라 촬영") {
                                        //         imageSourceType = .camera
                                        //         showImagePicker = true
                                        //     }
                                        //     .foregroundColor(.black)
                                        //     
                                        //     Button("📷 앨범에서 선택") {
                                        //         imageSourceType = .photoLibrary
                                        //         showImagePicker = true
                                        //     }
                                        //     .foregroundColor(.black)
                                        // }
                                        
                                        // 🔄 [NEW] 간소화된 버튼 구조
                                        HStack(spacing: 20) {
                                            Button("📸 카메라 촬영") {
                                                imageSourceType = .camera
                                                showImagePicker = true
                                            }
                                            .foregroundColor(.black)
                                            
                                            Button("📷 앨범에서 선택") {
                                                showMultiImagePicker = true
                                            }
                                            .foregroundColor(.black)
                                        }
                                        .sheet(isPresented: $showImagePicker) {
                                            ImagePicker(image: $selectedUIImage, sourceType: imageSourceType)
                                        }.id(imageSourceType)
                                        .sheet(isPresented: $showMultiImagePicker) {
                                            if #available(iOS 14.0, *) {
                                                MultiImagePicker(selectedImages: $selectedUIImages, maxSelection: 10)
                                            } else {
                                                LegacyImagePicker(selectedImages: $selectedUIImages, sourceType: .photoLibrary)
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack{
                                                Text("카테고리 선택")
                                                    .font(.headline)
                                                
                                                Picker("카테고리", selection: $viewModel.selectedCategory) {
                                                    ForEach(viewModel.categoryOptions, id: \.self) { category in
                                                        Text(category).tag(category)
                                                    }
                                                    Text("➕ 새 카테고리").tag("새 카테고리")
                                                }
                                                .pickerStyle(MenuPickerStyle())
                                            }
                                            if viewModel.selectedCategory == "새 카테고리" {
                                                TextField("새 카테고리 입력", text: $newCategoryText)
                                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                            }
                                            
                                        
                                            datePickerSection(takenAt: $takenAt)
                       
                                            Text("명소 이름")
                                                .font(.headline)
                                            TextField("명소 이름 입력", text: $titleText)
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                                .padding(.horizontal)
                                            
                                            Text("명소 소개")
                                                .font(.headline)
                                            TextField("간략하게 명소를 소개", text: $descriptionText)
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                                .padding(.horizontal)
                                        }
                                        if isUploading {
                                            ProgressView("업로드 중입니다...")
                                                .padding()
                                        } else {
                                            Button(action: {
                                                if viewModel.selectedCategory == "전체" {
                                                    withAnimation {
                                                        showCategoryNotice = true
                                                    }
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                        withAnimation {
                                                            showCategoryNotice = false
                                                        }
                                                    }
                                                    return
                                                }
                                                
                                                isUploading = true  // 🔄 업로드 시작
                                                var coordinate: CLLocationCoordinate2D?
                                                
                                                if let marker = viewModel.searchResultMarker {
                                                    coordinate = CLLocationCoordinate2D(latitude: marker.lat, longitude: marker.lng)
                                                } else if let popupLat = popupLat, let popupLng = popupLng {
                                                    coordinate = CLLocationCoordinate2D(latitude: popupLat, longitude: popupLng)
                                                }
                                                
                                                if let finalCoordinate = coordinate {
                                                    // 🔄 [ORIGINAL] 기존 단일 이미지 업로드 로직 (주석처리)
                                                    // viewModel.uploadImageToFirebase(
                                                    //     image: selectedUIImage ?? UIImage(),
                                                    //     location: finalCoordinate,
                                                    //     customCategory: newCategoryText.isEmpty ? nil : newCategoryText,
                                                    //     takenAt: takenAt,
                                                    //     imageTitle: titleText,
                                                    //     description: descriptionText,
                                                    //     userID: userID
                                                    // ) { success in
                                                    //     DispatchQueue.main.async {
                                                    //         isUploading = false  // ✅ 완료 후 해제
                                                    //         if success {
                                                    //             showPopup = false
                                                    //             isRegisteringNewImage = false
                                                    //         }
                                                    //     }
                                                    // }
                                                    
                                                    // 🔄 [NEW] 통합된 업로드 로직 - 앨범 선택은 항상 여러장, 카메라는 단일
                                                    if !selectedUIImages.isEmpty {
                                                        // 앨범에서 선택된 여러 이미지 업로드
                                                        viewModel.uploadMultipleImagesToFirebase(
                                                            images: selectedUIImages,
                                                            location: finalCoordinate,
                                                            customCategory: newCategoryText.isEmpty ? nil : newCategoryText,
                                                            takenAt: takenAt,
                                                            imageTitle: titleText,
                                                            description: descriptionText,
                                                            userID: userID
                                                        ) { success in
                                                            DispatchQueue.main.async {
                                                                isUploading = false
                                                                if success {
                                                                    selectedUIImages.removeAll() // ✅ 업로드 후 배열 비우기
                                                                    showPopup = false
                                                                    isRegisteringNewImage = false
                                                                }
                                                            }
                                                        }
                                                    } else if let singleImage = selectedUIImage {
                                                        // 카메라로 촬영된 단일 이미지 업로드
                                                        viewModel.uploadImageToFirebase(
                                                            image: singleImage,
                                                            location: finalCoordinate,
                                                            customCategory: newCategoryText.isEmpty ? nil : newCategoryText,
                                                            takenAt: takenAt,
                                                            imageTitle: titleText,
                                                            description: descriptionText,
                                                            userID: userID
                                                        ) { success in
                                                            DispatchQueue.main.async {
                                                                isUploading = false
                                                                if success {
                                                                    selectedUIImage = nil // ✅ 업로드 후 단일 이미지 제거
                                                                    showPopup = false
                                                                    isRegisteringNewImage = false
                                                                }
                                                            }
                                                        }
                                                    } else {
                                                        isUploading = false // 이미지가 없을 때
                                                    }
                                                } else {
                                                    isUploading = false  // 좌표 없을 때도 해제
                                                }
                                            }) {
                                                // 🔄 [ORIGINAL] 기존 고정된 텍스트 (주석처리)
                                                // Text("🗺️ 사진 업로드")
                                                
                                                // 🔄 [NEW] 여러 이미지 개수에 따른 동적 텍스트
                                                Text(!selectedUIImages.isEmpty ? "🗺️ 사진 \(selectedUIImages.count)장 업로드" : "🗺️ 사진 업로드")
                                                    .fontWeight(.bold)
                                                    .padding(3)
                                                    .background(Color.black)
                                                    .foregroundColor(.white)
                                                    .cornerRadius(10)
                                            }
                                            if showCategoryNotice {
                                                Text("⚠️ ‘명소 선택’ 상태에서는 사진을 등록할 수 없습니다.")
                                                    .padding()
                                                    .background(Color.yellow.opacity(0.9))
                                                    .foregroundColor(.black)
                                                    .cornerRadius(12)
                                                    .padding(.bottom, 100)
                                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                                    .animation(.easeInOut, value: showCategoryNotice)
                                            }
                                        }
                                    }
//                                    .padding()
                                }
                            }

                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .frame(maxWidth: 280)
                        .frame(maxHeight: 400)

                    }
//        if showReportPopup {
//            Color.black.opacity(0.4)
//                .edgesIgnoringSafeArea(.all)
//            
//            ReportPopupView(
//                placeId: selectedImageTitles[selectedImageIndex],
//                imageUrl: selectedImageUrls[selectedImageIndex],
//                isPresented: $showReportPopup
//            )
//            .frame(maxWidth: 300)
//            .cornerRadius(16)
//            .shadow(radius: 10)
//        }
        
        if showReportPopup {
            if selectedImageUrls.indices.contains(selectedImageIndex),
               selectedImageTitles.indices.contains(selectedImageIndex) {
                
                let place = viewModel.filteredPlaces.first(where: {
                    $0.imageUrls.contains(selectedImageUrls[selectedImageIndex])
                })
                
                if let placeId = place?.id {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    
                    ReportPopupView(
                        placeId: placeId,
                        imageUrl: selectedImageUrls[selectedImageIndex],
                        isPresented: $showReportPopup
                    )
                    .frame(maxWidth: 300)
                    .cornerRadius(16)
                    .shadow(radius: 10)
                }
            }
        }
    }
}
