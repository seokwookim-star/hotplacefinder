
import UIKit
import NaverThirdPartyLogin
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate, NaverThirdPartyLoginConnectionDelegate {
    var onLoginSuccess: ((String) -> Void)?
    var onLoginFailure: ((String) -> Void)?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // ✅ Google Mobile Ads 초기화
//        MobileAds.sharedInstance().start(completionHandler: nil)
        MobileAds.shared.start(completionHandler: nil)
        // ✅ Naver 로그인 초기화
        let instance = NaverThirdPartyLoginConnection.getSharedInstance()
        instance?.isNaverAppOauthEnable = true
        instance?.isInAppOauthEnable = true
        instance?.isOnlyPortraitSupportedInIphone()
        instance?.serviceUrlScheme = "naver0YfCWajxc8DrRjGgSaQN"
        instance?.consumerKey = "0YfCWajxc8DrRjGgSaQN"
        instance?.consumerSecret = "Q5VfRmoCU4"
        instance?.appName = "hotplace_finder"
//      instance?.delegate = self  // 필요한 경우 주석 해제

        return true
    }

    func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        _ = NaverThirdPartyLoginConnection.getSharedInstance()?.receiveAccessToken(url)
        return true
    }

    func oauth20ConnectionDidFinishRequestACTokenWithAuthCode() {
        guard let token = NaverThirdPartyLoginConnection.getSharedInstance()?.accessToken else {
            onLoginFailure?("토큰 없음")
            return
        }

        let url = URL(string: "https://openapi.naver.com/v1/nid/me")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let res = json["response"] as? [String: Any],
               let id = res["id"] as? String {
                self.onLoginSuccess?("naver_\(id)")
            } else {
                self.onLoginFailure?("사용자 정보 파싱 실패")
            }
        }.resume()
    }

    func oauth20Connection(_ connection: NaverThirdPartyLoginConnection!, didFailWithError error: Error!) {
        onLoginFailure?("로그인 실패: \(error.localizedDescription)")
    }

    func oauth20ConnectionDidFinishDeleteToken() {}
    func oauth20ConnectionDidFinishRequestACTokenWithRefreshToken() {}
}
