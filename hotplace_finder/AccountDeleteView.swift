//
//  mainTabView.swift
//  hotplace_finder
//
//  Created by 김석우 on 5/27/25.
//
import SwiftUI

struct AccountDeleteView: View {
    @AppStorage("userID") var userID: String = ""
    @State private var showConfirmation = false
    @State private var isDeleted = false

    var body: some View {
        Spacer()
        VStack(spacing: 20) {
            if isDeleted && userID == "" {
                Text("계정이 삭제되었습니다.")
                    .foregroundColor(.red)
                    .padding(.bottom, 70)
            } else {
                Button(role: .destructive) {
                    showConfirmation = true
                } label: {
                    Text("계정 삭제")
//                        .frame(maxWidth: 100)
                        .frame(width: 70, height: 15)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                .confirmationDialog("정말로 계정을 삭제하시겠습니까?", isPresented: $showConfirmation) {
                    Button("삭제", role: .destructive) {
                        deleteAccount()
                    }
                    Button("취소", role: .cancel) {}
                }
                Text("✅ Apple ID로 로그인된 상태입니다")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom, 70)
            }
        }
        .padding()
    }

    func deleteAccount() {
        // 🔥 실제 서버나 Firebase와 연동 시 여기서 삭제 API 호출
        print("Deleting user: \(userID)")
        
        // 예시로 로컬 데이터만 삭제
        userID = ""
        isDeleted = true
    }
}
