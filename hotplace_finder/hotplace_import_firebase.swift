//
//  hotplace_import_firebase.swift
//  hotplace_finder
//
//  Created by 김석우 on 4/20/25.
//


import Foundation
import FirebaseFirestore
import FirebaseStorage
import NMapsMap

class hotplace_import_firebase: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var places: [hotplace_struct] = []
    @Published var cameraTarget: NMGLatLng? = nil
    @Published var filteredPlaces: [hotplace_struct] = []
    private let locationManager = CLLocationManager()
    @Published var selectedCategory: String = "전체" {
        didSet {
            filterPlaces()
            cameraTarget = nil
        }
    }
    @Published var categoryOptions: [String] = ["전체"]
    @Published var userLocation: CLLocationCoordinate2D? = nil
    @Published var shouldMoveToUserLocation = false
    @Published var shouldMoveToSearchLocation: Bool = false
    @Published var isManualCameraMove = false
    @Published var userLocationMarker: NMGLatLng? = nil  // ✅ 내 위치 마커
    @Published var searchResultMarker: NMGLatLng? = nil  // ✅ 검색 결과 마커
    @Published var didInitialMapMove = false
    @Published var kakaoSearchResults: [KakaoPlace] = []
    @Published var showKakaoSearchList = false
    
    func filterPlaces() {
        if selectedCategory == "전체" {
            filteredPlaces = places
        } else {
            filteredPlaces = places.filter { $0.category == selectedCategory }
        }
    }
    func resetCameraTarget() {
        cameraTarget = nil
    }
    func searchPlaceWithFallback(_ query: String) {
        geocodeAddressWithFallback(query) { success in
            if !success {
                self.searchAllPlacesWithKakao(query)
            }
        }
    }
    func geocodeAddressWithFallback(_ address: String, completion: @escaping (Bool) -> Void) {
        guard let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("❌ 주소 인코딩 실패: \(address)")
            completion(false)
            return
        }
        
        let urlStr = "https://maps.apigw.ntruss.com/map-geocode/v2/geocode?query=\(encoded)"
        guard let url = URL(string: urlStr) else {
            print("❌ 유효하지 않은 URL")
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.addValue("mq1j6nqpbs", forHTTPHeaderField: "X-NCP-APIGW-API-KEY-ID")
        request.addValue("ILGKKEbhNUVLaXzt0ClYlgZvzthvJ5GOTjKqrcT0", forHTTPHeaderField: "X-NCP-APIGW-API-KEY")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data else {
                print("❌ 네이버 응답 없음")
                completion(false)
                return
            }
            do {
                let decoded = try JSONDecoder().decode(GeocodeResponse.self, from: data)
                if let address = decoded.addresses.first,
                   let lat = Double(address.y),
                   let lng = Double(address.x) {
                    DispatchQueue.main.async {
                        let newTarget = NMGLatLng(lat: lat, lng: lng)
                        self.cameraTarget = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            self.cameraTarget = newTarget
                            self.searchResultMarker = newTarget
                            self.shouldMoveToSearchLocation = true
                            print("📍 네이버 지오코딩 성공 → 위치 이동: \(lat), \(lng)")
                        }
                    }
                } else {
                    print("❌ 네이버 검색 결과 없음")
                    completion(false)
                }
            } catch {
                print("❌ 네이버 디코딩 실패: \(error.localizedDescription)")
                completion(false)
            }
        }.resume()
    }
    func requestUserLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        locationManager.startUpdatingLocation()
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude
        
        self.userLocation = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        self.userLocationMarker = NMGLatLng(lat: lat, lng: lng)
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("혼자 위치 가져오기 실패: \(error.localizedDescription)")
    }
    func searchAllPlacesWithKakao(_ query: String) {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        
        let urlStr = "https://dapi.kakao.com/v2/local/search/keyword.json?query=\(encoded)"
        guard let url = URL(string: urlStr) else { return }
        
        var request = URLRequest(url: url)
        request.setValue("KakaoAK 0ae8c5a742307b053a518b1166adeefb", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode(KakaoPlaceResponse.self, from: data)
                DispatchQueue.main.async {
                    self.kakaoSearchResults = decoded.documents
                    self.showKakaoSearchList = true
                }
            } catch {
                print("❌ Kakao 디코딩 실패: \(error)")
            }
        }.resume()
    }
    func searchPlaceWithKakao(_ query: String) {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("❌ 주소 인코딩 실패: \(query)")
            return
        }
        
        let urlStr = "https://dapi.kakao.com/v2/local/search/keyword.json?query=\(encoded)"
        guard let url = URL(string: urlStr) else {
            print("❌ 유효하지 않은 URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("KakaoAK 0ae8c5a742307b053a518b1166adeefb", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 네트워크 오류: \(error)")
                return
            }
            
            guard let data = data else {
                print("❌ 응답 없음")
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(KakaoPlaceResponse.self, from: data)
                guard let place = decoded.documents.first,
                      let lat = Double(place.y),
                      let lng = Double(place.x) else {
                    print("❌ 좌표 파싱 실패")
                    return
                }
                
                DispatchQueue.main.async {
                    let newTarget = NMGLatLng(lat: lat, lng: lng)
                    self.cameraTarget = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        self.cameraTarget = newTarget
                        self.searchResultMarker = newTarget  // ✅ 검색 결과 마커 지정
                        self.shouldMoveToSearchLocation = true
                    }
                }
            } catch {
                print("❌ 디코딩 실패: \(error)")
            }
        }.resume()
    }
    func fetchPlaces() {
        Firestore.firestore().collection("locations").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            guard let documents = snapshot?.documents else { return }

            var categorySet: Set<String> = []

            self.places = documents.compactMap { doc -> hotplace_struct? in
                let data = doc.data()
                guard
//                    let title = data["title"] as? String,
                    let lat = data["lat"] as? Double,
                    let lng = data["lng"] as? Double,
                    let category = data["category"] as? String
                else {
                    return nil
                }

                // 🔍 이미지 URL 배열
                let imageUrls: [String] = {
                    if let urls = data["imageUrls"] as? [String] {
                        return urls
                    } else if let url = data["imageUrl"] as? String {
                        return [url]
                    } else {
                        return []
                    }
                }()

                guard !imageUrls.isEmpty else { return nil }

                // 🕒 업로드 시간
                let timestamps: [Date] = (data["timestamps"] as? [Timestamp])?.map { $0.dateValue() } ?? []

                // 🕓 촬영 시간
                let takenAtList: [Date] = (data["takenAtList"] as? [Timestamp])?.map { $0.dateValue() } ?? []

                // 📝 제목과 설명
                let imageTitles: [String] = data["titles"] as? [String] ?? []
                let descriptions: [String] = data["descriptions"] as? [String] ?? []

                categorySet.insert(category)

                return hotplace_struct(
                    id: doc.documentID,
//                    title: title,
                    lat: lat,
                    lng: lng,
                    imageUrls: imageUrls,
                    timestamps: timestamps,
                    category: category,
                    takenAtList: takenAtList,
                    descriptions: descriptions,
                    titles: imageTitles
                )
            }

            DispatchQueue.main.async {
                self.categoryOptions = ["전체"] + categorySet.sorted()
                self.filterPlaces()
            }
        }
    }
    
    // 🔄 여러 이미지 업로드 메서드 추가
    func uploadMultipleImagesToFirebase(
        images: [UIImage],
        location: CLLocationCoordinate2D,
        customCategory: String? = nil,
        takenAt: Date? = nil,
        imageTitle: String = "",
        description: String = "",
        userID: String,
        completion: @escaping (Bool) -> Void
    ) {
        let db = Firestore.firestore()
        
        // 🔒 1. 업로드 금지 사용자 확인
        db.collection("bannedUsers").document(userID).getDocument { snapshot, error in
            if let error = error {
                print("🚫 밴 여부 확인 중 오류 발생: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let snapshot = snapshot, snapshot.exists {
                print("🚫 업로드 차단됨: \(userID)는 밴된 사용자입니다.")
                completion(false)
                return
            }
            
            // ✅ 2. 정상 사용자 → 여러 이미지 업로드 시작
            let group = DispatchGroup()
            var uploadedUrls: [String] = []
            var uploadFailed = false
            
            for image in images {
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    print("❌ 이미지 변환 실패")
                    uploadFailed = true
                    continue
                }
                
                group.enter()
                
                let fileName = UUID().uuidString + ".jpg"
                let storageRef = Storage.storage().reference().child("images/\(fileName)")
                
                storageRef.putData(imageData, metadata: nil) { metadata, error in
                    defer { group.leave() }
                    
                    if let error = error {
                        print("❌ Firebase Storage 업로드 실패: \(error.localizedDescription)")
                        uploadFailed = true
                        return
                    }
                    
                    storageRef.downloadURL { url, error in
                        guard let downloadURL = url else {
                            print("❌ 다운로드 URL 가져오기 실패")
                            uploadFailed = true
                            return
                        }
                        
                        uploadedUrls.append(downloadURL.absoluteString)
                    }
                }
            }
            
            // ✅ 3. 모든 이미지 업로드 완료 후 Firestore 업데이트
            group.notify(queue: .main) {
                if uploadFailed || uploadedUrls.isEmpty {
                    print("❌ 이미지 업로드 실패")
                    completion(false)
                    return
                }
                
                let categoryToUse = (customCategory?.isEmpty == false) ? customCategory! : self.selectedCategory
                let docId = "\(location.latitude)_\(location.longitude)_\(categoryToUse)"
                let docRef = db.collection("locations").document(docId)
                
                let uploadDate = Date()
                let takenDate = takenAt ?? uploadDate
                
                // 각 이미지에 대해 동일한 메타데이터 생성
                let timestamps = Array(repeating: Timestamp(date: uploadDate), count: uploadedUrls.count)
                let takenAtList = Array(repeating: Timestamp(date: takenDate), count: uploadedUrls.count)
                let titles = Array(repeating: imageTitle, count: uploadedUrls.count)
                let descriptions = Array(repeating: description, count: uploadedUrls.count)
                let userIDs = Array(repeating: userID, count: uploadedUrls.count)
                
                docRef.getDocument { snapshot, error in
                    if let error = error {
                        print("❌ 문서 확인 실패: \(error.localizedDescription)")
                        completion(false)
                        return
                    }
                    
                    if let document = snapshot, document.exists {
                        // 🔄 기존 문서에 업데이트
                        docRef.updateData([
                            "imageUrls": FieldValue.arrayUnion(uploadedUrls),
                            "timestamps": FieldValue.arrayUnion(timestamps),
                            "takenAtList": FieldValue.arrayUnion(takenAtList),
                            "titles": FieldValue.arrayUnion(titles),
                            "descriptions": FieldValue.arrayUnion(descriptions),
                            "userIDs": FieldValue.arrayUnion(userIDs)
                        ]) { err in
                            if let err = err {
                                print("❌ Firestore 업데이트 실패: \(err)")
                                completion(false)
                            } else {
                                self.fetchPlaces()
                                self.searchResultMarker = nil
                                completion(true)
                            }
                        }
                    } else {
                        // 🆕 새 문서 생성
                        docRef.setData([
                            "lat": location.latitude,
                            "lng": location.longitude,
                            "imageUrls": uploadedUrls,
                            "timestamps": timestamps,
                            "takenAtList": takenAtList,
                            "titles": titles,
                            "descriptions": descriptions,
                            "category": categoryToUse,
                            "userIDs": userIDs
                        ]) { err in
                            if let err = err {
                                print("❌ Firestore 문서 생성 실패: \(err)")
                                completion(false)
                            } else {
                                self.fetchPlaces()
                                self.searchResultMarker = nil
                                completion(true)
                                print("🔥 여러 이미지 업로드 완료, userID: \(userID), 이미지 수: \(uploadedUrls.count)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func uploadImageToFirebase(
        image: UIImage,
        location: CLLocationCoordinate2D,
        customCategory: String? = nil,
        takenAt: Date? = nil,
        imageTitle: String = "",
        description: String = "",
        userID: String,
        completion: @escaping (Bool) -> Void
    ) {
        let db = Firestore.firestore()

        // 🔒 1. 업로드 금지 사용자 확인
        db.collection("bannedUsers").document(userID).getDocument { snapshot, error in
            if let error = error {
                print("🚫 밴 여부 확인 중 오류 발생: \(error.localizedDescription)")
                completion(false)
                return
            }

            if let snapshot = snapshot, snapshot.exists {
                print("🚫 업로드 차단됨: \(userID)는 밴된 사용자입니다.")
                completion(false)
                return
            }

            // ✅ 2. 정상 사용자 → 이미지 변환
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("❌ 이미지 변환 실패")
                completion(false)
                return
            }

            let fileName = UUID().uuidString + ".jpg"
            let storageRef = Storage.storage().reference().child("images/\(fileName)")

            // ✅ 3. Storage 업로드
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    print("❌ Firebase Storage 업로드 실패: \(error.localizedDescription)")
                    completion(false)
                    return
                }

                storageRef.downloadURL { url, error in
                    guard let downloadURL = url else {
                        print("❌ 다운로드 URL 가져오기 실패")
                        completion(false)
                        return
                    }

                    // ✅ 4. Firestore에 위치 문서 업데이트
                    let categoryToUse = (customCategory?.isEmpty == false) ? customCategory! : self.selectedCategory
                    let docId = "\(location.latitude)_\(location.longitude)_\(categoryToUse)"
                    let docRef = db.collection("locations").document(docId)

                    let uploadDate = Date()
                    let takenDate = takenAt ?? uploadDate

                    docRef.getDocument { snapshot, error in
                        if let error = error {
                            print("❌ 문서 확인 실패: \(error.localizedDescription)")
                            completion(false)
                            return
                        }

                        if let document = snapshot, document.exists {
                            // 🔄 기존 문서에 업데이트
                            docRef.updateData([
                                "imageUrls": FieldValue.arrayUnion([downloadURL.absoluteString]),
                                "timestamps": FieldValue.arrayUnion([Timestamp(date: uploadDate)]),
                                "takenAtList": FieldValue.arrayUnion([Timestamp(date: takenDate)]),
                                "titles": FieldValue.arrayUnion([imageTitle]),
                                "descriptions": FieldValue.arrayUnion([description]),
                                "userIDs": FieldValue.arrayUnion([userID])
                            ]) { err in
                                if let err = err {
                                    print("❌ Firestore 업데이트 실패: \(err)")
                                    completion(false)
                                } else {
                                    self.fetchPlaces()
                                    self.searchResultMarker = nil
                                    completion(true)
                                }
                            }
                        } else {
                            // 🆕 새 문서 생성
                            docRef.setData([
                                "lat": location.latitude,
                                "lng": location.longitude,
                                "imageUrls": [downloadURL.absoluteString],
                                "timestamps": [Timestamp(date: uploadDate)],
                                "takenAtList": [Timestamp(date: takenDate)],
                                "titles": [imageTitle],
                                "descriptions": [description],
                                "category": categoryToUse,
                                "userIDs": [userID]
                            ]) { err in
                                if let err = err {
                                    print("❌ Firestore 문서 생성 실패: \(err)")
                                    completion(false)
                                } else {
                                    self.fetchPlaces()
                                    self.searchResultMarker = nil
                                    completion(true)
                                    print("🔥 현재 업로드 userID: \(userID)")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
//    func uploadImageToFirebase(
//        image: UIImage,
//        location: CLLocationCoordinate2D,
//        customCategory: String? = nil,
//        takenAt: Date? = nil,
//        imageTitle: String = "",
//        description: String = "",
//        userID: String,  // ✅ 사용자 ID 추가
//        completion: @escaping (Bool) -> Void
//    ) {
//        // 🔒 1. 밴 사용자 여부 먼저 확인
//        let db = Firestore.firestore()
//        db.collection("bannedUsers").document(userID).getDocument { snapshot, error in
//            if let snapshot = snapshot, snapshot.exists {
//                print("🚫 업로드 금지: 밴된 사용자입니다.")
//                completion(false)
//                return
//            }
//
//            // ✅ 2. 정상 사용자만 업로드 진행
//            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
//                print("이미지 변환 실패")
//                completion(false)
//                return
//            }
//
//            let fileName = UUID().uuidString + ".jpg"
//            let storageRef = Storage.storage().reference().child("images/\(fileName)")
//
//            storageRef.putData(imageData, metadata: nil) { metadata, error in
//                if let error = error {
//                    print("Storage 업로드 실패: \(error.localizedDescription)")
//                    completion(false)
//                    return
//                }
//
//                storageRef.downloadURL { url, error in
//                    guard let downloadURL = url else {
//                        print("URL 가져오기 실패")
//                        completion(false)
//                        return
//                    }
//
//                    let categoryToUse = (customCategory?.isEmpty == false) ? customCategory! : self.selectedCategory
//                    let docId = "\(location.latitude)_\(location.longitude)_\(categoryToUse)"
//                    let docRef = db.collection("locations").document(docId)
//
//                    let uploadDate = Date()
//                    let takenDate = takenAt ?? uploadDate
//
//                    docRef.getDocument { snapshot, error in
//                        if let document = snapshot, document.exists {
//                            docRef.updateData([
//                                "imageUrls": FieldValue.arrayUnion([downloadURL.absoluteString]),
//                                "timestamps": FieldValue.arrayUnion([Timestamp(date: uploadDate)]),
//                                "takenAtList": FieldValue.arrayUnion([Timestamp(date: takenDate)]),
//                                "titles": FieldValue.arrayUnion([imageTitle]),
//                                "descriptions": FieldValue.arrayUnion([description]),
//                                "userIDs": FieldValue.arrayUnion([userID])
//                            ]) { err in
//                                if let err = err {
//                                    print("Firestore 업데이트 실패: \(err)")
//                                    completion(false)
//                                } else {
//                                    self.fetchPlaces()
//                                    self.searchResultMarker = nil
//                                    completion(true)
//                                }
//                            }
//                        } else {
//                            docRef.setData([
//                                "lat": location.latitude,
//                                "lng": location.longitude,
//                                "imageUrls": [downloadURL.absoluteString],
//                                "timestamps": [Timestamp(date: uploadDate)],
//                                "takenAtList": [Timestamp(date: takenDate)],
//                                "titles": [imageTitle],
//                                "descriptions": [description],
//                                "category": categoryToUse,
//                                "userIDs": [userID]
//                            ]) { err in
//                                if let err = err {
//                                    print("Firestore 문서 생성 실패: \(err)")
//                                    completion(false)
//                                } else {
//                                    self.fetchPlaces()
//                                    self.searchResultMarker = nil
//                                    completion(true)
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//    func uploadImageToFirebase(
//        image: UIImage,
//        location: CLLocationCoordinate2D,
////        title: String,
//        customCategory: String? = nil,
//        takenAt: Date? = nil,
//        imageTitle: String = "",
//        description: String = "",
//        completion: @escaping (Bool) -> Void
//    ) {
//        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
//            print("이미지 변환 실패")
//            completion(false)
//            return
//        }
//        
//        let fileName = UUID().uuidString + ".jpg"
//        let storageRef = Storage.storage().reference().child("images/\(fileName)")
//        
//        storageRef.putData(imageData, metadata: nil) { metadata, error in
//            if let error = error {
//                print("Storage 업로드 실패: \(error.localizedDescription)")
//                completion(false)
//                return
//            }
//            
//            storageRef.downloadURL { url, error in
//                guard let downloadURL = url else {
//                    print("URL 가져오기 실패")
//                    completion(false)
//                    return
//                }
//                
//                let db = Firestore.firestore()
//                let categoryToUse = (customCategory?.isEmpty == false) ? customCategory! : self.selectedCategory
//                
//                let docId = "\(location.latitude)_\(location.longitude)_\(categoryToUse)"
//                let docRef = db.collection("locations").document(docId)
//                
//                let uploadDate = Date()
//                let takenDate = takenAt ?? uploadDate
//                
//                docRef.getDocument { snapshot, error in
//                    if let document = snapshot, document.exists {
//                        docRef.updateData([
//                            "imageUrls": FieldValue.arrayUnion([downloadURL.absoluteString]),
//                            "timestamps": FieldValue.arrayUnion([Timestamp(date: uploadDate)]),
//                            "takenAtList": FieldValue.arrayUnion([Timestamp(date: takenDate)]),
//                            "titles": FieldValue.arrayUnion([imageTitle]),
//                            "descriptions": FieldValue.arrayUnion([description])
//                        ]) { err in
//                            if let err = err {
//                                print("Firestore 업데이트 실패: \(err)")
//                                completion(false)
//                            } else {
//                                self.fetchPlaces()
//                                self.searchResultMarker = nil
//                                completion(true)
//                            }
//                        }
//                    } else {
//                        docRef.setData([
////                            "title": title,
//                            "lat": location.latitude,
//                            "lng": location.longitude,
//                            "imageUrls": [downloadURL.absoluteString],
//                            "timestamps": [Timestamp(date: uploadDate)],
//                            "takenAtList": [Timestamp(date: takenDate)],
//                            "titles": [imageTitle],
//                            "descriptions": [description],
//                            "category": categoryToUse
//                        ]) { err in
//                            if let err = err {
//                                print("Firestore 문서 생성 실패: \(err)")
//                                completion(false)
//                            } else {
//                                self.fetchPlaces()
//                                self.searchResultMarker = nil
//                                completion(true)
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//    func uploadImageToFirebase(
//        image: UIImage,
//        location: CLLocationCoordinate2D,
//        customCategory: String? = nil,
//        takenAt: Date? = nil,
//        imageTitle: String = "",
//        description: String = "",
//        userID: String,  // ✅ 사용자 ID 추가
//        completion: @escaping (Bool) -> Void
//    ) {
//        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
//            print("이미지 변환 실패")
//            completion(false)
//            return
//        }
//
//        let fileName = UUID().uuidString + ".jpg"
//        let storageRef = Storage.storage().reference().child("images/\(fileName)")
//
//        storageRef.putData(imageData, metadata: nil) { metadata, error in
//            if let error = error {
//                print("Storage 업로드 실패: \(error.localizedDescription)")
//                completion(false)
//                return
//            }
//
//            storageRef.downloadURL { url, error in
//                guard let downloadURL = url else {
//                    print("URL 가져오기 실패")
//                    completion(false)
//                    return
//                }
//
//                let db = Firestore.firestore()
//                let categoryToUse = (customCategory?.isEmpty == false) ? customCategory! : self.selectedCategory
//
//                let docId = "\(location.latitude)_\(location.longitude)_\(categoryToUse)"
//                let docRef = db.collection("locations").document(docId)
//
//                let uploadDate = Date()
//                let takenDate = takenAt ?? uploadDate
//
//                docRef.getDocument { snapshot, error in
//                    if let document = snapshot, document.exists {
//                        docRef.updateData([
//                            "imageUrls": FieldValue.arrayUnion([downloadURL.absoluteString]),
//                            "timestamps": FieldValue.arrayUnion([Timestamp(date: uploadDate)]),
//                            "takenAtList": FieldValue.arrayUnion([Timestamp(date: takenDate)]),
//                            "titles": FieldValue.arrayUnion([imageTitle]),
//                            "descriptions": FieldValue.arrayUnion([description]),
//                            "userIDs": FieldValue.arrayUnion([userID])  // ✅ 여러 사용자 저장을 위해 배열 형태
//                        ]) { err in
//                            if let err = err {
//                                print("Firestore 업데이트 실패: \(err)")
//                                completion(false)
//                            } else {
//                                self.fetchPlaces()
//                                self.searchResultMarker = nil
//                                completion(true)
//                            }
//                        }
//                    } else {
//                        docRef.setData([
//                            "lat": location.latitude,
//                            "lng": location.longitude,
//                            "imageUrls": [downloadURL.absoluteString],
//                            "ㅕ": [Timestamp(date: uploadDate)],
//                            "takenAtList": [Timestamp(date: takenDate)],
//                            "titles": [imageTitle],
//                            "descriptions": [description],
//                            "category": categoryToUse,
//                            "userIDs": [userID]  // ✅ 최초 등록자 저장
//                        ]) { err in
//                            if let err = err {
//                                print("Firestore 문서 생성 실패: \(err)")
//                                completion(false)
//                            } else {
//                                self.fetchPlaces()
//                                self.searchResultMarker = nil
//                                completion(true)
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
    func deleteImageFromFirebase(placeId: String, imageUrl: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let storage = Storage.storage()
        let docRef = db.collection("locations").document(placeId)
        
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  var imageUrls = data["imageUrls"] as? [String],
                  var timestamps = data["timestamps"] as? [Timestamp],
                  let index = imageUrls.firstIndex(of: imageUrl) else {
                print("❌ 이미지 삭제 실패: 데이터 불일치")
                completion(false)
                return
            }
            
            // 🔹 Storage 경로 추출
            let url = URL(string: imageUrl)
            let encodedPath = url?.absoluteString
                .components(separatedBy: "/o/").last?
                .components(separatedBy: "?").first
            
            guard let decodedPath = encodedPath?.removingPercentEncoding else {
                print("❌ 경로 디코딩 실패")
                completion(false)
                return
            }
            
            let imageRef = storage.reference(withPath: decodedPath)
            
            // 🔸 1. Storage 삭제
            imageRef.delete { err in
                if let err = err {
                    print("❌ Storage 삭제 실패: \(err.localizedDescription)")
                    completion(false)
                    return
                }
                
                print("✅ Storage 이미지 삭제 완료")
                
                // 🔸 2. Firestore에서 배열 동기화
                imageUrls.remove(at: index)
                timestamps.remove(at: index)
                
                docRef.updateData([
                    "imageUrls": imageUrls,
                    "timestamps": timestamps
                ]) { err in
                    if let err = err {
                        print("❌ Firestore 업데이트 실패: \(err.localizedDescription)")
                        completion(false)
                    } else {
                        print("✅ Firestore 업데이트 완료")
                        self.fetchPlaces()
                        completion(true)
                    }
                }
            }
        }
    }
    func reportImage(placeId: String, imageUrl: String) {
        let db = Firestore.firestore()
        let placeRef = db.collection("places").document(placeId)

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(placeRef)
            } catch let error as NSError {
                print("❌ 트랜잭션 실패: \(error.localizedDescription)")
                return nil
            }

            var reportCount = snapshot.data()?["reportCount"] as? Int ?? 0
            reportCount += 1

            transaction.updateData(["reportCount": reportCount], forDocument: placeRef)

            // 신고 로그 남기기
            let reportLog: [String: Any] = [
                "placeId": placeId,
                "imageUrl": imageUrl,
                "timestamp": FieldValue.serverTimestamp()
            ]
            db.collection("reports").addDocument(data: reportLog)

            return nil
        }) { (_, error) in
            if let error = error {
                print("🚨 신고 실패: \(error.localizedDescription)")
            } else {
                print("🚨 신고 완료")
            }
        }
    }
}
