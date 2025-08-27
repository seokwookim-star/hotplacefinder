import SwiftUI
import UIKit

struct ZoomableImageView: View {
    let imageUrl: URL
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        OptimizedAsyncImage(url: imageUrl.absoluteString) { image in
            image
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = lastScale * value
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }
                )
                .animation(.easeInOut(duration: 0.2), value: scale)
        }
    }
}
