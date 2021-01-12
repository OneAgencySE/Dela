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
	@Published var image: UIImage?

    private let greeterClient = GreeterClient()
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
            .map { input -> AnyPublisher<Blob_BlobData, UserInfoError> in
                return self.blobClient.downloadPublisher(blobId: input)
            }.switchToLatest()
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                    case .failure(let error):
                        print(error)
                    case .finished:
                        self.image = UIImage(data: downloadImageCache)
                        downloadImageCache = Data() // Clear image data
                }
            } receiveValue: { data in
                downloadImageCache.append(data.chunkData)
            }
    }

	func initUploadSubscriber() {
        uploadCancellable = uploadPublisher
            .map { input -> AnyPublisher<Blob_BlobInfo, UserInfoError> in
                return self.blobClient.uploadImge(data: input)
            }.switchToLatest()
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                    case .failure(let error):
                        print(error)
                    case .finished:
                        print("finished")
                }
            } receiveValue: { blobInfo in
                print(blobInfo)
            }
	}

    func didPressDownload() {
        let number = Int.random(in: 0...2)
        let files = ["6afbc11c-acbe-4a46-abc7-b51bb8b15d76.jpeg",
                     "36289966-6e07-4447-ae10-a161ded2325c.jpeg",
                     "test_36289966-6e07-4447-ae10-a161ded2325c.jpeg.jpeg"]
        downloadPublisher.send(files[number])
        downloadPublisher.send(completion: .finished)
    }

    func didPressUpload(data: Data?) {
        guard let image = data else {
            return
        }
        uploadPublisher.send(image)
        uploadPublisher.send(completion: .finished)
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
