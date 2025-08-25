//
//  startAnimation.swift
//  hotplace_finder
//
//  Created by 김석우 on 5/8/25.
//
// New File 1: LoadingView.swift

import SwiftUI
import Firebase

struct ReportPopupView: View {
    let placeId: String
    let imageUrl: String
    @Binding var isPresented: Bool
    @State private var reasonText: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🚨 신고하기")
                .font(.headline)
            
            Text("신고 사유를 입력해주세요.")
                .font(.subheadline)
            
            TextEditor(text: $reasonText)
                .frame(height: 120)
                .border(Color.gray, width: 1)
                .focused($isFocused)
                .onAppear { isFocused = true }
            
            HStack {
                Button("취소") {
                    isPresented = false
                }
                .foregroundColor(.gray)
                
                Spacer()
                
                Button("신고") {
                    submitReport()
                }
                .disabled(reasonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .foregroundColor(.red)
                .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding()
    }
    
    
    func submitReport() {
        let db = Firestore.firestore()
        let reportLog: [String: Any] = [
            "placeId": placeId,
            "imageUrl": imageUrl,
            "reason": reasonText,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        db.collection("reports").addDocument(data: reportLog) { error in
            if let error = error {
                print("❌ 신고 저장 실패: \(error.localizedDescription)")
            } else {
                print("✅ 신고 저장 성공")
                isPresented = false
            }
        }
    }
}
    
    
//    func submitReport() {
//        let db = Firestore.firestore()
//        let placeRef = db.collection("locations").document(placeId)
//
//        db.runTransaction({ (transaction, errorPointer) -> Any? in
//            do {
//                let snapshot = try transaction.getDocument(placeRef)
//                let currentCount = snapshot.data()?["reportCounts"] as? Int ?? 0
//                let newCount = currentCount + 1
//
//                print("📌 현재 신고 수: \(currentCount), 신고 후: \(newCount)")
//
//                transaction.updateData(["reportCounts": newCount], forDocument: placeRef)
//            } catch {
//                print("❌ 트랜잭션 실패: \(error.localizedDescription)")
//                return nil
//            }
//            return nil
//        }) { (_, error) in
//            if let error = error {
//                print("❌ 최종 트랜잭션 실패: \(error.localizedDescription)")
//            } else {
//                print("✅ 신고 성공! reportCounts 증가")
//                // 신고 로그는 트랜잭션 이후에 추가
//                let reportLog: [String: Any] = [
//                    "placeId": placeId,
//                    "imageUrl": imageUrl,
//                    "reason": reasonText,
//                    "timestamp": FieldValue.serverTimestamp()
//                ]
//                db.collection("reports").addDocument(data: reportLog) { logError in
//                    if let logError = logError {
//                        print("⚠️ 신고 로그 저장 실패: \(logError.localizedDescription)")
//                    } else {
//                        print("📝 신고 로그 저장 완료")
//                    }
//                }
//
//                // 팝업 닫기
//                isPresented = false
//            }
//        }
//    }
//}



//import SwiftUI
//import Firebase
//
//struct ReportPopupView: View {
//    let placeId: String
//    let imageUrl: String
//    @Binding var isPresented: Bool
//    @State private var reasonText: String = ""
//    @FocusState private var isFocused: Bool
//
//    var body: some View {
//        VStack(spacing: 20) {
//            Text("🚨 신고하기")
//                .font(.headline)
//
//            Text("신고 사유를 입력해주세요.")
//                .font(.subheadline)
//
//            TextEditor(text: $reasonText)
//                .frame(height: 120)
//                .border(Color.gray, width: 1)
//                .focused($isFocused)
//                .onAppear { isFocused = true }
//
//            HStack {
//                Button("취소") {
//                    isPresented = false
//                }
//                .foregroundColor(.gray)
//
//                Spacer()
//                
//                Button("신고") {
//                    submitReport()
//                }
//                .disabled(reasonText.trimmingCharacters(in: .whitespaces).isEmpty)
//                .foregroundColor(.red)
//                .fontWeight(.bold)
//            }
//        }
//        .padding()
//        .background(Color.white)
//        .cornerRadius(16)
//        .shadow(radius: 10)
//        .padding()
//    }
//
//    func submitReport() {
//        let db = Firestore.firestore()
//        let placeRef = db.collection("places").document(placeId)
//
//        db.runTransaction({ (transaction, errorPointer) -> Any? in
//            let snapshot: DocumentSnapshot
//            do {
//                snapshot = try transaction.getDocument(placeRef)
//            } catch {
//                return nil
//            }
//
//            let currentCount = snapshot.data()?["reportCounts"] as? Int ?? 0
//            transaction.updateData(["reportCounts": currentCount + 1], forDocument: placeRef)
//
//            let reportLog: [String: Any] = [
//                "placeId": placeId,
//                "imageUrl": imageUrl,
//                "reason": reasonText,
//                "timestamp": FieldValue.serverTimestamp()
//            ]
//            db.collection("reports").addDocument(data: reportLog)
//
//            return nil
//        }) { (_, error) in
//            if let error = error {
//                print("신고 실패: \(error)")
//            } else {
//                print("신고 완료")
//                isPresented = false
//            }
//        }
//    }
//}
