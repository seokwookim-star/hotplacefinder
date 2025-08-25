import SwiftUI
import UIKit

struct FullScreenImageView: View {
    let imageUrl: String
    @Binding var isPresented: Bool

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { scale = $0 }
                                .onEnded { _ in
                                    if scale < 1.0 { scale = 1.0 }
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { offset = $0.translation }
                                .onEnded { _ in }
                        )
                } placeholder: {
                    ProgressView()
                }
            }

            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}
