//
//  MapView.swift
//  hotplace_finder
//
//  Created by 김석우 on 4/17/25.
//

import SwiftUI
import MapKit

struct MapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780), // 초기값: 서울 시청
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var body: some View {
        Map(coordinateRegion: $region, showsUserLocation: true)
            .ignoresSafeArea()
            .onAppear {
                requestCurrentLocation()
            }
    }

    private func requestCurrentLocation() {
        let manager = CLLocationManager()
        manager.requestWhenInUseAuthorization()
        if let location = manager.location {
            region.center = location.coordinate
        }
    }
}
