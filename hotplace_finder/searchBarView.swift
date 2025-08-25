//
//  startAnimation.swift
//  hotplace_finder
//
//  Created by 김석우 on 5/8/25.
//
// New File 1: LoadingView.swift

import SwiftUI
import NMapsMap

struct searchBarView: View {
    @Binding var searchQuery: String
    @ObservedObject var viewModel: hotplace_import_firebase

    var body: some View {
        VStack {
            HStack {
                TextField("주소 검색", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 200)
                    .onSubmit {
                        viewModel.searchPlaceWithFallback(searchQuery)
                        viewModel.shouldMoveToSearchLocation = true
                    }

                Button("검색") {
                    viewModel.searchPlaceWithFallback(searchQuery)
                    viewModel.shouldMoveToSearchLocation = true
                }
                .foregroundColor(.black)
                .sheet(isPresented: $viewModel.showKakaoSearchList) {
                    VStack {
                        Text("검색 결과").font(.headline).padding(.top)
                        List(viewModel.kakaoSearchResults, id: \.self) { place in
                            Button(action: {
                                if let lat = Double(place.y), let lng = Double(place.x) {
                                    viewModel.cameraTarget = nil
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                        viewModel.cameraTarget = NMGLatLng(lat: lat, lng: lng)
                                        viewModel.searchResultMarker = NMGLatLng(lat: lat, lng: lng)
                                        viewModel.shouldMoveToSearchLocation = true
                                        viewModel.showKakaoSearchList = false
                                    }
                                }
                            }) {
                                VStack(alignment: .leading) {
                                    Text(place.place_name).bold()
                                    Text(place.road_address_name).font(.caption).foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .padding()
                }

                Menu {
                    ForEach(viewModel.categoryOptions, id: \.self) { category in
                        Button(action: {
                            viewModel.selectedCategory = category
                        }) {
                            Text(category)
                                .foregroundColor(.black)
                        }
                    }
                } label: {
                    Text(viewModel.selectedCategory)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                        .foregroundColor(.black)
                }
            }
            .padding(4)
            .background(Color.white.opacity(0.9))
            .cornerRadius(10)
            .shadow(radius: 3)
            .padding(.horizontal)
            .padding(.top, 32)
            Spacer()
        }
    }
}
