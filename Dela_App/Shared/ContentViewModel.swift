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
	
	init() {
		downloadImages()
	}

	func send() {
		switch greeterClient.hello("I said Hi") {
            case .success(let message):
				greeting = message
			case .failure(let failure):
				greeting = failure.localizedDescription
		}
	}

	func sendImage(_ data: Data?) {
		guard let image = data else {
			return
		}
        blobClient.uploadImge(data: image)
	}
	
	func downloadImages() {
		downloadCancellable = blobClient.downloadPublisher()
			.
			.subscribe(on: DispatchQueue.global())
			.receive(on: DispatchQueue.main)
			.sink { completion in
				switch completion {
					case .failure(let error):
						print(error)
					case .finished:
						print("finished")
				}
		} receiveValue: { data in
			
			self.image = UIImage(data: data)
		}

	}

}
