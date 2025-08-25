//
//  mainTabView.swift
//  hotplace_finder
//
//  Created by 김석우 on 5/27/25.
//

// 카카오로그인id : 4279811343 
import SwiftUI
import KakaoSDKAuth
import KakaoSDKUser

struct KakaoLoginView: View {
    @AppStorage("userID") var userID: String = ""
    @State private var message: String = ""

    var body: some View {
        VStack {
            Button(action: {
                loginWithKakao()
            }) {
                HStack {
                    Image(systemName: "bubble.left")
                    Text("카카오로 로그인")
                }
                .foregroundColor(.white)
                .padding()
//                .frame(maxWidth: .infinity)
                .background(Color.yellow)
                .cornerRadius(10)
            }

            Text(message)
                .foregroundColor(.gray)
        }
        .padding()
    }

    func loginWithKakao() {
        // 카카오톡 앱이 설치되어 있으면 앱으로 로그인
        if UserApi.isKakaoTalkLoginAvailable() {
            UserApi.shared.loginWithKakaoTalk { oauthToken, error in
                handleLoginResult(oauthToken: oauthToken, error: error)
            }
        } else {
            // 웹 기반 로그인 (앱 미설치 시 fallback)
            UserApi.shared.loginWithKakaoAccount { oauthToken, error in
                handleLoginResult(oauthToken: oauthToken, error: error)
            }
        }
    }

    func handleLoginResult(oauthToken: OAuthToken?, error: Error?) {
        if let error = error {
            self.message = "로그인 실패: \(error.localizedDescription)"
            return
        }

        // 사용자 정보 요청
        UserApi.shared.me { user, error in
            if let error = error {
                self.message = "사용자 정보 불러오기 실패: \(error.localizedDescription)"
                return
            }

            if let id = user?.id {
                self.userID = "kakao_\(id)"
                self.message = "✅ 카카오 로그인 성공!"
            } else {
                self.message = "사용자 ID가 없습니다."
            }
        }
    }
}
