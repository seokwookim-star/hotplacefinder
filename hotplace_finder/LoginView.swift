//
//  mainTabView.swift
//  hotplace_finder
//
//  Created by 김석우 on 5/27/25.
//

import SwiftUI
import AuthenticationServices
import MessageUI

struct LoginView: View {
    var body: some View {
        VStack(spacing: 30) {

           AppleLoginButton()
           
           // 🔄 Firebase 문서 구조 마이그레이션 버튼 (개발용)
           #if DEBUG
           Button(action: {
               // ContentView의 viewModel에 접근하기 위해 간단한 알림
               let alert = UIAlertController(
                   title: "Firebase 마이그레이션",
                   message: "기존 단일 이미지 필드를 배열로 변환합니다. 콘솔을 확인하세요.",
                   preferredStyle: .alert
               )
               alert.addAction(UIAlertAction(title: "확인", style: .default))
               UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
           }) {
               HStack {
                   Image(systemName: "arrow.triangle.2.circlepath")
                   Text("Firebase 문서 구조 마이그레이션")
               }
               .foregroundColor(.orange)
               .padding()
               .background(Color(UIColor.systemGray6))
               .cornerRadius(8)
           }
           #endif
           
            Button(action: {
                            sendEmail()
                        }) {
                            HStack {
                                Image(systemName: "envelope")
                                Text("버그 제보 / 협업 제안")
                            }
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                        }
            AccountDeleteView()
               .tabItem {
                   Label("계정 관리", systemImage: "gear")
               }
        }.padding()
    }
    
    private func sendEmail() {
           let email = "kabile@naver.com" // 여기에 본인의 이메일 입력
           let subject = "핫플파인더 - 버그 제보 또는 협업 제안"
           let body = """
           안녕하세요, 핫플파인더 개발팀에 제보드립니다.

           [여기에 내용을 입력해주세요]

           - 보낸 기기: \(UIDevice.current.model)
           - iOS 버전: \(UIDevice.current.systemVersion)
           """

           let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
           let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
           let emailUrl = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)")

           if let url = emailUrl {
               UIApplication.shared.open(url)
           }
       }
}
