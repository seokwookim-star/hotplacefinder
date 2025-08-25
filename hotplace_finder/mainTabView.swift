//
//  mainTabView.swift
//  hotplace_finder
//
//  Created by 김석우 on 5/27/25.
//

import SwiftUI

struct MainTabView: View {
    @AppStorage("userID") var userID: String = ""
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ZStack {
                ContentView()
                VStack{
                    Spacer()
                    HStack{
                        BannerAdView(adUnitID: "ca-app-pub-1784560805883962/9475697003")
                            .frame(width: 320, height: 50)
                            .padding(.bottom, 36)
                            .ignoresSafeArea(.keyboard, edges: .bottom)
                    }
                }.zIndex(100)
            }.tag(0)
                .tabItem {
                    Label("지도", systemImage: "map")
                }
            ZStack {
                LoginView()
                VStack{
                    Spacer()
                    HStack{
                        BannerAdView(adUnitID: "ca-app-pub-1784560805883962/9475697003")
                            .frame(width: 320, height: 50)
                            .padding(.bottom, 36)
                            .ignoresSafeArea(.keyboard, edges: .bottom)
                    }
                }.zIndex(100)
            }.tag(1)
                .tabItem {
                    Label("로그인", systemImage: "person.circle")
                }
        }
        .onAppear {
            if !userID.isEmpty {
                selectedTab = 0
            }
        }
        .onChange(of: userID) { oldValue, newValue in
            if !newValue.isEmpty {
                selectedTab = 0
            }
        }
    }
}
