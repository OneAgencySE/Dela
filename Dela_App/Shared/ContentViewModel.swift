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
	@Published var downloadedImage: (Data, String)?
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
	
	func buildImage(blobID: String) -> AnyPublisher<(Data, String), UserInfoError> {
		return self.blobClient.downloadPublisher(blobId: blobID)
			.handleEvents(receiveSubscription: { _ in
				self.startTime = Double(DispatchTime.now().uptimeNanoseconds) / 1_000_000
				print("start", self.startTime)
			}, receiveOutput: { (blob) in
				//self.blobStart = Double(DispatchTime.now().uptimeNanoseconds) / 1_000_000
				
			}, receiveCompletion: { _ in
				let endTime = Double(DispatchTime.now().uptimeNanoseconds) / 1_000_000
				print("end", endTime - self.startTime)
			})
			.subscribe(on: DispatchQueue.global())
			.reduce((Data(), ""), { (fullImage, newData) -> (Data, String) in
				let data = fullImage.0 + newData.chunkData
				return (data, newData.info.fileName)
			})
			.eraseToAnyPublisher()
	}

    func initDownloadPublisher() {
		
        downloadCancellable = downloadPublisher			
            .flatMap { [unowned self] input in buildImage(blobID: input) }
			.receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                    case .failure(let error):
                        print(error)
                    case .finished:
                       print("finished")
                }
            } receiveValue: { blob in
				self.downloadedImage = (blob.0, blob.1)
            }
    }

	func initUploadSubscriber() {

		uploadCancellable = uploadPublisher
            .flatMap { [unowned self] input -> AnyPublisher<Blob_BlobInfo, UserInfoError> in
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
					self.uploadedImage = (image, blobInfo.blobID)
				}
            }
	}

    func didPressDownload() {
        let number = Int.random(in: 0...2)
        let files = ["a2442950-44f6-4bbe-aba5-5f36a1fc71f1.jpeg",
                     "83133db1-8462-4bc9-b703-db33d8f056a9.jpeg",
                     "665537c8-2855-4fa6-9d06-df43560fceb5.jpeg"]
		print(files[number])
        downloadPublisher.send(files[number])
        //downloadPublisher.send(completion: .finished)

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
