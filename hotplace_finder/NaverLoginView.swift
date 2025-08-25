//
//  mainTabView.swift
//  hotplace_finder
//
//  Created by 김석우 on 5/27/25.
//

import SwiftUI
import NaverThirdPartyLogin
struct NaverLoginView: View {
    @AppStorage("userID") var userID: String = ""
    @State private var message: String = ""
    @StateObject private var coordinator = NaverLoginCoordinator()

    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                let instance = NaverThirdPartyLoginConnection.getSharedInstance()

                if instance?.isValidAccessTokenExpireTimeNow() == true {
                    fetchNaverUserID()
                } else {
                    coordinator.onLoginSuccess = { id in
                        DispatchQueue.main.async {
                            self.userID = "naver_\(id)"
                            self.message = "✅ 네이버 로그인 성공"
                        }
                    }

                    coordinator.onLoginFailure = { errorMessage in
                        DispatchQueue.main.async {
                            self.message = "❌ \(errorMessage)"
                        }
                    }

                    instance?.delegate = coordinator
                    instance?.requestThirdPartyLogin()
                }
            }) {
                HStack {
                    Image("naver")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)

                    Text("네이버로 로그인")
                        .fontWeight(.medium)
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.green)
                .cornerRadius(10)
            }

            if !message.isEmpty {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .transition(.opacity)
            }
        }
        .onAppear {
            let instance = NaverThirdPartyLoginConnection.getSharedInstance()
            if instance?.isValidAccessTokenExpireTimeNow() == true {
                fetchNaverUserID()
            }
        }
        .animation(.easeInOut, value: message)
        .padding()
    }

    func fetchNaverUserID() {
        guard let token = NaverThirdPartyLoginConnection.getSharedInstance()?.accessToken else {
            self.message = "❌ 유효한 토큰이 없습니다"
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
                DispatchQueue.main.async {
                    self.userID = "naver_\(id)"
                    self.message = "✅ 네이버 로그인 성공"
                }
            } else {
                DispatchQueue.main.async {
                    self.message = "❌ 사용자 정보 파싱 실패"
                }
            }
        }.resume()
    }
}


//import SwiftUI
//import NaverThirdPartyLogin
//
//struct NaverLoginView: View {
//    @AppStorage("userID") var userID: String = ""
//    @State private var message: String = ""
//    
//    // 유지될 수 있게 coordinator를 StateObject로 래핑
////    private let coordinator = NaverLoginCoordinator()
//    @StateObject private var coordinator = NaverLoginCoordinator()
//
//    var body: some View {
//        VStack(spacing: 20) {
//            Button(action: {
//                let instance = NaverThirdPartyLoginConnection.getSharedInstance()
//                
//                coordinator.onLoginSuccess = { id in
//                    DispatchQueue.main.async {
//                        self.userID = "naver_\(id)"
//                        print(self.userID)
//                        self.message = "✅ 네이버 로그인 성공"
//                        
//                    }
//                }
//
//                coordinator.onLoginFailure = { errorMessage in
//                    DispatchQueue.main.async {
//                        self.message = "❌ \(errorMessage)"
//                    }
//                }
//
//                instance?.delegate = coordinator
//                instance?.requestThirdPartyLogin()
//            }) {
//                HStack {
//                    Image("naver")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 20, height: 20)
//
//                    Text("네이버로 로그인")
//                        .fontWeight(.medium)
//                }
//                .padding()
//                .foregroundColor(.white)
//                .background(Color.green)
//                .cornerRadius(10)
//            }
//            
//            if !message.isEmpty {
//                Text(message)
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//                    .transition(.opacity)
//            }
//        }
//        .animation(.easeInOut, value: message)
//        .padding()
//    }
//}
