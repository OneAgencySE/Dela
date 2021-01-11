//
//  ContentViewModel.swift
//  Dela
//
//  Created by Joacim Nidén on 2020-12-17.
//

import Foundation
import Combine

class ContentViewModel: ObservableObject {

	@Published var greeting: String?
	private let greeterClient = GreeterClient()
    private let blobClient = BlobClient()

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

}
