//
//  mainTabView.swift
//  hotplace_finder
//
//  Created by 김석우 on 5/27/25.
//

//import AuthenticationServices
//import SwiftUI
//
//struct AppleLoginButton: View {
//    @AppStorage("userID") private var userID: String = ""
//    @State private var AppleloginSuccess: Bool = false
//    var body: some View {
//        VStack(spacing: 10) {
//                SignInWithAppleButton(.signIn,
//                    onRequest: configure,
//                    onCompletion: handle
//                )
//                .signInWithAppleButtonStyle(.black)
//                .frame(width: 200, height: 45)
//
//                // ✅ 로그인 성공 메시지
//                if AppleloginSuccess {
//                    Text("✅ 로그인 성공!")
//                        .foregroundColor(.green)
//                        .font(.subheadline)
//                }
//        }
//    }
//
//    func configure(_ request: ASAuthorizationAppleIDRequest) {
//        request.requestedScopes = [.fullName, .email]
//    }
//
//    func handle(_ result: Result<ASAuthorization, Error>) {
//        switch result {
//        case .success(let auth):
//            if let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential {
//                let userId = appleIDCredential.user
//                print("Apple ID 로그인 성공: \(userId)")
//                userID = userId
//                AppleloginSuccess = true
//                // 🔒 AppStorage 등에 저장해 로그인 상태 유지 가능
//            }
//        case .failure(let error):
//            print("Apple ID 로그인 실패: \(error.localizedDescription)")
//        }
//    }
//}


import SwiftUI
import AuthenticationServices
import FirebaseAuth
import CryptoKit

struct AppleLoginButton: View {
    @AppStorage("userID") private var userID: String = ""
    @State private var AppleloginSuccess: Bool = false
    @State private var currentNonce: String?

    var body: some View {
        VStack(spacing: 10) {
            Text("로그인")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top, 0)
                    .frame(maxWidth: .infinity, alignment: .leading)
            Text("로그인하여 나만의 사진을 업로드해 보세요 :)")
                    .font(.subheadline)
                    .bold()
                    .padding(.top, 0)
                    .frame(maxWidth: .infinity, alignment: .leading)
            
            SignInWithAppleButton(.signIn, onRequest: configure, onCompletion: handle)
                .signInWithAppleButtonStyle(.black)
                .frame(width: 200, height: 45)
                .padding(.top, 50)

            if AppleloginSuccess {
                Text("✅ 로그인 성공!")
                    .foregroundColor(.green)
                    .font(.subheadline)
            }
        }
    }

    // 🔐 Apple 요청 구성: nonce 생성
    func configure(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    // ✅ Apple 로그인 후 Firebase 연동
    func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard
                let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                let nonce = currentNonce,
                let appleIDToken = appleIDCredential.identityToken,
                let idTokenString = String(data: appleIDToken, encoding: .utf8)
            else {
                print("❌ Apple 로그인 실패: 유효하지 않은 토큰")
                return
            }

            let credential = OAuthProvider.credential(
                providerID: .apple,
                idToken: idTokenString,
                rawNonce: nonce
            )

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("❌ Firebase 로그인 실패: \(error.localizedDescription)")
                    return
                }

                if let user = authResult?.user {
                    print("✅ Firebase 로그인 성공, UID: \(user.uid)")
                    userID = user.uid // ✅ 추적 및 제재에 사용하는 고유 ID 저장
                    AppleloginSuccess = true
                }
            }

        case .failure(let error):
            print("❌ Apple 로그인 실패: \(error.localizedDescription)")
        }
    }
}

import CryptoKit

func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashed = SHA256.hash(data: inputData)
    return hashed.map { String(format: "%02x", $0) }.joined()
}

func randomNonceString(length: Int = 32) -> String {
    let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
        let randoms: [UInt8] = (0..<16).map { _ in
            var random: UInt8 = 0
            _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            return random
        }

        randoms.forEach { random in
            if remainingLength == 0 { return }

            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }

    return result
}
