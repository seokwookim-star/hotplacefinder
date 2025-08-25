import SwiftUI
import NMapsMap

struct NaverMapView: UIViewRepresentable {
    var places: [hotplace_struct]
    @Binding var cameraTarget: NMGLatLng?
    @Binding var showImagePopup: Bool
    @Binding var userLocationMarker: NMGLatLng?     // ✅ 변경: newMarker → userLocationMarker
    @Binding var searchResultMarker: NMGLatLng?     // ✅ 추가: 검색 마커 분리
    @Binding var popupLat: Double?
    @Binding var popupLng: Double?
    @Binding var selectedImageUrls: [String]
    @Binding var selectedTimestamps: [Date]
    @Binding var selectedImageIndex: Int
    @Binding var shouldMoveToUserLocation: Bool
    @Binding var shouldMoveToSearchLocation: Bool
    @Binding var selectedTakenAtList: [Date]
    @Binding var selectedImageTitles: [String]
    @Binding var selectedDescriptions: [String]

    class Coordinator {
        var markers: [NMFMarker] = []
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    func makeUIView(context: Context) -> NMFNaverMapView {
        return NMFNaverMapView()
    }

    func updateUIView(_ uiView: NMFNaverMapView, context: Context) {
        for marker in context.coordinator.markers {
            marker.mapView = nil
        }
        context.coordinator.markers.removeAll()

        // ✅ 사용자 위치 마커 추가
        if let userPos = userLocationMarker {
            let marker = NMFMarker(position: userPos)
            marker.iconImage = NMFOverlayImage(name: "user_location_3")
            marker.width = 30
            marker.height = 30
            marker.alpha = 0.98
            marker.zIndex = Int.max
            marker.mapView = uiView.mapView
            marker.touchHandler = { _ in
                DispatchQueue.main.async {
                    self.selectedImageUrls = []
                    self.selectedTimestamps = []
                    self.selectedImageIndex = 0
                    self.popupLat = userPos.lat
                    self.popupLng = userPos.lng
                    self.showImagePopup = true
                    
                }
                return true
            }
            context.coordinator.markers.append(marker)
        }

        // ✅ 검색 결과 마커 추가
        if let searchPos = searchResultMarker {
            let marker = NMFMarker(position: searchPos)
            marker.iconImage = NMFOverlayImage(name: "pin")
            marker.width = 30
            marker.height = 30
            marker.mapView = uiView.mapView
            marker.touchHandler = { _ in
                DispatchQueue.main.async {
                    self.selectedImageUrls = []
                    self.selectedTimestamps = []
                    self.selectedImageIndex = 0
                    self.popupLat = searchPos.lat
                    self.popupLng = searchPos.lng
                    self.showImagePopup = true
                }
                return true
            }
            context.coordinator.markers.append(marker)
        }

        // ✅ 카메라 이동 조건
        if let target = cameraTarget {
            if shouldMoveToSearchLocation {
                    let update = NMFCameraUpdate(scrollTo: target, zoomTo: 15)
                    update.animation = .easeIn
                    uiView.mapView.moveCamera(update)
                    DispatchQueue.main.async {
                        self.shouldMoveToSearchLocation = false  // 한 번만 이동하도록 리셋
                    }
                }
            else if shouldMoveToUserLocation {
                let update = NMFCameraUpdate(scrollTo: target)
                update.animation = .easeIn
                uiView.mapView.moveCamera(update)
                DispatchQueue.main.async {
                    self.shouldMoveToUserLocation = false
                }
            }
        }
        // ✅ 장소 마커들 추가
        for place in places {
            let marker = NMFMarker(position: NMGLatLng(lat: place.lat, lng: place.lng))
            marker.iconImage = markerIcon(for: place.category)
            marker.width = 24
            marker.height = 24
            marker.mapView = uiView.mapView
            marker.touchHandler = { _ in
                DispatchQueue.main.async {
                    self.selectedImageUrls = place.imageUrls
                    print("🧪 이미지 수: \(place.imageUrls.count)")
                    self.selectedTimestamps = place.timestamps
                    self.selectedImageIndex = 0
                    self.popupLat = place.lat
                    self.popupLng = place.lng
                    self.showImagePopup = true
                    self.cameraTarget = nil
                    self.selectedTakenAtList = place.takenAtList        // ✅ 추가
                    self.selectedImageTitles = place.titles             // ✅ 추가
                    self.selectedDescriptions = place.descriptions
                    let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: place.lat, lng: place.lng), zoomTo: 15.0)
                    cameraUpdate.animation = .easeIn
                    uiView.mapView.moveCamera(cameraUpdate)
                }
                return true
            }
            context.coordinator.markers.append(marker)
        }
    }

    func markerIcon(for category: String) -> NMFOverlayImage {
        let imageName: String
        switch category {
        case "벚꽃": imageName = "sakura"
        case "자연": imageName = "nature"
        case "폭포": imageName = "waterfall"
        case "맛집": imageName = "food"
        case "데이트명소" : imageName = "date"
        case "꽃": imageName = "flower"
        case "카페": imageName = "coffee"	
        default: imageName = "default"
        }
        return NMFOverlayImage(name: imageName)
    }
}
