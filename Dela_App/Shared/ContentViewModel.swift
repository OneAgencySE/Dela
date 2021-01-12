//
//  ContentViewModel.swift
//  Dela
//
//  Created by Joacim Nidén on 2020-12-17.
//

import Foundation
import Combine
import UIKit

class ContentViewModel: ObservableObject {

	@Published var greeting: String?
	@Published var downloadedImage: UIImage?
	@Published var uploadedImage: (Data, String)?
	
	private var imageData: Data?

	private let greeterClient = GreeterClient.shared
	private let blobClient = BlobClient()

    private var downloadCancellable: AnyCancellable?
    private let downloadPublisher = PassthroughSubject<String, Never>()

    private var uploadCancellable: AnyCancellable?
    private let uploadPublisher = PassthroughSubject<Data, Never>()

	init() {		
		initDownloadPublisher()
		initUploadSubscriber()
	}

    func initDownloadPublisher() {
        var downloadImageCache = Data()
        downloadCancellable = downloadPublisher
            .map { [unowned self] input -> AnyPublisher<Blob_BlobData, UserInfoError> in
                return self.blobClient.downloadPublisher(blobId: input)
            }.switchToLatest()
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                    case .failure(let error):
                        print(error)
                    case .finished:
                        self.downloadedImage = UIImage(data: downloadImageCache)
                        downloadImageCache = Data() // Clear image data
                }
            } receiveValue: { data in
                downloadImageCache.append(data.chunkData)
            }
    }

	func initUploadSubscriber() {

		uploadCancellable = uploadPublisher
            .map { [unowned self] input -> AnyPublisher<Blob_BlobInfo, UserInfoError> in
				self.imageData = input
                return self.blobClient.uploadImge(data: input)
            }
			.switchToLatest()
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                    case .failure(let error):
                        print(error)
                    case .finished:
                        print("finished")
                }
            } receiveValue: { [unowned self] blobInfo in
				if let image = self.imageData {
					self.uploadedImage = (image, blobInfo.blobID)
				}
				
            }
	}

    func didPressDownload() {
        let number = Int.random(in: 0...2)
        let files = ["6ca0447e-5e0c-40c7-89bf-660c35268c4f.jpeg",
                     "8eb2f759-bf70-432d-b2ed-ad75d24b6f55.jpeg",
                     "8f8195e2-cae7-4153-b4ec-663c73bf4b65.jpeg"]
        downloadPublisher.send(files[number])
        downloadPublisher.send(completion: .finished)
    }

    func didPressUpload(data: Data?) {
        guard let image = data else {
            return
        }

        uploadPublisher.send(image)
    }

    func send() {
        switch greeterClient.hello("I said Hi") {
            case .success(let message):
                greeting = message
            case .failure(let failure):
                greeting = failure.localizedDescription
        }
    }

}
