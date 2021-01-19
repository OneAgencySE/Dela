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

	@Published var downloadedImage: DownloadedBlob?
	@Published var uploadedImage: (Data, String)?

	private var imageData: Data?

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
                        print("Failure: ", error)
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
                        print("Failure: ", error)
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
        if let image = self.uploadedImage {
            downloadPublisher.send(image.1)
        }
    }

    func didPressUpload(data: Data?) {
        guard let image = data else {
            return
        }

        uploadPublisher.send(image)
    }

}
