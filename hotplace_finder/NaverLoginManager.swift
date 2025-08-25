//
//  mainTabView.swift
//  hotplace_finder
//
//  Created by 김석우 on 5/27/25.
//

import Foundation
import NaverThirdPartyLogin

class NaverLoginManager {
    static let shared = NaverLoginManager()

    private init() {
        let instance = NaverThirdPartyLoginConnection.getSharedInstance()
        instance?.isNaverAppOauthEnable = true
        instance?.isInAppOauthEnable = true
        instance?.isOnlyPortraitSupportedInIphone()
        instance?.serviceUrlScheme = "naver0YfCWajxc8DrRjGgSaQN"  // 예: "naver9s8n4xxxxxx"
        instance?.consumerKey = "0YfCWajxc8DrRjGgSaQN"
        instance?.consumerSecret = "Q5VfRmoCU4"
        instance?.appName = "hotplace_finder"
    }
}
