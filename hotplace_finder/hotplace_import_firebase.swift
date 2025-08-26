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
                    if let error = error {
                        print("❌ Firebase Storage 업로드 실패: \(error.localizedDescription)")
                        uploadFailed = true
                        group.leave() // ❌ 실패 시에만 leave
                        return
                    }
                    
                    storageRef.downloadURL { url, error in
                        defer { group.leave() } // ✅ downloadURL 완료 후 leave
                        
                        guard let downloadURL = url else {
                            print("❌ 다운로드 URL 가져오기 실패")
                            uploadFailed = true
                            return
                        }
                        
                        // ✅ URL을 배열에 추가
                        uploadedUrls.append(downloadURL.absoluteString)
                        print("✅ 이미지 URL 추가됨: \(downloadURL.absoluteString)")
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
                
                print("🎯 업로드된 이미지 수: \(uploadedUrls.count)")
                print("🎯 업로드된 URL들: \(uploadedUrls)")
                
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
                        // 🔄 기존 문서에 업데이트 - 안전한 배열 병합 방식
                        guard let existingData = document.data() else {
                            print("❌ 기존 문서 데이터를 가져올 수 없음")
                            completion(false)
                            return
                        }
                        
                        // 🔍 기존 배열 데이터 백업 (빈 배열이 아닌 경우만)
                        let existingImageUrls = existingData["imageUrls"] as? [String] ?? []
                        let existingTimestamps = existingData["timestamps"] as? [Timestamp] ?? []
                        let existingTakenAtList = existingData["takenAtList"] as? [Timestamp] ?? []
                        let existingTitles = existingData["titles"] as? [String] ?? []
                        let existingDescriptions = existingData["descriptions"] as? [String] ?? []
                        let existingUserIDs = existingData["userIDs"] as? [String] ?? []
                        
                        // 🔄 새로운 데이터와 기존 데이터 병합
                        let finalImageUrls = existingImageUrls.isEmpty ? uploadedUrls : (existingImageUrls + uploadedUrls)
                        let finalTimestamps = existingTimestamps.isEmpty ? timestamps : (existingTimestamps + timestamps)
                        let finalTakenAtList = existingTakenAtList.isEmpty ? takenAtList : (existingTakenAtList + takenAtList)
                        let finalTitles = existingTitles.isEmpty ? titles : (existingTitles + titles)
                        let finalDescriptions = existingDescriptions.isEmpty ? descriptions : (existingDescriptions + descriptions)
                        let finalUserIDs = existingUserIDs.isEmpty ? userIDs : (existingUserIDs + userIDs)
                        
                        print("🔍 기존 데이터 개수 - imageUrls: \(existingImageUrls.count), timestamps: \(existingTimestamps.count), takenAtList: \(existingTakenAtList.count)")
                        print("🎯 새로운 데이터 개수 - imageUrls: \(uploadedUrls.count), timestamps: \(timestamps.count), takenAtList: \(takenAtList.count)")
                        print("✅ 최종 병합 데이터 개수 - imageUrls: \(finalImageUrls.count), timestamps: \(finalTimestamps.count), takenAtList: \(finalTakenAtList.count)")
                        
                        docRef.updateData([
                            "imageUrls": finalImageUrls,
                            "timestamps": finalTimestamps,
                            "takenAtList": finalTakenAtList,
                            "titles": finalTitles,
                            "descriptions": finalDescriptions,
                            "userIDs": finalUserIDs
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
    
    // 🔄 Firebase 문서 구조 마이그레이션 함수
    func migrateFirebaseDocumentStructure(completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("locations").getDocuments { snapshot, error in
            if let error = error {
                print("❌ 마이그레이션 중 오류: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("❌ 문서를 찾을 수 없음")
                completion(false)
                return
            }
            
            let group = DispatchGroup()
            var migrationCount = 0
            
            for document in documents {
                let data = document.data()
                
                // 🔍 기존 단일 이미지 필드 확인
                if let singleImageUrl = data["imageUrl"] as? String {
                    group.enter()
                    
                    // 🔄 단일 이미지를 배열로 변환
                    let updatedData: [String: Any] = [
                        "imageUrls": [singleImageUrl],
                        "imageUrl": FieldValue.delete() // 기존 필드 삭제
                    ]
                    
                    document.reference.updateData(updatedData) { error in
                        defer { group.leave() }
                        
                        if let error = error {
                            print("❌ 문서 \(document.documentID) 마이그레이션 실패: \(error.localizedDescription)")
                        } else {
                            migrationCount += 1
                            print("✅ 문서 \(document.documentID) 마이그레이션 완료")
                        }
                    }
                }
            }
            
            group.notify(queue: .main) {
                print("🎉 마이그레이션 완료: \(migrationCount)개 문서 변환")
                self.fetchPlaces() // 데이터 새로고침
                completion(true)
            }
        }
    }
    
    func deleteImageFromFirebase(placeId: String, imageUrl: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let storage = Storage.storage()
        let docRef = db.collection("locations").document(placeId)
        
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  var imageUrls = data["imageUrls"] as? [String],
                  var timestamps = data["timestamps"] as? [Timestamp],
                  var takenAtList = data["takenAtList"] as? [Timestamp],
                  var titles = data["titles"] as? [String],
                  var descriptions = data["descriptions"] as? [String],
                  var userIDs = data["userIDs"] as? [String],
                  let index = imageUrls.firstIndex(of: imageUrl) else {
                print("❌ 이미지 삭제 실패: 데이터 불일치")
                completion(false)
                return
            }
            
            print("🎯 삭제할 이미지 인덱스: \(index)")
            print("🎯 삭제 전 데이터 개수 - imageUrls: \(imageUrls.count), timestamps: \(timestamps.count), takenAtList: \(takenAtList.count), titles: \(titles.count), descriptions: \(descriptions.count), userIDs: \(userIDs.count)")
            
            // 🔹 Storage 경로 추출 - 개선된 방식
            print("🔍 원본 URL: \(imageUrl)")
            
            // 방법 1: Firebase Storage URL에서 경로 추출
            let storagePath: String
            if imageUrl.contains("/o/") {
                // Firebase Storage URL 형식: https://.../o/images%2Ffilename.jpg?alt=media&token=...
                let components = imageUrl.components(separatedBy: "/o/")
                if components.count > 1 {
                    let pathComponent = components[1].components(separatedBy: "?").first ?? ""
                    storagePath = pathComponent.removingPercentEncoding ?? pathComponent
                    print("🔍 추출된 Storage 경로: \(storagePath)")
                } else {
                    print("❌ Firebase Storage URL 형식이 아님")
                    completion(false)
                    return
                }
            } else {
                // 직접 경로인 경우
                storagePath = imageUrl
                print("🔍 직접 경로 사용: \(storagePath)")
            }
            
            let imageRef = storage.reference(withPath: storagePath)
            print("🎯 Storage 참조 생성: \(imageRef.fullPath)")
            
            // 🔸 1. Storage 삭제
            imageRef.delete { err in
                if let err = err {
                    print("❌ Storage 이미지 삭제 실패!")
                    print("🔍 에러 코드: \(err._code)")
                    print("🔍 에러 설명: \(err.localizedDescription)")
                    print("🔍 에러 도메인: \(err._domain)")
                    print("🔍 Storage 경로: \(storagePath)")
                    print("🔍 Storage 참조: \(imageRef.fullPath)")
                    
                    // 🔍 Storage 파일 존재 여부 확인
                    imageRef.getMetadata { metadata, error in
                        if let error = error {
                            print("🔍 파일 존재 여부 확인 실패: \(error.localizedDescription)")
                        } else if let metadata = metadata {
                            print("🔍 파일 존재함 - 크기: \(metadata.size) bytes")
                        } else {
                            print("🔍 파일이 존재하지 않음")
                        }
                    }
                    
                    completion(false)
                    return
                }
                
                print("✅ Storage 이미지 삭제 완료")
                print("🎯 삭제된 파일 경로: \(storagePath)")
                
                // 🔸 2. Firestore에서 모든 관련 배열 데이터 동기화
                // 배열 길이를 맞춰서 동일한 인덱스의 데이터를 모두 삭제
                if index < imageUrls.count { imageUrls.remove(at: index) }
                if index < timestamps.count { timestamps.remove(at: index) }
                if index < takenAtList.count { takenAtList.remove(at: index) }
                if index < titles.count { titles.remove(at: index) }
                if index < descriptions.count { descriptions.remove(at: index) }
                if index < userIDs.count { userIDs.remove(at: index) }
                
                print("🎯 삭제 후 데이터 개수 - imageUrls: \(imageUrls.count), timestamps: \(timestamps.count), takenAtList: \(takenAtList.count), titles: \(titles.count), descriptions: \(descriptions.count), userIDs: \(userIDs.count)")
                
                // 🔸 3. 모든 배열을 한 번에 업데이트
                let updateData: [String: Any] = [
                    "imageUrls": imageUrls,
                    "timestamps": timestamps,
                    "takenAtList": takenAtList,
                    "titles": titles,
                    "descriptions": descriptions,
                    "userIDs": userIDs
                ]
                
                docRef.updateData(updateData) { err in
                    if let err = err {
                        print("❌ Firestore 업데이트 실패: \(err.localizedDescription)")
                        completion(false)
                    } else {
                        print("✅ Firestore 모든 데이터 동기화 완료")
                        self.fetchPlaces()
                        completion(true)
                    }
                }
            }
        }
    }
    
    // 🔧 데이터 일관성 정리 함수
    func cleanupInconsistentData(completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("locations").getDocuments { snapshot, error in
            if let error = error {
                print("❌ 데이터 정리 중 오류: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("❌ 문서를 찾을 수 없음")
                completion(false)
                return
            }
            
            let group = DispatchGroup()
            var cleanupCount = 0
            
            for document in documents {
                let data = document.data()
                
                // 🔍 배열 필드들의 길이 확인
                let imageUrls = data["imageUrls"] as? [String] ?? []
                let timestamps = data["timestamps"] as? [Timestamp] ?? []
                let takenAtList = data["takenAtList"] as? [Timestamp] ?? []
                let titles = data["titles"] as? [String] ?? []
                let descriptions = data["descriptions"] as? [String] ?? []
                let userIDs = data["userIDs"] as? [String] ?? []
                
                // 🔍 가장 긴 배열을 기준으로 다른 배열들을 맞춤
                let maxLength = max(imageUrls.count, timestamps.count, takenAtList.count, titles.count, descriptions.count, userIDs.count)
                
                if maxLength > 0 && (imageUrls.count != maxLength || timestamps.count != maxLength || takenAtList.count != maxLength || titles.count != maxLength || descriptions.count != maxLength || userIDs.count != maxLength) {
                    group.enter()
                    
                    print("🔧 문서 \(document.documentID) 데이터 정리 필요 - 최대 길이: \(maxLength)")
                    print("🔧 현재 길이 - imageUrls: \(imageUrls.count), timestamps: \(timestamps.count), takenAtList: \(takenAtList.count), titles: \(titles.count), descriptions: \(descriptions.count), userIDs: \(userIDs.count)")
                    
                    // 🔧 배열 길이를 맞춤 (빈 값으로 채움)
                    let normalizedImageUrls = Array(imageUrls.prefix(maxLength)) + Array(repeating: "", count: max(0, maxLength - imageUrls.count))
                    let normalizedTimestamps = Array(timestamps.prefix(maxLength)) + Array(repeating: Timestamp(date: Date()), count: max(0, maxLength - timestamps.count))
                    let normalizedTakenAtList = Array(takenAtList.prefix(maxLength)) + Array(repeating: Timestamp(date: Date()), count: max(0, maxLength - takenAtList.count))
                    let normalizedTitles = Array(titles.prefix(maxLength)) + Array(repeating: "", count: max(0, maxLength - titles.count))
                    let normalizedDescriptions = Array(descriptions.prefix(maxLength)) + Array(repeating: "", count: max(0, maxLength - descriptions.count))
                    let normalizedUserIDs = Array(userIDs.prefix(maxLength)) + Array(repeating: "", count: max(0, maxLength - userIDs.count))
                    
                    let updateData: [String: Any] = [
                        "imageUrls": normalizedImageUrls,
                        "timestamps": normalizedTimestamps,
                        "takenAtList": normalizedTakenAtList,
                        "titles": normalizedTitles,
                        "descriptions": normalizedDescriptions,
                        "userIDs": normalizedUserIDs
                    ]
                    
                    document.reference.updateData(updateData) { error in
                        defer { group.leave() }
                        
                        if let error = error {
                            print("❌ 문서 \(document.documentID) 정리 실패: \(error.localizedDescription)")
                        } else {
                            cleanupCount += 1
                            print("✅ 문서 \(document.documentID) 데이터 정리 완료")
                        }
                    }
                }
            }
            
            group.notify(queue: .main) {
                print("🎉 데이터 정리 완료: \(cleanupCount)개 문서 정리됨")
                self.fetchPlaces() // 데이터 새로고침
                completion(true)
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
