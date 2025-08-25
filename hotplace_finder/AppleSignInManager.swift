//
//  mainTabView.swift
//  hotplace_finder
//
//  Created by 김석우 on 5/27/25.
//
import AuthenticationServices

class AppleSignInManager: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    var onSignInSuccess: ((String) -> Void)?
    var onSignInFailure: ((Error?) -> Void)?

    func startSignInWithAppleFlow() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // ✅ 사용자 인증 성공 시 처리
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userId = "apple_\(appleIDCredential.user)"
            onSignInSuccess?(userId)
        }
    }

    // ❌ 실패 시 처리
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onSignInFailure?(error)
    }

    // ✅ 어떤 창에서 인증을 띄울지 지정
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first { $0.isKeyWindow }!
    }
}
