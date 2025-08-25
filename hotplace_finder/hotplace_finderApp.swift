//
//  hotplace_finderApp.swift
//  hotplace_finder
//
//  Created by 김석우 on 4/17/25.
//

import SwiftUI
import SwiftData
import FirebaseCore
import KakaoSDKCommon
import KakaoSDKAuth
import NaverThirdPartyLogin
import GoogleMobileAds


@main
struct hotplace_finderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openURL) var openURL
    init() {
        FirebaseApp.configure()
        
        MobileAds.shared.start()
//        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [ GADSimulatorID ]
        KakaoSDK.initSDK(appKey: "a1986eb58b15e9bbbc725fb1e1700696")
        _ = NaverLoginManager.shared
        UIView.appearance().overrideUserInterfaceStyle = .light // 라이트 모드로 고정
        }
    var body: some Scene {
        WindowGroup {
            MainTabView().onOpenURL { url in
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                        }
                _ = NaverThirdPartyLoginConnection.getSharedInstance()?.receiveAccessToken(url)
                
                }
//            TestAdView()
        }
    }
}
