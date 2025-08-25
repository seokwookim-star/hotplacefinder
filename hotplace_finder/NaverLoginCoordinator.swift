//
//  mainTabView.swift
//  hotplace_finder
//
//  Created by 김석우 on 5/27/25.
//

import Foundation
import NaverThirdPartyLogin
import Combine

class NaverLoginCoordinator: NSObject, ObservableObject, NaverThirdPartyLoginConnectionDelegate {
    var onLoginSuccess: ((String) -> Void)?
    var onLoginFailure: ((String) -> Void)?

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
                self.onLoginSuccess?(id)
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

//import Foundation
//import NaverThirdPartyLogin
//
//class NaverLoginCoordinator: NSObject, NaverThirdPartyLoginConnectionDelegate {
//    var onLoginSuccess: ((String) -> Void)?
//    var onLoginFailure: ((String) -> Void)?
//
//    func oauth20ConnectionDidFinishRequestACTokenWithAuthCode() {
//        guard let token = NaverThirdPartyLoginConnection.getSharedInstance()?.accessToken else {
//            onLoginFailure?("토큰 획득 실패")
//            return
//        }
//
//        let url = URL(string: "https://openapi.naver.com/v1/nid/me")!
//        var request = URLRequest(url: url)
//        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//
//        URLSession.shared.dataTask(with: request) { data, _, _ in
//            if let data = data,
//               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//               let response = json["response"] as? [String: Any],
//               let id = response["id"] as? String {
//                DispatchQueue.main.async {
//                    self.onLoginSuccess?(id)
//                }
//            } else {
//                DispatchQueue.main.async {
//                    self.onLoginFailure?("사용자 정보 파싱 실패")
//                }
//            }
//        }.resume()
//    }
//
//    func oauth20Connection(_ connection: NaverThirdPartyLoginConnection!, didFailWithError error: Error!) {
//        onLoginFailure?("로그인 실패: \(error.localizedDescription)")
//    }
//
//    func oauth20ConnectionDidFinishDeleteToken() {}
//    func oauth20ConnectionDidFinishRequestACTokenWithRefreshToken() {}
//}
