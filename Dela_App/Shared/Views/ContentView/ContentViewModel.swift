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
	@Published var downloadedImage: DownloadedBlob?
	@Published var uploadedImage: (Data, String)?

	private var imageData: Data?

	private let greeterClient = GreeterClient.shared
	private let blobClient = BlobClient.shared

    private var downloadCancellable: AnyCancellable?
    private let downloadPublisher = PassthroughSubject<String, Never>()

    private var uploadCancellable: AnyCancellable?
    private let uploadPublisher = PassthroughSubject<Data, Never>()

	init() {
		initDownloadPublisher()
		initUploadSubscriber()
	}

	private var startTime: Double = 0
	private var blobStart: Double = 0

    func initDownloadPublisher() {
        downloadCancellable = downloadPublisher
            .flatMap { [unowned self] input in blobClient.downBlobPub(blobId: input) }
			.receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                    case .failure(let error):
                        print(error)
                    case .finished:
                       print("finished")
                }
            } receiveValue: { blob in
				self.downloadedImage = blob
            }
    }

	func initUploadSubscriber() {

		uploadCancellable = uploadPublisher
            .flatMap { [unowned self] input -> AnyPublisher<BlobInfo, UserInfoError> in
				self.imageData = input
                return self.blobClient.uploadImge(data: input)
            }
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
					self.uploadedImage = (image, blobInfo.blobId)
				}
            }
	}

    func didPressDownload() {
        let number = Int.random(in: 0...2)
        let files = ["0bc0e53e-0175-4238-8729-0db1ae8f9fc0.jpeg",
                     "5c5c2fc8-a9d5-4272-86b9-05e7952ada9b.jpeg",
                     "30dec707-bead-4f64-b43a-531ec06fa22b.jpeg"]
		print(files[number])
        downloadPublisher.send(files[number])

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
